import 'video_format.dart';
import 'download_progress.dart';

enum DownloadTaskStatus { queued, downloading, paused, done, error }

class DownloadTask {
  final String id;
  final String url;
  final String title;
  final String? thumbnailUrl;
  final String? uploader;
  final VideoFormat format;
  final DownloadTaskStatus status;
  final DownloadProgress? progress;
  final String? errorMessage;
  final String? cookiesBrowser;
  final String? outputPath;
  final String? subtitleLang;
  final DateTime createdAt;
  final DateTime? completedAt;

  const DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    this.thumbnailUrl,
    this.uploader,
    required this.format,
    this.status = DownloadTaskStatus.queued,
    this.progress,
    this.errorMessage,
    this.cookiesBrowser,
    this.outputPath,
    this.subtitleLang,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'uploader': uploader,
        'format': format.toJson(),
        'status': status.name,
        'errorMessage': errorMessage,
        'cookiesBrowser': cookiesBrowser,
        'outputPath': outputPath,
        'subtitleLang': subtitleLang,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
        id: json['id'] as String,
        url: json['url'] as String,
        title: json['title'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        uploader: json['uploader'] as String?,
        format: VideoFormat.fromJson(json['format'] as Map<String, dynamic>),
        status: DownloadTaskStatus.values.byName(json['status'] as String),
        errorMessage: json['errorMessage'] as String?,
        cookiesBrowser: json['cookiesBrowser'] as String?,
        outputPath: json['outputPath'] as String?,
        subtitleLang: json['subtitleLang'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );

  DownloadTask copyWith({
    String? id,
    String? url,
    String? title,
    String? thumbnailUrl,
    String? uploader,
    VideoFormat? format,
    DownloadTaskStatus? status,
    Object? progress = _undefined,
    Object? errorMessage = _undefined,
    String? cookiesBrowser,
    Object? outputPath = _undefined,
    Object? subtitleLang = _undefined,
    DateTime? createdAt,
    Object? completedAt = _undefined,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      uploader: uploader ?? this.uploader,
      format: format ?? this.format,
      status: status ?? this.status,
      progress:
          progress == _undefined ? this.progress : (progress as DownloadProgress?),
      errorMessage: errorMessage == _undefined
          ? this.errorMessage
          : (errorMessage as String?),
      cookiesBrowser: cookiesBrowser ?? this.cookiesBrowser,
      outputPath: outputPath == _undefined
          ? this.outputPath
          : (outputPath as String?),
      subtitleLang: subtitleLang == _undefined
          ? this.subtitleLang
          : (subtitleLang as String?),
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt == _undefined
          ? this.completedAt
          : (completedAt as DateTime?),
    );
  }
}

class _Undefined {
  const _Undefined();
}

const _undefined = _Undefined();
