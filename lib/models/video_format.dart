/// Represents a single downloadable format from yt-dlp's format list.
class VideoFormat {
  final String formatId;
  final String ext;
  final int? height; // null for audio-only formats
  final double? tbr; // total bitrate in kbps
  final String? vcodec;
  final String? acodec;
  final String label; // human-readable label shown in the UI

  const VideoFormat({
    required this.formatId,
    required this.ext,
    this.height,
    this.tbr,
    this.vcodec,
    this.acodec,
    required this.label,
  });

  bool get isAudioOnly =>
      (vcodec == null || vcodec == 'none') &&
      acodec != null &&
      acodec != 'none';

  factory VideoFormat.fromJson(Map<String, dynamic> json) {
    final formatId = json['format_id']?.toString() ?? '';
    final ext = json['ext']?.toString() ?? '';
    final height = json['height'] as int?;
    final tbr = (json['tbr'] as num?)?.toDouble();
    final vcodec = json['vcodec']?.toString();
    final acodec = json['acodec']?.toString();

    final isAudio =
        (vcodec == null || vcodec == 'none') && acodec != null && acodec != 'none';

    String label;
    if (isAudio) {
      final bitrateStr = tbr != null ? '${tbr.round()}kbps' : '';
      label = 'Audio only${bitrateStr.isNotEmpty ? ' • $bitrateStr' : ''} ($ext)';
    } else if (height != null) {
      label = '${height}p ($ext)';
    } else {
      label = '$formatId ($ext)';
    }

    return VideoFormat(
      formatId: formatId,
      ext: ext,
      height: height,
      tbr: tbr,
      vcodec: vcodec,
      acodec: acodec,
      label: label,
    );
  }

  Map<String, dynamic> toJson() => {
        'format_id': formatId,
        'ext': ext,
        'height': height,
        'tbr': tbr,
        'vcodec': vcodec,
        'acodec': acodec,
        'label': label,
      };

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      other is VideoFormat && other.formatId == formatId;

  @override
  int get hashCode => formatId.hashCode;
}

/// Returns a deduplicated, sorted list of formats suitable for the UI.
/// Groups by resolution: Best, 1080p, 720p, 480p, 360p, Audio only.
List<VideoFormat> buildFormatMenu(List<VideoFormat> raw) {
  // Separate video+audio muxed/adaptive and audio-only
  final videoFormats = raw
      .where((f) => f.height != null && !(f.vcodec == null || f.vcodec == 'none'))
      .toList();

  final audioFormats = raw.where((f) => f.isAudioOnly).toList();

  // Deduplicate by height — keep highest tbr per height
  final Map<int, VideoFormat> byHeight = {};
  for (final f in videoFormats) {
    final h = f.height!;
    if (!byHeight.containsKey(h) ||
        (f.tbr ?? 0) > (byHeight[h]!.tbr ?? 0)) {
      byHeight[h] = f;
    }
  }

  // Sort descending by height
  final sortedVideo = byHeight.values.toList()
    ..sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));

  // Best audio: highest tbr
  VideoFormat? bestAudio;
  if (audioFormats.isNotEmpty) {
    bestAudio = audioFormats
        .reduce((a, b) => (a.tbr ?? 0) >= (b.tbr ?? 0) ? a : b);
  }

  return [
    ...sortedVideo,
    ?bestAudio,
  ];
}
