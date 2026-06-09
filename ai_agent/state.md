Last updated: 2026-06-08 00:09:04 +06:30

# Project State

## Overview
Flutter Desktop media downloader (Windows primary, Linux later).
Minimum window: 1000×700. State: **Riverpod**. Routing: **go_router**. Bundled tools: yt-dlp + ffmpeg (assets/binaries/).

## Architecture
```
Flutter UI → Riverpod → Services → Process (yt-dlp) → JSON/Stdout → Models → UI
```

### Queue Flow
```
User adds task → Queue (sequential) → Network download (0-100%)
                                          ↓ on 100%
                                    Post-processing (muxing) ← │
                                    Next task starts network    │
                                    (runs in parallel)          │
                                          ↓ on process exit     │
                                    Mark done, remove from set  │
```

- `_networkTaskId` tracks the single network-downloading task
- `_processingTaskIds` (Set) tracks tasks in post-processing (muxing)
- `_processNext()` only starts when `_networkTaskId` is null
- `DownloadService` holds `Map<String, Process>` — one per task
- Pause kills process + removes from both tracking sets

## Current Structure
```
lib/
  app/        app.dart, router.dart
  core/
    services/ yt_dlp_service.dart          ← executable extraction, fetchVideoInfo()
              download_service.dart         ← streaming download with progress parsing
              settings_service.dart         ← JSON file persistence for settings
              history_service.dart          ← JSON file persistence for download history
              queue_persistence_service.dart ← JSON file persistence for queued/paused tasks
    utils/     platform_utils.dart          ← platform-aware binary names and asset paths
  features/
    home/       home_page.dart, home_provider.dart, home_state.dart
    downloads/  downloads_page.dart, download_queue_provider.dart
    history/    history_page.dart, history_provider.dart, history_state.dart
    settings/   settings_page.dart, settings_provider.dart, settings_state.dart
  models/     video_info.dart, video_format.dart, download_progress.dart, download_task.dart
  widgets/    video_info_card.dart, video_download_tile.dart
  main.dart
```

## Key Dependencies (pubspec.yaml)
- flutter_riverpod: ^2.6.1
- go_router: ^16.3.0
- path_provider: ^2.1.5
- window_manager: ^0.5.1
- file_picker: ^10.2.0
- uuid: ^4.5.1

## Key M2.8 Changes
- **Current/Total size**: `DownloadProgress.currentSizeLabel` computed from `percent × totalBytes / 100` via `_parseSize`/`_formatSize` helpers. `_ProgressBar` displays `"12.68 MiB / 28.00 MiB"` instead of just `"28.00 MiB"`
- **Subtitle phase fix**: `tryParsePhase` now detects `"Downloading subtitles..."` (via `[info] Downloading subtitles`) and `"Writing subtitles..."` (via `[info] Writing video subtitles`) instead of lumping them under generic `"Initializing..."`, preventing the false "resetting to Initializing" appearance
- **Size regex fixed**: Handles `of ~ X` (unknown file size prefix) via `of\s+~?\s*` pattern

## Key M2.7 Changes
- **Layout fix**: `_TaskTile` SizedBox height increased to 160; inner Column uses `mainAxisSize: MainAxisSize.min` with `Padding(top:1)` instead of `SizedBox(2)`; Row uses `crossAxisAlignment: CrossAxisAlignment.center` — eliminates the 4px RenderFlex overflow
- **Multi-pass progress**: `_highestPercent` map tracks the highest percent per task. When yt-dlp starts downloading additional streams (audio/subs) after video hits 100%, the progress bar stays pinned at 100% and shows "Downloading additional streams..." phase text with live speed/ETA — no more backward jumps
- **Infinite loop guard**: `_processNext()` checks `_processingTaskIds.contains(task.id)` and `_services.containsKey(task.id)` before starting a task
- **`Badge` widget**: Both sidebars now use Flutter's built-in `Badge` with `activeCount` (tasks where status != done). Shows "9+" when count > 9, exact number otherwise, hidden at 0
- All tracking maps (`_highestPercent`, `_processingTaskIds`, `_services`) cleaned up consistently in finish/fail/cancel/remove

## Key M2.6 Changes
- **FFmpeg bundled + pathed**: ffmpeg.exe extracted from `assets/binaries/windows/` alongside yt-dlp; `--ffmpeg-location` explicitly passed to yt-dlp so muxing always finds FFmpeg
- **Format override**: Always uses `bestvideo[height<=?1080]+bestaudio/best` instead of user-selected format ID — guarantees audio in every download
- **MKV container**: `--merge-output-format mkv` for native subtitle storage; `--remux-video mkv` was removed as redundant
- **Fixed height task tiles**: `_TaskTile` wrapped in `SizedBox(height: 150)` to eliminate layout jiggling during phase/progress updates
- **Button text + SnackBar**: "Add to Queue" renamed to "Download"; pressing it shows a floating SnackBar "Added to download queue!" for instant feedback

## Key M2.5 Changes
- **phase field** on `DownloadProgress` — detected from yt-dlp stdout lines like `[Merger]`, `[ffmpeg]`, `[VideoConvertor]`, `[Metadata]`
- **Multi-process DownloadService**: `Map<String, Process>` instead of single `Process?`; each active task owns its own service instance
- **Decoupled queue logic**: network download and post-processing are tracked separately; next queued task starts immediately when current reaches 100%, while muxing continues in background
- **Phase label**: shown on Downloads page alongside the progress bar; e.g. "Merging Audio & Video..." spinner while ffmpeg runs
- **`flutter analyze` clean**: 0 errors, 0 warnings

## What Works
- App boots, window manager sets 1000×700 centered window
- Riverpod state management via `homeProvider` and `downloadQueueProvider`
- YtDlpService: extracts platform-aware yt-dlp binary, fetches metadata (forced UTF-8 decoding, optional cookies extraction)
- DownloadService: downloads video/audio tracks and streams progress (percent, speed, ETA, cookies support)
- VideoInfo & VideoFormat: parsed formats list, deduplicated by resolution
- DownloadProgress: parses yt-dlp stdout in real-time
- Polished dark UI with sidebar, URL input card, format dropdown, expanding Advanced Options for cookie-based authentication (bypassing bot detection)
- **Queue System (M2)**: sequential download queue with status tracking (queued → downloading → paused → done/error), cancel support, badge count on sidebar, dedicated Downloads page
- **Pause/Resume**: per-task pause (kills yt-dlp process, stores partial file) and resume (restarts with `--continue` flag). Smart queue: pausing one download auto-starts the next queued task.
- **Global Pause All / Resume All**: batch pauses all active + queued tasks, or resumes all paused tasks
- DownloadTask model with copyWith, shared between home page (add to queue) and downloads page (progress tracking)
- Sidebar navigation via go_router with **fade transition** (`FadeTransition`, 200ms) between `/` and `/downloads`

## Current Subtitle Approach (2026-06-08)
- **`--embed-subs` removed** (confirmed hang cause during MKV remux on large files)
- **`--remux-video mkv` removed** (redundant with `--merge-output-format mkv`)
- Subtitles download as separate `.vtt` alongside the MKV via `--write-subs --sub-langs "en"`
- Phase tracking correctly detects subtitle download and resets `_inSubtitlePhase` on `[Merger]`
- "Initializing..." phase-only updates skipped during post-processing
- `onDone` safety net marks task done if stream ends while in post-processing

## Key M3 Changes
- **History persistence**: Completed `DownloadTask` entries saved to JSON in app support directory via `HistoryService`; auto-loaded on startup
- **History page**: Full page with list of completed downloads (title, format, date), per-item remove, clear all with confirmation dialog
- **Settings persistence**: `SettingsService` saves/loads settings JSON; `SettingsNotifier` auto-initializes on creation
- **Settings page**: Output directory picker (via `file_picker`), default subtitles toggle — matches existing dark M3 UI
- **Queue state persistence**: `QueuePersistenceService` saves queued/paused tasks on every state change; restored on app restart
- **History auto-save**: `DownloadQueueNotifier._finishTask()` calls `historyProvider.notifier.addEntry()` on completion
- **Settings integration**: `HomeNotifier` reads `defaultSubtitles` from settings on init; passes `outputDirectory` to `addTask`
- **Router**: `/history` and `/settings` routes added with fade transitions; sidebar icons wired in all pages
- **Serialization**: `VideoFormat.toJson()` and `DownloadTask.toJson()/fromJson()` added for persistence
- `flutter analyze` clean (0 errors, 0 warnings) + build passes ✅

## Key M3.1 Changes
- **Queue tile thumbnails**: `_TaskTile` now shows 100×56 thumbnail with duration badge on left, status icon inline with uploader, action buttons compacted
- **History tile thumbnails**: `_HistoryTile` uses the same thumbnail layout
- **Clear All button**: Downloads `_TopBar` shows "Clear All" (error-colored) when any task is done/error, calls `clearAllExceptInProgress()`
- **`_ThumbPlaceholder`**: Shared private widget for thumbnail loading/error states (duplicated in both files)
- **`_formatDuration`**: HH:MM:SS or MM:SS formatting added to both tile widgets

## Key M3.2 Changes (Linux Support)
- **Linux binaries**: `assets/binaries/Linux/ffmpeg` (extracted from `.deb`) and `assets/binaries/Linux/yt-dlp`
- **pubspec.yaml**: registered `assets/binaries/linux/` for asset bundling
- **Zero Dart code changes**: `PlatformUtils` already had correct Linux paths (`assets/binaries/linux/yt-dlp`, `assets/binaries/linux/ffmpeg`, binary names without `.exe`); `YtDlpService` and `DownloadService` already had `chmod +x` for non-Windows
- **Linux runner**: standard Flutter-generated files in `linux/` — GTK3 app with `window_manager` and `screen_retriever` plugins registered

## Known Issues / Gaps
- Linux build requires a Linux host: `flutter build linux --release`
- No `.desktop` file yet for system-level app registration
- Task stuck at "Remuxing" 100% without CC needs testing after `--remux-video` removal
