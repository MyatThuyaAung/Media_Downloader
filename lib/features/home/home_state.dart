import '../../models/video_format.dart';
import '../../models/video_info.dart';
import '../../models/download_progress.dart';

// Sentinel to distinguish "not passed" from "explicitly set to null"
class _Undefined {
  const _Undefined();
}

const _undefined = _Undefined();

class HomeState {
  final String url;
  final VideoInfo? videoInfo;
  final bool isLoading;
  final String? error;
  final VideoFormat? selectedFormat;
  final bool isDownloading;
  final DownloadProgress? downloadProgress;
  final String? cookiesBrowser;

  const HomeState({
    this.url = '',
    this.videoInfo,
    this.isLoading = false,
    this.error,
    this.selectedFormat,
    this.isDownloading = false,
    this.downloadProgress,
    this.cookiesBrowser,
  });

  HomeState copyWith({
    String? url,
    VideoInfo? videoInfo,
    bool? isLoading,
    Object? error = _undefined,
    VideoFormat? selectedFormat,
    bool? isDownloading,
    Object? downloadProgress = _undefined,
    Object? cookiesBrowser = _undefined,
  }) {
    return HomeState(
      url: url ?? this.url,
      videoInfo: videoInfo ?? this.videoInfo,
      isLoading: isLoading ?? this.isLoading,
      error: error == _undefined ? this.error : (error as String?),
      selectedFormat: selectedFormat ?? this.selectedFormat,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress == _undefined
          ? this.downloadProgress
          : (downloadProgress as DownloadProgress?),
      cookiesBrowser: cookiesBrowser == _undefined
          ? this.cookiesBrowser
          : (cookiesBrowser as String?),
    );
  }
}