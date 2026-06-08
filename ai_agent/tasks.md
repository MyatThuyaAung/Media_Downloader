Last updated: 2026-06-08 00:09:04 +06:30

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

## Completed — M2 (Queue System)
- [x] DownloadTask model (id, url, title, format, status, progress, errorMessage, cookiesBrowser, outputPath, timestamps)
- [x] DownloadQueueState + DownloadQueueNotifier (sequential processing, pause, resume, pauseAll, resumeAll, cancel, remove, clearCompleted)
- [x] Queue screen (downloads_page.dart) — status icons, progress bars, per-task Pause/Resume/Cancel/Dismiss, global Pause All / Resume All
- [x] Smart queue: pausing a download auto-starts next queued task
- [x] Resume via yt-dlp `--continue` flag (kill + restart with partial file)
- [x] Home page integration: "Add to Queue" button, removed direct download handling
- [x] Sidebar navigation: go_router routes with FadeTransition (200ms) between `/` and `/downloads`, badge count on queue icon
- [x] Build passes (Windows debug) ✅

## Completed — M2.5 (Phase-aware Progress + Multi-process Architecture)
- [x] DownloadProgress.phase field + tryParsePhase() static parser detecting `[Merger]`, `[ffmpeg]`, `[VideoConvertor]`, `[Metadata]`, resume detection
- [x] Multi-process DownloadService: `Map<String, Process>` keyed by taskId; `cancel(taskId)` per process
- [x] Decoupled queue: `_networkTaskId` (one network download) + `_processingTaskIds` (concurrent muxing). Next task starts when current hits 100% while muxing continues in background
- [x] Phase status label with spinner on Downloads page; "Starting/Resuming download..." immediate feedback
- [x] `_onDownloadComplete` keeps percent=100 during muxing so progress bar stays full
- [x] Fixed `value` → `initialValue` + `ValueKey` for `DropdownButtonFormField` deprecation
- [x] Removed unused import, unnecessary `dispose()` override
- [x] Updated stale test stub; `flutter analyze` clean (0 errors, 0 warnings) ✅

## Completed — M2.6 (Bug Fixes, FFmpeg Pathing, Subtitles, UX Polish)
- [x] FFmpeg extraction from assets + `--ffmpeg-location` arg passed to yt-dlp
- [x] Format override to `bestvideo[height<=?1080]+bestaudio/best` for guaranteed audio
- [x] `--merge-output-format mkv` for native subtitle storage
- [x] Subtitle flags: `--write-subs`, `--sub-langs "en"` (single English, no embed)
- [x] Fixed `_TaskTile` layout jiggling by wrapping in `SizedBox(height: 150)`
- [x] Renamed "Add to Queue" → "Download" button with download icon
- [x] Instant SnackBar feedback ("Added to download queue!") on button press
- [x] `flutter analyze` clean (0 errors, 0 warnings) + build passes ✅

## Completed — M2.7 (Layout Overflow, Multi-pass Progress, Badge, Loop Fix)
- [x] Fixed `_TaskTile` RenderFlex overflow (4px): SizedBox 150→160, removed tight SizedBox(2), mainAxisSize: min on inner Column
- [x] Multi-pass progress detection: `_highestPercent` map tracks max percent per task; when secondary stream starts (audio/subs), progress bar stays pinned at 100 with "Downloading additional streams..." phase
- [x] Infinite loop fix: `_processNext()` now double-checks task isn't already tracked in `_processingTaskIds` or `_services` before starting
- [x] Flutter `Badge` widget on both sidebars replacing custom Positioned/Container badge; shows `activeCount` (non-done tasks); >9 displays "9+"; hidden when 0
- [x] `_highestPercent` cleaned up on finish, fail, cancel, remove
- [x] `flutter analyze` clean (0 errors, 0 warnings) + build passes ✅

## Completed — M2.8 (Current/Total Size, Subtitle Phase Fix)
- [x] Added `currentSizeLabel` field to `DownloadProgress` — parsed from yt-dlp's `of X` by computing `percent * total / 100`
- [x] Added `_parseSize` / `_formatSize` helpers for size string parsing and formatted display
- [x] Fixed `of ~ X` size regex to handle unknown-size prefix
- [x] UI now shows `"12.68 MiB / 28.00 MiB"` format instead of just total size
- [x] Added subtitle-specific phase detection: `"Downloading subtitles..."` / `"Writing subtitles..."` instead of generic `"Initializing..."`
- [x] Multi-pass handler passes `currentSizeLabel` through to the pinned progress
- [x] `flutter analyze` clean (0 errors, 0 warnings) + build passes ✅

## Completed — M3 (History & Settings)
- [x] History persistence — JSON file in app support directory (HistoryService)
- [x] History page with completed downloads list, remove, clear all
- [x] Settings page with output directory picker (file_picker), default subtitles toggle
- [x] Settings persistence — JSON file (SettingsService + SettingsNotifier)
- [x] Queue state persistence — queued/paused tasks saved on change, restored on startup
- [x] History auto-save on task completion (DownloadQueueNotifier → historyProvider)
- [x] Settings integration into HomeNotifier (default subtitles, output directory)
- [x] /history and /settings routes in go_router with fade transitions
- [x] Sidebar icons wired across all pages (home, downloads, history, settings)
- [x] VideoFormat.toJson(), DownloadTask.toJson()/fromJson() for serialization
- [x] `flutter analyze` clean (0 errors, 0 warnings) + build passes ✅

## Completed — Bug Fixes (2026-06-08)
- [x] Removed `--embed-subs` from `download_service.dart` (confirmed cause of yt-dlp hang during MKV remux)
- [x] Removed `--remux-video mkv` from `download_service.dart` (redundant with `--merge-output-format mkv`)

## Planned — M4 (Linux)
- [ ] Linux binary bundling
- [ ] Platform detection utilities
