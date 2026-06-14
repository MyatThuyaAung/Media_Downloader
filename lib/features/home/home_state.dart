import '../../models/playlist_info.dart';
import '../../models/video_info.dart';

// Sentinel to distinguish "not passed" from "explicitly set to null"
class _Undefined {
  const _Undefined();
}

const _undefined = _Undefined();

class HomeState {
  final String url;
  final VideoInfo? videoInfo;
  final PlaylistInfo? playlistInfo;
  final bool isLoading;
  final String? error;
  final String? cookiesBrowser;
  final String? subtitleLang;

  const HomeState({
    this.url = '',
    this.videoInfo,
    this.playlistInfo,
    this.isLoading = false,
    this.error,
    this.cookiesBrowser,
    this.subtitleLang,
  });

  bool get isPlaylist => playlistInfo != null;

  HomeState copyWith({
    String? url,
    Object? videoInfo = _undefined,
    Object? playlistInfo = _undefined,
    bool? isLoading,
    Object? error = _undefined,
    Object? cookiesBrowser = _undefined,
    Object? subtitleLang = _undefined,
  }) {
    return HomeState(
      url: url ?? this.url,
      videoInfo: videoInfo == _undefined
          ? this.videoInfo
          : (videoInfo as VideoInfo?),
      playlistInfo: playlistInfo == _undefined
          ? this.playlistInfo
          : (playlistInfo as PlaylistInfo?),
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