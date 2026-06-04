import 'video_format.dart';

class VideoInfo {
  final String title;
  final String uploader;
  final String thumbnailUrl;
  final int duration;
  final List<VideoFormat> formats;
  final String? description;
  final int? viewCount;

  const VideoInfo({
    required this.title,
    required this.uploader,
    required this.thumbnailUrl,
    required this.duration,
    this.formats = const [],
    this.description,
    this.viewCount,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    final rawFormats = (json['formats'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(VideoFormat.fromJson)
        .toList();

    return VideoInfo(
      title: json['title'] ?? '',
      uploader: json['uploader'] ?? json['channel'] ?? 'Unknown',
      thumbnailUrl: json['thumbnail'] ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      formats: buildFormatMenu(rawFormats),
      description: json['description'] as String?,
      viewCount: (json['view_count'] as num?)?.toInt(),
    );
  }
}