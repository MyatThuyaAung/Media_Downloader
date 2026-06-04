Last updated: 2026-06-04 22:33:00 +06:30

# Tasks

## Completed
- [x] Flutter project scaffold
- [x] Riverpod + go_router integration
- [x] window_manager setup (1000×700)
- [x] YtDlpService: extract yt-dlp.exe from assets, run --dump-single-json
- [x] VideoInfo model (title, uploader, thumbnailUrl, duration)
- [x] HomeState + HomeNotifier + HomeProvider
- [x] HomePage: URL field + fetch button + loading/error/card display
- [x] VideoInfoCard widget (placeholder thumbnail)
- [x] Document project in ai_agent/ memory files
- [x] M1: Fix HomeState.copyWith sentinel bug
- [x] M1: platform_utils.dart (platform-aware binary paths)
- [x] M1: video_format.dart + buildFormatMenu() deduplication
- [x] M1: download_progress.dart + tryParse() from yt-dlp stdout
- [x] M1: video_info.dart extended with formats list, viewCount
- [x] M1: yt_dlp_service.dart — platform detection, chmod +x on Linux
- [x] M1: download_service.dart — streaming download, cancel()
- [x] M1: home_state.dart — selectedFormat, isDownloading, downloadProgress
- [x] M1: home_provider.dart — selectFormat, startDownload, cancelDownload
- [x] M1: home_page.dart — sidebar, format dropdown, progress bar, dark UI
- [x] M1: video_info_card.dart — Image.network thumbnail, meta chips, view count
- [x] M1: app.dart — dark ColorScheme, google_fonts Inter, global theme tokens
- [x] M1: UTF-8 encoding fixes (added --encoding utf-8 and allowMalformed: true to decoders)
- [x] M1: Cookies Source Integration (bypassed "Sign in to confirm you're not a bot" error using --cookies-from-browser)
- [x] M1: Build passes ✅ (debug Windows)


## Planned — M2 (Queue System)
- [ ] DownloadTask model
- [ ] DownloadQueue state + provider
- [ ] Queue screen (downloads feature)

## Planned — M3+
- [ ] History persistence
- [ ] Settings screen (output folder, default format)
- [ ] Linux binary + platform detection
