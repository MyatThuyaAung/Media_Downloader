import 'dart:io';

class PlatformUtils {
  PlatformUtils._();

  // ── OS detection ─────────────────────────────────────────────────────────

  static bool get _isWindows => Platform.isWindows;
  static bool get _isMacOS => Platform.isMacOS;

  // ── yt-dlp ───────────────────────────────────────────────────────────────

  static String get ytDlpExecutableName =>
      _isWindows ? 'yt-dlp.exe' : 'yt-dlp';

  static String get ytDlpAssetPath {
    if (_isWindows) return 'assets/binaries/windows/yt-dlp.exe';
    if (_isMacOS) return 'assets/binaries/macos/yt-dlp';
    return 'assets/binaries/linux/yt-dlp';
  }

  // ── Deno ─────────────────────────────────────────────────────────────────

  static String get denoExecutableName =>
      _isWindows ? 'deno.exe' : 'deno';

  static String get denoDownloadUrl {
    if (_isWindows) {
      return 'https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip';
    }
    // Linux
    return 'https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip';
  }

  // ── Folder utilities ─────────────────────────────────────────────────────

  /// Opens the containing folder of [outputPath] in the system file manager.
  /// If the path contains the yt-dlp `%(ext)s` template placeholder, it is
  /// stripped before extracting the parent directory.
  static void openContainingFolder(String outputPath) {
    final cleanPath = outputPath.replaceAll('%(ext)s', '');
    final dir = Directory(cleanPath).parent;
    if (!dir.existsSync()) return;

    if (_isWindows) {
      Process.run('explorer', [dir.path]);
    } else if (_isMacOS) {
      Process.run('open', [dir.path]);
    } else {
      Process.run('xdg-open', [dir.path]);
    }
  }

  // ── ffmpeg ───────────────────────────────────────────────────────────────

  static String get ffmpegExecutableName =>
      _isWindows ? 'ffmpeg.exe' : 'ffmpeg';

  static String get ffmpegAssetPath {
    if (_isWindows) return 'assets/binaries/windows/ffmpeg.exe';
    if (_isMacOS) return 'assets/binaries/macos/ffmpeg';
    return 'assets/binaries/linux/ffmpeg';
  }
}
