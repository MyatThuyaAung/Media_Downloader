Last updated: 2026-06-04 22:33:00 +06:30

# Project State

## Overview
Flutter Desktop media downloader (Windows primary, Linux later).
Minimum window: 1000×700. State: **Riverpod**. Routing: **go_router**. Bundled tools: yt-dlp (assets/binaries/).

## Architecture
```
Flutter UI → Riverpod → Services → Process (yt-dlp) → JSON/Stdout → Models → UI
```

## Current Structure
```
lib/
  app/        app.dart, router.dart
  core/
    services/ yt_dlp_service.dart   ← executable extraction, fetchVideoInfo() (UTF-8 + cookies support)
              download_service.dart ← streaming download with progress parsing (UTF-8 + cookies support)
    utils/     platform_utils.dart   ← platform-aware binary names and asset paths
  features/
    home/     home_page.dart, home_provider.dart, home_state.dart
    downloads/ (empty scaffold)
    history/   (empty scaffold)
    settings/  (empty scaffold)
  models/     video_info.dart, video_format.dart, download_progress.dart
  widgets/    video_info_card.dart
  main.dart
```

## Key Dependencies (pubspec.yaml)
- flutter_riverpod: ^2.6.1
- go_router: ^16.3.0
- path_provider: ^2.1.5
- window_manager: ^0.5.1
- file_picker: ^10.2.0
- uuid: ^4.5.1

## What Works
- App boots, window manager sets 1000×700 centered window
- Riverpod state management via `homeProvider`
- YtDlpService: extracts platform-aware yt-dlp binary, fetches metadata (forced UTF-8 decoding, optional cookies extraction)
- DownloadService: downloads video/audio tracks and streams progress (percent, speed, ETA, cookies support)
- VideoInfo & VideoFormat: parsed formats list, deduplicated by resolution
- DownloadProgress: parses yt-dlp stdout in real-time
- Polished dark UI with sidebar, URL input card, format dropdown, expanding Advanced Options for cookie-based authentication (bypassing bot detection), and animated progress bar

## Known Issues / Gaps (M2+ scope)
- Queue system (multiple concurrent or sequential downloads) not implemented yet
- History persistence not implemented yet
- Settings screen (custom output folder, default format) not implemented yet
