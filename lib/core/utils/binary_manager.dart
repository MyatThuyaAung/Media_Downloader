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
  String? _denoPath;
  bool _ytDlpUpdated = false;

  static final _binDir = _BinDir();

  /// Returns the path to a usable yt-dlp executable.
  ///
  /// Resolution chain (top wins):
  /// 1. already-resolved cached path
  /// 2. downloaded from GitHub releases (standalone binary)
  /// 3. extracted-from-assets copy in app-support dir (may be pip shim)
  /// 4. system-installed yt-dlp (via PATH / `which` / `where`) — last resort
  ///
  /// After a GitHub download, a background `--update-to stable` is triggered.
  /// The asset/sytem paths avoid `--update-to` to prevent pip-shim corruption.
  Future<String> get ytDlpPath async {
    if (_ytDlpPath != null && File(_ytDlpPath!).existsSync()) {
      return _ytDlpPath!;
    }

    // 1. Cached / previously-extracted in app-support dir
    final cached = await _cachedYtDlpPath();
    if (cached != null) {
      _ytDlpPath = cached;
      return cached;
    }

    // 2. Download from GitHub releases (standalone binary, always fresh)
    try {
      debugPrint('[binary_manager] downloading yt-dlp from GitHub...');
      final downloaded = await downloadYtDlp();
      _ytDlpPath = downloaded;
      _scheduleUpdate(downloaded);
      return downloaded;
    } catch (e) {
      debugPrint('[binary_manager] yt-dlp download failed: $e');
    }

    // 3. Extract from bundled assets (may be pip shim — skip update)
    try {
      final extracted = await _extractYtDlp();
      _ytDlpPath = extracted;
      return extracted;
    } catch (e) {
      debugPrint('[binary_manager] asset extraction failed: $e');
    }

    // 4. System-installed (last resort — skip update)
    final system = await _findSystemExecutable('yt-dlp');
    if (system != null) {
      _ytDlpPath = system;
      return system;
    }

    throw Exception(
      'yt-dlp not found. Check your network connection or install yt-dlp manually.',
    );
  }

  /// Returns the path to a usable FFmpeg executable.
  ///
  /// Resolution chain:
  /// 1. already-resolved cached path
  /// 2. extracted-from-assets copy in app-support dir
  /// 3. system-installed ffmpeg (via PATH) — last resort
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

  /// Returns the path to a usable Deno executable.
  ///
  /// Resolution chain:
  /// 1. already-resolved cached path
  /// 2. cached copy in app-support dir
  /// 3. downloaded from GitHub releases
  /// 4. system-installed deno (via PATH) — last resort
  Future<String> get denoPath async {
    if (_denoPath != null && File(_denoPath!).existsSync()) {
      return _denoPath!;
    }

    // 1. Cached in app-support dir
    final cached = await _cachedDenoPath();
    if (cached != null) {
      _denoPath = cached;
      return cached;
    }

    // 2. Download from GitHub releases
    try {
      debugPrint('[binary_manager] downloading deno from GitHub...');
      final downloaded = await downloadDeno();
      _denoPath = downloaded;
      return downloaded;
    } catch (e) {
      debugPrint('[binary_manager] deno download failed: $e');
    }

    // 3. System-installed (last resort)
    final system = await _findSystemExecutable('deno');
    if (system != null) {
      _denoPath = system;
      return system;
    }

    throw Exception(
      'Deno not found. Check your network connection or install deno manually.',
    );
  }

  /// Resolves all three binaries sequentially (yt-dlp → ffmpeg → deno).
  /// Throws on the first failure.
  Future<void> initAll() async {
    await ytDlpPath;
    await ffmpegPath;
    await denoPath;
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

  static Future<String?> _cachedDenoPath() async {
    final dir = await _binDir.get();
    final exe = File('${dir.path}/${PlatformUtils.denoExecutableName}');
    if (exe.existsSync()) {
      _makeExecutable(exe.path);
      return exe.path;
    }
    return null;
  }

  static Future<String?> _cachedYtDlpPath() async {
    final dir = await _binDir.get();
    final exe = File('${dir.path}/${PlatformUtils.ytDlpExecutableName}');
    if (exe.existsSync()) {
      // Skip pip-shim binaries (standalone yt-dlp.exe is > 3 MB)
      if (exe.lengthSync() < 1_000_000) {
        debugPrint('[binary_manager] cached yt-dlp too small — likely a pip shim, removing');
        exe.deleteSync();
        return null;
      }
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
      final sink = file.openWrite();
      await sink.addStream(response);
      await sink.close();
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

  // ── Deno download & extraction ──────────────────────────────────────────

  /// Downloads the latest Deno binary from GitHub releases.
  /// Returns the path to the extracted executable.
  Future<String> downloadDeno() async {
    final dir = await _binDir.get();
    final zipPath = '${dir.path}/deno.zip';
    final url = PlatformUtils.denoDownloadUrl;

    debugPrint('[binary_manager] downloading deno from $url');

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'MediaDownloader/1.0');
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download deno: HTTP ${response.statusCode}',
        );
      }

      final file = File(zipPath);
      final sink = file.openWrite();
      await sink.addStream(response);
      await sink.close();
    } finally {
      client.close();
    }

    await _extractZip(zipPath, dir.path);
    if (File(zipPath).existsSync()) {
      File(zipPath).deleteSync();
    }

    final destPath = '${dir.path}/${PlatformUtils.denoExecutableName}';
    _makeExecutable(destPath);
    debugPrint('[binary_manager] deno ready at $destPath');
    return destPath;
  }

  static Future<void> _extractZip(String zipPath, String destDir) async {
    if (Platform.isWindows) {
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          "Expand-Archive -LiteralPath '$zipPath' -DestinationPath '$destDir' -Force",
        ],
      );
      if (result.exitCode != 0) {
        throw Exception(
          'Failed to extract deno zip: ${result.stderr}',
        );
      }
    } else {
      final result = await Process.run(
        'unzip',
        ['-o', zipPath, '-d', destDir],
      );
      if (result.exitCode != 0) {
        throw Exception(
          'Failed to extract deno zip: ${result.stderr}',
        );
      }
    }
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
