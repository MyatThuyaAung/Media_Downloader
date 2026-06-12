import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'platform_utils.dart';

class BinaryManager {
  BinaryManager._();

  static final BinaryManager _instance = BinaryManager._();
  static BinaryManager get instance => _instance;

  String? _ytDlpPath;
  String? _ffmpegPath;
  bool _ytDlpUpdated = false;

  static final _binDir = _BinDir();

  /// Returns the path to a usable yt-dlp executable.
  ///
  /// Resolution chain (top wins):
  /// 1. already-resolved cached path
  /// 2. system-installed yt-dlp (via PATH / `which` / `where`)
  /// 3. extracted-from-assets copy in app-support dir
  /// 4. downloaded from GitHub releases (last resort)
  ///
  /// After resolution, a background `--update-to stable` is triggered
  /// so subsequent uses get the latest extractors.
  Future<String> get ytDlpPath async {
    if (_ytDlpPath != null && File(_ytDlpPath!).existsSync()) {
      return _ytDlpPath!;
    }

    // 1. Cached / previously-extracted in app-support dir
    final cached = await _cachedYtDlpPath();
    if (cached != null) {
      _ytDlpPath = cached;
      _scheduleUpdate(cached);
      return cached;
    }

    // 2. System-installed
    final system = await _findSystemExecutable('yt-dlp');
    if (system != null) {
      _ytDlpPath = system;
      _scheduleUpdate(system);
      return system;
    }

    // 3. Extract from bundled assets
    try {
      final extracted = await _extractYtDlp();
      _ytDlpPath = extracted;
      _scheduleUpdate(extracted);
      return extracted;
    } catch (e) {
      debugPrint('[binary_manager] asset extraction failed: $e');
    }

    // 4. Download from GitHub releases (last resort)
    debugPrint('[binary_manager] downloading yt-dlp from GitHub...');
    final downloaded = await downloadYtDlp();
    _ytDlpPath = downloaded;
    _scheduleUpdate(downloaded);
    return downloaded;
  }

  /// Returns the path to a usable FFmpeg executable.
  ///
  /// Resolution chain:
  /// 1. already-resolved cached path
  /// 2. extracted-from-assets copy in app-support dir
  /// 3. system-installed ffmpeg (via PATH)
  Future<String> get ffmpegPath async {
    if (_ffmpegPath != null && File(_ffmpegPath!).existsSync()) {
      return _ffmpegPath!;
    }

    // 1. Extracted from assets
    final extracted = await _extractFfmpeg();
    if (extracted != null) {
      _ffmpegPath = extracted;
      return extracted;
    }

    // 2. System-installed
    final system = await _findSystemExecutable('ffmpeg');
    if (system != null) {
      _ffmpegPath = system;
      return system;
    }

    throw Exception(
      'FFmpeg not found. Install ffmpeg or place it in $binDirPath.',
    );
  }

  // ── Update ───────────────────────────────────────────────────────────────

  /// Runs `yt-dlp --update-to stable` on the resolved binary.
  /// Silently succeeds if already current; logs failures without throwing.
  Future<void> updateYtDlp() async {
    final exe = _ytDlpPath;
    if (exe == null || !File(exe).existsSync()) {
      return;
    }
    try {
      final result = await Process.run(exe, ['--update-to', 'stable'],
          runInShell: Platform.isWindows);
      if (result.exitCode == 0) {
        debugPrint('[binary_manager] yt-dlp updated successfully');
      } else {
        final stderr = (result.stderr as String?)?.trim();
        if (stderr != null && stderr.isNotEmpty) {
          debugPrint('[binary_manager] yt-dlp update note: $stderr');
        }
      }
    } catch (e) {
      debugPrint('[binary_manager] yt-dlp update skipped: $e');
    }
    _ytDlpUpdated = true;
  }

  void _scheduleUpdate(String exePath) {
    if (!_ytDlpUpdated) {
      _ytDlpUpdated = true;
      updateYtDlp().ignore();
    }
  }

  // ── System PATH search ───────────────────────────────────────────────────

  static Future<String?> _findSystemExecutable(String name) async {
    try {
      final which = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(which, [name],
          runInShell: true);
      if (result.exitCode == 0) {
        final path = (result.stdout as String)
            .trim()
            .split(RegExp(r'[\r\n]+'))
            .firstWhere(
              (p) => p.isNotEmpty,
              orElse: () => '',
            );
        if (path.isNotEmpty && File(path).existsSync()) {
          debugPrint('[binary_manager] found system $name: $path');
          return path;
        }
      }
    } catch (e) {
      debugPrint('[binary_manager] which/where failed for $name: $e');
    }
    return null;
  }

  // ── Cache / extraction ───────────────────────────────────────────────────

  static String get binDirPath => _binDir.path;

  static Future<String?> _cachedYtDlpPath() async {
    final dir = await _binDir.get();
    final exe = File('${dir.path}/${PlatformUtils.ytDlpExecutableName}');
    if (exe.existsSync()) {
      _makeExecutable(exe.path);
      return exe.path;
    }
    return null;
  }

  static Future<String> _extractYtDlp() async {
    final dir = await _binDir.get();
    final destPath = '${dir.path}/${PlatformUtils.ytDlpExecutableName}';
    final dest = File(destPath);

    if (!dest.existsSync()) {
      debugPrint('[binary_manager] extracting yt-dlp from assets...');
      final data = await rootBundle.load(PlatformUtils.ytDlpAssetPath);
      await dest.writeAsBytes(data.buffer.asUint8List(), flush: true);
      _makeExecutable(destPath);
    }
    return destPath;
  }

  static Future<String?> _extractFfmpeg() async {
    try {
      final dir = await _binDir.get();
      final destPath = '${dir.path}/${PlatformUtils.ffmpegExecutableName}';
      final dest = File(destPath);

      if (!dest.existsSync()) {
        debugPrint('[binary_manager] extracting ffmpeg from assets...');
        final data = await rootBundle.load(PlatformUtils.ffmpegAssetPath);
        await dest.writeAsBytes(data.buffer.asUint8List(), flush: true);
        _makeExecutable(destPath);
      }
      return destPath;
    } catch (e) {
      debugPrint('[binary_manager] failed to extract ffmpeg: $e');
      return null;
    }
  }

  static void _makeExecutable(String path) {
    if (!Platform.isWindows) {
      Process.run('chmod', ['+x', path]).ignore();
    }
  }

  // ── GitHub download fallback (last resort for yt-dlp) ────────────────────

  /// Downloads the latest yt-dlp binary from GitHub releases into [destDir].
  /// Returns the path to the downloaded binary.
  Future<String> downloadYtDlp({String? destDir}) async {
    final dir = destDir ?? (await _binDir.get()).path;
    final destPath = '$dir/${PlatformUtils.ytDlpExecutableName}';
    final url = _ytDlpDownloadUrl;

    debugPrint('[binary_manager] downloading yt-dlp from $url');

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'MediaDownloader/1.0');
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download yt-dlp: HTTP ${response.statusCode}',
        );
      }

      final file = File(destPath);
      await file.openWrite().addStream(response);
      _makeExecutable(destPath);
      debugPrint('[binary_manager] yt-dlp downloaded to $destPath');
      return destPath;
    } finally {
      client.close();
    }
  }

  static String get _ytDlpDownloadUrl {
    if (Platform.isWindows) {
      return 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';
    }
    if (Platform.isMacOS) {
      return 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos';
    }
    // Linux
    return 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux';
  }
}

/// Lazy-initialised handle to the app-support binaries directory.
class _BinDir {
  String? _path;

  String get path {
    if (_path == null) {
      throw StateError(
        'BinaryManager directory not yet resolved. Call get() first.',
      );
    }
    return _path!;
  }

  Future<Directory> get() async {
    if (_path != null) return Directory(_path!);

    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}/binaries');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _path = dir.path;
    return dir;
  }
}

extension _FutureIgnorer<T> on Future<T> {
  void ignore() {}
}
