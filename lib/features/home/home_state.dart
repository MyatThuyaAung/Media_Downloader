import '../../models/video_info.dart';

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
  final String? cookiesBrowser;
  final String? subtitleLang;

  const HomeState({
    this.url = '',
    this.videoInfo,
    this.isLoading = false,
    this.error,
    this.cookiesBrowser,
    this.subtitleLang,
  });

  HomeState copyWith({
    String? url,
    VideoInfo? videoInfo,
    bool? isLoading,
    Object? error = _undefined,
    Object? cookiesBrowser = _undefined,
    Object? subtitleLang = _undefined,
  }) {
    return HomeState(
      url: url ?? this.url,
      videoInfo: videoInfo ?? this.videoInfo,
      isLoading: isLoading ?? this.isLoading,
      error: error == _undefined ? this.error : (error as String?),
      cookiesBrowser: cookiesBrowser == _undefined
          ? this.cookiesBrowser
          : (cookiesBrowser as String?),
      subtitleLang: subtitleLang == _undefined
          ? this.subtitleLang
          : (subtitleLang as String?),
    );
  }
}