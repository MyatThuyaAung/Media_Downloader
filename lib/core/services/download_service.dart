import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/download_progress.dart';
import '../utils/platform_utils.dart';

class DownloadService {
  static String? _ytDlpPath;

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

  Process? _activeProcess;

  /// Downloads a video/audio track and emits [DownloadProgress] events.
  ///
  /// [formatId] is the yt-dlp format id (e.g. "137+140", "bestaudio").
  /// [outputPath] is the full file path template (yt-dlp -o syntax accepted).
  Stream<DownloadProgress> download({
    required String url,
    required String formatId,
    required String outputPath,
    String? cookiesBrowser,
  }) {
    final controller = StreamController<DownloadProgress>();

    _startDownload(
      url: url,
      formatId: formatId,
      outputPath: outputPath,
      cookiesBrowser: cookiesBrowser,
      controller: controller,
    );

    return controller.stream;
  }

  Future<void> _startDownload({
    required String url,
    required String formatId,
    required String outputPath,
    required StreamController<DownloadProgress> controller,
    String? cookiesBrowser,
  }) async {
    try {
      final executable = await ytDlpExecutable;

      final args = [
        '-f', formatId,
        '--merge-output-format', 'mp4',
        '--newline',
        '--encoding', 'utf-8',
      ];

      if (cookiesBrowser != null &&
          cookiesBrowser.isNotEmpty &&
          cookiesBrowser.toLowerCase() != 'none') {
        args.addAll(['--cookies-from-browser', cookiesBrowser.toLowerCase()]);
      }

      args.addAll(['-o', outputPath, url]);

      _activeProcess = await Process.start(
        executable,
        args,
      );

      const decoder = Utf8Decoder(allowMalformed: true);

      // Parse stdout for progress
      _activeProcess!.stdout
          .transform(decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          final progress = DownloadProgress.tryParse(line);
          if (progress != null && !controller.isClosed) {
            controller.add(progress);
          }
        },
      );

      // Capture stderr for error reporting
      final stderrBuffer = StringBuffer();
      _activeProcess!.stderr
          .transform(decoder)
          .transform(const LineSplitter())
          .listen((line) => stderrBuffer.writeln(line));

      final exitCode = await _activeProcess!.exitCode;

      if (exitCode == 0) {
        if (!controller.isClosed) {
          controller.add(DownloadProgress.done);
          controller.close();
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
          controller.close();
        }
      }
    } catch (e, st) {
      if (!controller.isClosed) {
        controller.addError(e, st);
        controller.close();
      }
    }
  }

  /// Kills the active download process if one is running.
  void cancel() {
    _activeProcess?.kill();
    _activeProcess = null;
  }
}
