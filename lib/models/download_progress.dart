/// Represents a real-time download progress snapshot parsed from yt-dlp stdout.
class DownloadProgress {
  final double percent; // 0.0 – 100.0
  final String? speedLabel; // e.g. "2.30MiB/s"
  final String? etaLabel; // e.g. "00:12"
  final String? sizeLabel; // e.g. "100.00MiB" — total size
  final String? currentSizeLabel; // e.g. "45.30 MiB" — bytes downloaded so far
  final bool isDone;
  final String? phase; // e.g. "Merging Audio & Video...", "Resuming download..."

  const DownloadProgress({
    required this.percent,
    this.speedLabel,
    this.etaLabel,
    this.sizeLabel,
    this.currentSizeLabel,
    this.isDone = false,
    this.phase,
  });

  static const done = DownloadProgress(percent: 100, isDone: true);

  /// Creates a phase-only update (no numeric progress change).
  factory DownloadProgress.phase(String phase) {
    return DownloadProgress(percent: 0, phase: phase);
  }

  DownloadProgress copyWith({
    double? percent,
    String? phase,
    String? speedLabel,
    String? etaLabel,
    String? sizeLabel,
    String? currentSizeLabel,
    bool? isDone,
  }) {
    return DownloadProgress(
      percent: percent ?? this.percent,
      speedLabel: speedLabel ?? this.speedLabel,
      etaLabel: etaLabel ?? this.etaLabel,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      currentSizeLabel: currentSizeLabel ?? this.currentSizeLabel,
      isDone: isDone ?? this.isDone,
      phase: phase ?? this.phase,
    );
  }

  /// Parses a size string like "28.00MiB" into (value, unit).
  static (double value, String unit)? _parseSize(String raw) {
    final m = RegExp(r'^([\d.]+)\s*(\w+)$').firstMatch(raw.trim());
    if (m == null) return null;
    final v = double.tryParse(m.group(1)!);
    if (v == null) return null;
    return (v, m.group(2)!);
  }

  /// Formats a size value + unit back to a display string with a space.
  static String _formatSize(double value, String unit) =>
      '${value.toStringAsFixed(2)} $unit';

  /// Parses a yt-dlp stdout line like:
  /// [download]  45.3% of 100.00MiB at 2.30MiB/s ETA 00:12
  static DownloadProgress? tryParse(String line) {
    if (!line.contains('[download]')) return null;

    // Match percentage
    final percentMatch = RegExp(r'(\d+\.?\d*)%').firstMatch(line);
    if (percentMatch == null) return null;

    final percent = double.tryParse(percentMatch.group(1)!) ?? 0;

    // Match size: "of X" (handles optional "~" prefix for unknown sizes)
    final sizeMatch = RegExp(r'of\s+~?\s*([\d.]+\s*\w+)').firstMatch(line);
    final rawSize = sizeMatch?.group(1)?.trim();
    String? sizeLabel;
    String? currentSizeLabel;

    if (rawSize != null) {
      final parsed = _parseSize(rawSize);
      if (parsed != null) {
        final (totalValue, unit) = parsed;
        final currentValue = totalValue * percent / 100;
        currentSizeLabel = _formatSize(currentValue, unit);
        sizeLabel = _formatSize(totalValue, unit);
      } else {
        sizeLabel = rawSize;
      }
    }

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
      currentSizeLabel: currentSizeLabel,
    );
  }

  /// Parses yt-dlp stdout lines that indicate post-processing or status phases.
  /// Returns a [DownloadProgress] with [phase] set, or null if not a phase line.
  static DownloadProgress? tryParsePhase(String line) {
    if (line.contains('[ffmpeg]')) {
      return DownloadProgress.phase('Processing with FFmpeg...');
    }
    if (line.contains('[VideoConvertor]')) {
      return DownloadProgress.phase('Converting video...');
    }
    if (line.contains('[Metadata]')) {
      return DownloadProgress.phase('Writing metadata...');
    }
    if (line.contains('[download]') && line.contains('Checking existing')) {
      return DownloadProgress.phase('Checking existing data...');
    }
    if (line.contains('[download]') && line.contains('Already downloaded')) {
      return DownloadProgress.phase('Already downloaded, verifying...');
    }
    if (line.contains('[info]') && line.contains('Downloading subtitles')) {
      return DownloadProgress.phase('Downloading subtitles...');
    }
    if (line.contains('[info]') && line.contains('Writing video subtitles')) {
      return DownloadProgress.phase('Writing subtitles...');
    }
    if (line.contains('[info]') &&
        (line.contains('Downloading') || line.contains('format') || line.contains('Download'))) {
      return DownloadProgress.phase('Initializing...');
    }
    return null;
  }
}
