class PlaylistEntry {
  final String id;
  final String title;
  final String url;
  final String? thumbnailUrl;
  final int duration;
  final String? uploader;
  final int? viewCount;

  const PlaylistEntry({
    required this.id,
    required this.title,
    required this.url,
    this.thumbnailUrl,
    this.duration = 0,
    this.uploader,
    this.viewCount,
  });

  factory PlaylistEntry.fromJson(Map<String, dynamic> json) {
    return PlaylistEntry(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      url: json['url'] ?? json['webpage_url'] ?? '',
      thumbnailUrl: json['thumbnail'] as String?,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      uploader: json['uploader'] as String?,
      viewCount: (json['view_count'] as num?)?.toInt(),
    );
  }
}

class PlaylistInfo {
  final String title;
  final String? uploader;
  final String webpageUrl;
  final List<PlaylistEntry> entries;

  const PlaylistInfo({
    required this.title,
    this.uploader,
    required this.webpageUrl,
    this.entries = const [],
  });

  factory PlaylistInfo.fromJson(Map<String, dynamic> json) {
    final rawEntries = (json['entries'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PlaylistEntry.fromJson)
        .toList();

    return PlaylistInfo(
      title: json['title'] ?? '',
      uploader: json['uploader'] as String?,
      webpageUrl: json['webpage_url'] ?? '',
      entries: rawEntries,
    );
  }
}
