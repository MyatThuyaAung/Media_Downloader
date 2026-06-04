import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/video_format.dart';
import '../../models/download_progress.dart';
import '../../core/services/yt_dlp_service.dart';
import '../../core/services/download_service.dart';
import 'home_state.dart';

final _ytDlpService = YtDlpService();
final _downloadService = DownloadService();

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (ref) => HomeNotifier(),
);

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState());

  StreamSubscription<DownloadProgress>? _downloadSub;

  // ── URL ──────────────────────────────────────────────────────────────────

  void updateUrl(String value) {
    // Changing URL resets previous results but preserves cookiesBrowser
    state = HomeState(
      url: value,
      cookiesBrowser: state.cookiesBrowser,
    );
  }

  // ── Cookies Browser ──────────────────────────────────────────────────────

  void updateCookiesBrowser(String? value) {
    state = state.copyWith(cookiesBrowser: value);
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

      // Pre-select the best video format if available
      final defaultFormat = info.formats.isNotEmpty ? info.formats.first : null;

      state = state.copyWith(
        isLoading: false,
        videoInfo: info,
        selectedFormat: defaultFormat,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Format selection ─────────────────────────────────────────────────────

  void selectFormat(VideoFormat format) {
    state = state.copyWith(selectedFormat: format);
  }

  // ── Download ─────────────────────────────────────────────────────────────

  Future<void> startDownload() async {
    final info = state.videoInfo;
    final format = state.selectedFormat;

    if (info == null || format == null) return;
    if (state.isDownloading) return;

    state = state.copyWith(
      isDownloading: true,
      downloadProgress: const DownloadProgress(percent: 0),
      error: null,
    );

    try {
      // Resolve output directory (user's Downloads folder)
      final downloadsDir = await getDownloadsDirectory();
      final outputDir = downloadsDir?.path ?? '.';

      // Sanitise title for use as filename
      final safeTitle = info.title
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();

      final outputPath = '$outputDir/$safeTitle.%(ext)s';

      final stream = _downloadService.download(
        url: state.url.trim(),
        formatId: format.formatId,
        outputPath: outputPath,
        cookiesBrowser: state.cookiesBrowser,
      );

      _downloadSub = stream.listen(
        (progress) {
          if (mounted) {
            state = state.copyWith(downloadProgress: progress);
            if (progress.isDone) {
              state = state.copyWith(
                isDownloading: false,
                downloadProgress: null,
              );
            }
          }
        },
        onError: (Object e) {
          if (mounted) {
            state = state.copyWith(
              isDownloading: false,
              downloadProgress: null,
              error: e.toString(),
            );
          }
        },
        onDone: () {
          if (mounted && state.isDownloading) {
            state = state.copyWith(
              isDownloading: false,
              downloadProgress: null,
            );
          }
        },
      );
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        downloadProgress: null,
        error: e.toString(),
      );
    }
  }

  void cancelDownload() {
    _downloadSub?.cancel();
    _downloadSub = null;
    _downloadService.cancel();
    state = state.copyWith(isDownloading: false, downloadProgress: null);
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }
}
