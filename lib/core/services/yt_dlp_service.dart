import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/video_info.dart';
import '../utils/platform_utils.dart';

class YtDlpService {
  static String? _ytDlpPath;

  /// Returns the path to the yt-dlp executable, extracting it from assets
  /// to the app support directory on first call.
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

      // Make executable on Linux/macOS
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', exePath]);
      }
    }

    _ytDlpPath = exePath;
    return exePath;
  }

  /// Fetches video metadata (including available formats) using --dump-single-json.
  Future<VideoInfo> fetchVideoInfo(String url, {String? cookiesBrowser}) async {
    final executable = await ytDlpExecutable;

    final args = [
      '--dump-single-json',
      '--no-playlist',
      '--encoding', 'utf-8',
    ];

    if (cookiesBrowser != null &&
        cookiesBrowser.isNotEmpty &&
        cookiesBrowser.toLowerCase() != 'none') {
      args.addAll(['--cookies-from-browser', cookiesBrowser.toLowerCase()]);
    }

    args.add(url);

    final process = await Process.start(
      executable,
      args,
    );

    const decoder = Utf8Decoder(allowMalformed: true);
    final outputFuture = process.stdout.transform(decoder).join();
    final errorFuture = process.stderr.transform(decoder).join();

    final results = await Future.wait([outputFuture, errorFuture]);
    final output = results[0];
    final error = results[1];

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception(
        error.isNotEmpty ? error : 'yt-dlp exited with code $exitCode',
      );
    }

    final json = jsonDecode(output) as Map<String, dynamic>;
    return VideoInfo.fromJson(json);
  }
}