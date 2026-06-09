import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/video_format.dart';
import '../../models/video_info.dart';
import '../../core/services/yt_dlp_service.dart';
import '../downloads/download_queue_provider.dart';
import '../settings/settings_provider.dart';
import 'home_state.dart';

final _ytDlpService = YtDlpService();

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

    state = state.copyWith(isLoading: true, error: null);

    try {
      final info = await _ytDlpService.fetchVideoInfo(
        state.url.trim(),
        cookiesBrowser: state.cookiesBrowser,
      );

      state = state.copyWith(
        isLoading: false,
        videoInfo: info,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Download ─────────────────────────────────────────────────────────────

  void startDownload({
    required VideoInfo video,
    required VideoFormat format,
    required String? subtitleLang,
  }) {
    final outputDirectory = _ref.read(settingsProvider).outputDirectory;
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

  void cancelDownload() {
    _ref.read(downloadQueueProvider.notifier).cancelActive();
  }

}
