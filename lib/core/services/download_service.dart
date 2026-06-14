import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/download_progress.dart';
import '../utils/binary_manager.dart';

class DownloadService {
  final _binaryManager = BinaryManager.instance;

  // ── Per-task phase tracking ────────────────────────────────────────────
  int _streamCount = 0;
  bool _inSubtitlePhase = false;
  bool _inMergerPhase = false;
  double _currentPercent = 0;
  String? _mainSizeLabel;
  String? _mainCurrentSizeLabel;

  static const _subtitleExtensions = ['.vtt', '.srt', '.ass', '.ssa', '.lrc'];

  bool _isSubtitleDest(String dest) {
    final lower = dest.toLowerCase();
    return _subtitleExtensions.any((ext) => lower.endsWith(ext)) ||
        lower.contains('subtitle');
  }

  /// Computes an overall progress percent that reflects the multi-stream
  /// nature of yt-dlp downloads (video + audio + subtitles).
  ///
  /// Weights are always applied so the overall never drops at stream
  /// transitions:
  /// - First stream (video): current * 0.6 → 0–60%
  /// - Second stream (audio): 60 + current * 0.25 → 60–85%
  /// - Remaining streams (subtitles etc): 85 + current * 0.15 → 85–100%
  /// - Merger phase: always 100%
  double _overallPercent() {
    if (_inMergerPhase) return 100;
    if (_inSubtitlePhase) return 85 + _currentPercent * 0.15;
    if (_streamCount <= 1) return _currentPercent * 0.6;
    return 60 + _currentPercent * 0.25;
  }

  final Map<String, Process> _processes = {};

  Stream<DownloadProgress> download({
    required String taskId,
    required String url,
    required String formatId,
    required String outputPath,
    String? cookiesBrowser,
    bool resume = false,
    String? subtitleLang,
  }) {
    final controller = StreamController<DownloadProgress>();

    _startDownload(
      taskId: taskId,
      url: url,
      formatId: formatId,
      outputPath: outputPath,
      cookiesBrowser: cookiesBrowser,
      controller: controller,
      resume: resume,
      subtitleLang: subtitleLang,
    );

    return controller.stream;
  }

  Future<void> _startDownload({
    required String taskId,
    required String url,
    required String formatId,
    required String outputPath,
    required StreamController<DownloadProgress> controller,
    String? cookiesBrowser,
    bool resume = false,
    String? subtitleLang,
  }) async {
    StreamSubscription<String>? stdoutSub;
    StreamSubscription<String>? stderrSub;
    Process? process;

    try {
      final executable = await _binaryManager.ytDlpPath;
      final ffmpegPath = await _binaryManager.ffmpegPath;

      final args = [
        '-f', formatId,
        '--no-playlist',
        '--merge-output-format', 'mkv',
        '--ffmpeg-location', ffmpegPath,
        '--newline',
        '--encoding', 'utf-8',
      ];

      if (subtitleLang != null && subtitleLang.isNotEmpty) {
        args.addAll([
          '--sub-langs', subtitleLang,
          '--embed-subs',
        ]);
      }

      if (resume) {
        args.add('--continue');
      }

      try {
        final deno = await _binaryManager.denoPath;
        args.addAll(['--js-runtimes', 'deno:$deno']);
      } catch (e) {
        debugPrint('[download_service] Deno not available, skipping JS runtime args: $e');
      }

      if (cookiesBrowser != null &&
          cookiesBrowser.isNotEmpty &&
          cookiesBrowser.toLowerCase() != 'none') {
        args.addAll(['--cookies-from-browser', cookiesBrowser.toLowerCase()]);
      }

      args.addAll(['-o', outputPath, url]);

      debugPrint('[download_service] starting: $executable ${args.join(' ')}');
      process = await Process.start(executable, args);
      debugPrint('[download_service] started PID ${process.pid}');
      process.stdin.close();
      _processes[taskId] = process;

      const decoder = Utf8Decoder(allowMalformed: true);

      _streamCount = 0;
      _inSubtitlePhase = false;
      _inMergerPhase = false;
      _currentPercent = 0;
      _mainSizeLabel = null;
      _mainCurrentSizeLabel = null;

      final stderrBuffer = StringBuffer();
      var lineCount = 0;

      stdoutSub = process.stdout
          .transform(decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          lineCount++;
          if (lineCount <= 5) {
            debugPrint('[download_service] stdout#$lineCount: $line');
          }

          if (controller.isClosed) return;

          if (line.contains('[download]') && line.contains('Destination:')) {
            final dest = line.split('Destination:').last.trim();
            _mainSizeLabel = null;
            _mainCurrentSizeLabel = null;
            _currentPercent = 0;
            if (_isSubtitleDest(dest)) {
              _inSubtitlePhase = true;
              controller.add(DownloadProgress(
                percent: _overallPercent().clamp(0, 100),
                phase: 'Downloading Subtitles',
              ));
            } else {
              _inSubtitlePhase = false;
              _streamCount++;
              controller.add(DownloadProgress.phase(
                _streamCount == 1 ? 'Downloading Video' : 'Downloading Audio',
              ));
            }
            return;
          }

          if (line.contains('[Merger]')) {
            _inMergerPhase = true;
            _inSubtitlePhase = false;
            controller.add(DownloadProgress(
              percent: _overallPercent().clamp(0, 100),
              phase: 'Remuxing...',
              sizeLabel: _mainSizeLabel,
              currentSizeLabel: _mainCurrentSizeLabel,
            ));
            return;
          }

          final phase = DownloadProgress.tryParsePhase(line);
          if (phase != null) {
            controller.add(phase);
            return;
          }

          final progress = DownloadProgress.tryParse(line);
          if (progress == null) return;

          final sizeIsKiB = progress.sizeLabel?.contains('KiB') ?? false;

          if (_inSubtitlePhase || _inMergerPhase || sizeIsKiB) {
            controller.add(DownloadProgress(
              percent: _overallPercent().clamp(0, 100),
              phase: _inSubtitlePhase
                  ? 'Downloading Subtitles'
                  : (_inMergerPhase ? 'Remuxing...' : null),
              speedLabel: progress.speedLabel,
              etaLabel: progress.etaLabel,
              sizeLabel: _mainSizeLabel,
              currentSizeLabel: _mainCurrentSizeLabel,
            ));
            return;
          }

          _currentPercent = progress.percent;
          if (progress.sizeLabel != null) {
            _mainSizeLabel = progress.sizeLabel;
            _mainCurrentSizeLabel = progress.currentSizeLabel;
          }

          controller.add(DownloadProgress(
            percent: _overallPercent().clamp(0, 100),
            phase: _streamCount <= 1
                ? 'Downloading Video'
                : 'Downloading Audio',
            speedLabel: progress.speedLabel,
            etaLabel: progress.etaLabel,
            sizeLabel: _mainSizeLabel,
            currentSizeLabel: _mainCurrentSizeLabel,
          ));
        },
      );

      stderrSub = process.stderr
          .transform(decoder)
          .transform(const LineSplitter())
          .listen((line) {
        stderrBuffer.writeln(line);
        debugPrint('[download_service] stderr: $line');
      });

      debugPrint('[download_service] awaiting exit code for $taskId');

      int exitCode;
      try {
        exitCode = await process.exitCode.timeout(
          const Duration(minutes: 30),
          onTimeout: () {
            debugPrint('[download_service] SIGKILL — $taskId unresponsive');
            process?.kill();
            return -1;
          },
        );
      } on TimeoutException {
        process.kill();
        exitCode = -1;
      }

      debugPrint('[download_service] exit code $exitCode for task $taskId');
      if (exitCode == 0) {
        if (!controller.isClosed) {
          controller.add(const DownloadProgress(
            percent: 100, isDone: true, phase: 'Complete',
          ));
        }
      } else {
        if (!controller.isClosed) {
          controller.addError(
            Exception(
              stderrBuffer.isNotEmpty
                  ? stderrBuffer.toString()
                  : 'yt-dlp exited with code $exitCode',
            ),
          );
        }
      }
    } catch (e, st) {
      debugPrint('[download_service] error for $taskId: $e $st');
      if (!controller.isClosed) {
        controller.addError(e, st);
      }
    } finally {
      _processes.remove(taskId);
      await stdoutSub?.cancel();
      await stderrSub?.cancel();
      if (process != null) {
        final killed = process.kill();
        debugPrint('[download_service] cleanup $taskId — kill=$killed');
      }
      if (!controller.isClosed) {
        controller.close();
      }
    }
  }

  void cancel(String taskId) {
    _processes[taskId]?.kill();
    _processes.remove(taskId);
  }

  void cancelAll() {
    for (final p in _processes.values) {
      p.kill();
    }
    _processes.clear();
  }
}
