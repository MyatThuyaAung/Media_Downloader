/// Represents a real-time download progress snapshot parsed from yt-dlp stdout.
class DownloadProgress {
  final double percent; // 0.0 – 100.0
  final String? speedLabel; // e.g. "2.30MiB/s"
  final String? etaLabel; // e.g. "00:12"
  final String? sizeLabel; // e.g. "100.00MiB"
  final bool isDone;

  const DownloadProgress({
    required this.percent,
    this.speedLabel,
    this.etaLabel,
    this.sizeLabel,
    this.isDone = false,
  });

  static const done = DownloadProgress(percent: 100, isDone: true);

  /// Parses a yt-dlp stdout line like:
  /// [download]  45.3% of 100.00MiB at 2.30MiB/s ETA 00:12
  static DownloadProgress? tryParse(String line) {
    if (!line.contains('[download]')) return null;

    // Match percentage
    final percentMatch = RegExp(r'(\d+\.?\d*)%').firstMatch(line);
    if (percentMatch == null) return null;

    final percent = double.tryParse(percentMatch.group(1)!) ?? 0;

    // Match size: "of X"
    final sizeMatch = RegExp(r'of\s+([\d.]+\s*\w+)').firstMatch(line);
    final sizeLabel = sizeMatch?.group(1)?.trim();

    // Match speed: "at X"
    final speedMatch = RegExp(r'at\s+([\d.]+\s*\w+/s)').firstMatch(line);
    final speedLabel = speedMatch?.group(1)?.trim();

    // Match ETA
    final etaMatch = RegExp(r'ETA\s+(\d+:\d+)').firstMatch(line);
    final etaLabel = etaMatch?.group(1)?.trim();

    return DownloadProgress(
      percent: percent,
      speedLabel: speedLabel,
      etaLabel: etaLabel,
      sizeLabel: sizeLabel,
    );
  }
}
