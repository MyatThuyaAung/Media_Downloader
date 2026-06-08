import 'video_format.dart';

const _languageNames = <String, String>{
  'en': 'English', 'ja': 'Japanese', 'es': 'Spanish', 'fr': 'French',
  'de': 'German', 'it': 'Italian', 'pt': 'Portuguese', 'ru': 'Russian',
  'ko': 'Korean', 'zh': 'Chinese', 'ar': 'Arabic', 'hi': 'Hindi',
  'id': 'Indonesian', 'th': 'Thai', 'vi': 'Vietnamese', 'nl': 'Dutch',
  'pl': 'Polish', 'tr': 'Turkish', 'sv': 'Swedish', 'da': 'Danish',
  'fi': 'Finnish', 'no': 'Norwegian', 'cs': 'Czech', 'hu': 'Hungarian',
  'ro': 'Romanian', 'uk': 'Ukrainian', 'el': 'Greek', 'he': 'Hebrew',
  'bn': 'Bengali', 'ta': 'Tamil', 'te': 'Telugu', 'mr': 'Marathi',
  'gu': 'Gujarati', 'kn': 'Kannada', 'ml': 'Malayalam', 'pa': 'Punjabi',
  'ur': 'Urdu', 'fa': 'Persian', 'ms': 'Malay', 'tl': 'Tagalog',
  'my': 'Burmese', 'km': 'Khmer', 'ne': 'Nepali', 'si': 'Sinhala',
  'ka': 'Georgian', 'hy': 'Armenian', 'az': 'Azerbaijani',
  'en-US': 'English (US)', 'en-GB': 'English (UK)',
  'pt-BR': 'Portuguese (Brazil)', 'pt-PT': 'Portuguese (Portugal)',
  'fr-FR': 'French (France)', 'fr-CA': 'French (Canada)',
  'es-ES': 'Spanish (Spain)', 'es-MX': 'Spanish (Mexico)',
  'de-DE': 'German (Germany)', 'zh-Hans': 'Chinese (Simplified)',
  'zh-Hant': 'Chinese (Traditional)',
};

String languageDisplayName(String code) {
  if (code == 'en-orig') return 'English (Original)';
  return _languageNames[code] ?? _languageNames[code.split('-').first] ?? code.toUpperCase();
}

class VideoInfo {
  final String title;
  final String uploader;
  final String thumbnailUrl;
  final int duration;
  final List<VideoFormat> formats;
  final String? description;
  final int? viewCount;
  final List<String> manualSubtitleLangs;
  final List<String> autoSubtitleLangs;

  const VideoInfo({
    required this.title,
    required this.uploader,
    required this.thumbnailUrl,
    required this.duration,
    this.formats = const [],
    this.description,
    this.viewCount,
    this.manualSubtitleLangs = const [],
    this.autoSubtitleLangs = const [],
  });

  List<String> get subtitleLangs =>
      {...manualSubtitleLangs, ...autoSubtitleLangs}.toList()..sort();

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    final rawFormats = (json['formats'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(VideoFormat.fromJson)
        .toList();

    List<String> nonEmptyKeys(Map<String, dynamic>? map) {
      if (map == null) return [];
      final result = <String>[];
      for (final entry in map.entries) {
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          result.add(entry.key);
        }
      }
      result.sort();
      return result;
    }

    final manualSubtitleLangs = nonEmptyKeys(
      json['subtitles'] as Map<String, dynamic>?,
    );

    final autoSubtitleLangs = nonEmptyKeys(
      json['automatic_captions'] as Map<String, dynamic>?,
    );

    return VideoInfo(
      title: json['title'] ?? '',
      uploader: json['uploader'] ?? json['channel'] ?? 'Unknown',
      thumbnailUrl: json['thumbnail'] ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      formats: buildFormatMenu(rawFormats),
      description: json['description'] as String?,
      viewCount: (json['view_count'] as num?)?.toInt(),
      manualSubtitleLangs: manualSubtitleLangs,
      autoSubtitleLangs: autoSubtitleLangs,
    );
  }
}
