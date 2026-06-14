import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/video_format.dart';
import '../../models/video_info.dart';
import '../../core/services/yt_dlp_service.dart';
import '../downloads/download_queue_provider.dart';
import 'home_state.dart';

final _playlistUrlPattern = RegExp(r'(?:list=|/playlist/|/set/|/album/)', caseSensitive: false);
final _mixIdPattern = RegExp(r'^RD', caseSensitive: false);

final _ytDlpService = YtDlpService();

String? _extractListId(String url) {
  try {
    return Uri.parse(url).queryParameters['list'];
  } catch (_) {
    return null;
  }
}

bool _isMixUrl(String url) {
  final listId = _extractListId(url);
  return listId != null && _mixIdPattern.hasMatch(listId);
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(ref),
);

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier(this._ref) : super(const HomeState());

  final Ref _ref;

  // ── URL ──────────────────────────────────────────────────────────────────

  void updateUrl(String value) {
    state = state.copyWith(url: value);
  }

  // ── Cookies Browser ──────────────────────────────────────────────────────

  void updateCookiesBrowser(String? value) {
    state = state.copyWith(cookiesBrowser: value);
  }

  // ── Subtitle Language ───────────────────────────────────────────────────

  void updateSubtitleLang(String? value) {
    state = state.copyWith(subtitleLang: value);
  }

  // ── Metadata fetch ────────────────────────────────────────────────────────

  Future<void> fetchVideoInfo() async {
    if (state.url.trim().isEmpty) return;

    state = state.copyWith(isLoading: true, error: null, videoInfo: null, playlistInfo: null);

    try {
      final trimmed = state.url.trim();

      // Mix URLs (list=RD...) are auto-generated, not user-curated playlists.
      // Treat them as single-video downloads.
      final isNonMixPlaylist = _playlistUrlPattern.hasMatch(trimmed) && !_isMixUrl(trimmed);

      if (isNonMixPlaylist) {
        final playlist = await _ytDlpService.fetchPlaylistInfo(
          trimmed,
          cookiesBrowser: state.cookiesBrowser,
        );

        state = state.copyWith(
          isLoading: false,
          playlistInfo: playlist,
          error: null,
        );
      } else {
        final info = await _ytDlpService.fetchVideoInfo(
          trimmed,
          cookiesBrowser: state.cookiesBrowser,
        );

        state = state.copyWith(
          isLoading: false,
          videoInfo: info,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Download ─────────────────────────────────────────────────────────────

  void startDownload({
    required VideoInfo video,
    required VideoFormat format,
    required String? subtitleLang,
    String? outputDirectory,
  }) {
    _ref.read(downloadQueueProvider.notifier).addTask(
          url: state.url.trim(),
          title: video.title,
          thumbnailUrl: video.thumbnailUrl,
          uploader: video.uploader,
          format: format,
          cookiesBrowser: state.cookiesBrowser,
          subtitleLang: subtitleLang,
          outputDirectory: outputDirectory,
          duration: video.duration,
          viewCount: video.viewCount,
        );
  }

}
