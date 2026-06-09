import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/download_progress.dart';
import '../utils/platform_utils.dart';

class DownloadService {
  static String? _ytDlpPath;
  static String? _ffmpegPath;

  // ── Per-task phase tracking ────────────────────────────────────────────
  int _streamCount = 0;
  bool _inSubtitlePhase = false;
  bool _inMergerPhase = false;
  double _mainPercent = 0;
  String? _mainSizeLabel;
  String? _mainCurrentSizeLabel;

  static const _subtitleExtensions = ['.vtt', '.srt', '.ass', '.ssa', '.lrc'];

  bool _isSubtitleDest(String dest) {
    final lower = dest.toLowerCase();
    return _subtitleExtensions.any((ext) => lower.endsWith(ext)) ||
        lower.contains('subtitle');
  }

  /// Returns the path to the yt-dlp executable (shared cache with YtDlpService).
  Future<String> get ytDlpExecutable async {
    if (_ytDlpPath != null) return _ytDlpPath!;

    final supportDir = await getApplicationSupportDirectory();
    final binDir = Directory('${supportDir.path}/binaries');
    if (!binDir.existsSync()) {
      binDir.createSync(recursive: true);
    }

    final exeName = PlatformUtils.ytDlpExecutableName;
    final exePath = '${binDir.path}/$exeName';
    final exeFile = File(exePath);

    if (!exeFile.existsSync()) {
      final data = await rootBundle.load(PlatformUtils.ytDlpAssetPath);
      final bytes = data.buffer.asUint8List();
      await exeFile.writeAsBytes(bytes, flush: true);

      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', exePath]);
      }
    }

    _ytDlpPath = exePath;
    return exePath;
  }

  /// Returns the path to the FFmpeg executable, extracting it from assets
  /// to the app support directory on first call.
  Future<String> get ffmpegExecutable async {
    if (_ffmpegPath != null) return _ffmpegPath!;

    final supportDir = await getApplicationSupportDirectory();
    final binDir = Directory('${supportDir.path}/binaries');
    if (!binDir.existsSync()) {
      binDir.createSync(recursive: true);
    }

    final exeName = PlatformUtils.ffmpegExecutableName;
    final exePath = '${binDir.path}/$exeName';
    final exeFile = File(exePath);

    if (!exeFile.existsSync()) {
      final data = await rootBundle.load(PlatformUtils.ffmpegAssetPath);
      final bytes = data.buffer.asUint8List();
      await exeFile.writeAsBytes(bytes, flush: true);

      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', exePath]);
      }
    }

    _ffmpegPath = exePath;
    return exePath;
  }

  final Map<String, Process> _processes = {};

  /// Downloads a video/audio track and emits [DownloadProgress] events.
  ///
  /// [taskId] is used to track this download for cancellation.
  /// [formatId] is the yt-dlp format id (e.g. "137+140", "bestaudio").
  /// [outputPath] is the full file path template (yt-dlp -o syntax accepted).
  /// [resume] when true adds `--continue` to resume a partial download.
  /// [subtitleLang] language code for subtitles (null = none, 'en' = English).
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
      final executable = await ytDlpExecutable;
      final ffmpegPath = await ffmpegExecutable;

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
      _mainPercent = 0;
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
            if (_isSubtitleDest(dest)) {
              _inSubtitlePhase = true;
              controller.add(DownloadProgress(
                percent: _mainPercent.clamp(0, 100),
                phase: 'Downloading Subtitles',
                sizeLabel: _mainSizeLabel,
                currentSizeLabel: _mainCurrentSizeLabel,
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
            controller.add(const DownloadProgress(
              percent: 100,
              phase: 'Remuxing...',
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
              percent: _mainPercent.clamp(0, 100),
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

          if (progress.percent > _mainPercent) {
            _mainPercent = progress.percent;
            _mainSizeLabel = progress.sizeLabel;
            _mainCurrentSizeLabel = progress.currentSizeLabel;
          }

          controller.add(DownloadProgress(
            percent: progress.percent,
            phase: _streamCount == 0
                ? 'Downloading Video'
                : (_streamCount == 1
                    ? 'Downloading Video'
                    : 'Downloading Audio'),
            speedLabel: progress.speedLabel,
            etaLabel: progress.etaLabel,
            sizeLabel: progress.sizeLabel,
            currentSizeLabel: progress.currentSizeLabel,
          ));
        },
      );

      stderrSub = process.stderr
          .transform(decoder)
          .transform(const LineSplitter())
          .listen((line) => stderrBuffer.writeln(line));

      debugPrint('[download_service] awaiting exit code for $taskId');

      // ── Robust exit-code waiter with timeout ────────────────────
      // On Windows, process.exitCode may never complete if the process
      // hangs or the stdout pipe is in a bad state.  We use a short
      // polling-like approach: a 5-minute timeout, then force-kill.
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
        // Safety net: if timeout throws (null onTimeout), kill directly
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

  /// Kills the download process identified by [taskId].
  void cancel(String taskId) {
    _processes[taskId]?.kill();
    _processes.remove(taskId);
  }

  /// Kills all active processes.
  void cancelAll() {
    for (final p in _processes.values) {
      p.kill();
    }
    _processes.clear();
  }
}
