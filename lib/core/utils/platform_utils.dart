import 'dart:io';

/// Platform-aware paths for bundled executables.
class PlatformUtils {
  PlatformUtils._();

  static String get ytDlpExecutableName =>
      Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp';

  static String get ytDlpAssetPath => Platform.isWindows
      ? 'assets/binaries/windows/yt-dlp.exe'
      : 'assets/binaries/linux/yt-dlp';

  static String get ffmpegExecutableName =>
      Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';

  static String get ffmpegAssetPath => Platform.isWindows
      ? 'assets/binaries/windows/ffmpeg.exe'
      : 'assets/binaries/linux/ffmpeg';
}
