<div align="center">

# Media Downloader

A modern cross-platform media downloader powered by Flutter, yt-dlp, and FFmpeg.

[Features](#features) •
[Installation](#installation) •
[Tech Stack](#tech-stack)

</div>

---

## Overview

Media Downloader is a desktop application for downloading videos, audio, and subtitles from supported platforms through a clean Material 3 dark interface. Built with Flutter and powered by yt-dlp and FFmpeg with automatic binary management.

## Features

- **Video downloads** with format selection (quality, codec, container)
- **Subtitle downloads** with embedding support
- **Multi-stream weighted progress** — smooth 0→60→85→100% across video, audio, and subtitle phases
- **Download queue** with sequential processing and concurrent post-processing (muxing)
- **Pause/Resume** support for queued and active downloads
- **Download history** with persistent storage
- **Live settings** — download directory changes take effect immediately (no restart)
- **Auto binary management** — 4-tier fallback for yt-dlp (cached → system → asset → GitHub) with background auto-update, plus FFmpeg resolution
- **File suffix collision** — automatically appends `_1`, `_2`, etc. when a file already exists
- **Open folder** button on completed downloads
- **Clipboard paste** button on URL input with clear (X) button
- **Material 3 dark theme** with bundled Inter variable font (no external font dependency)
- Cookies-based authentication from browser profiles
- Windows primary support (Linux/macOS compatible)

## Planned

- Playlist downloads
- macOS binary bundling

## Installation

### Requirements

- Flutter SDK (stable channel)
- Windows, Linux, or macOS

### Quick Start

```bash
flutter pub get
flutter run -d windows
```

### Build

```bash
flutter build windows --release
```

The app bundles yt-dlp and FFmpeg automatically — no manual installation required.

## Tech Stack

- **Framework**: Flutter (desktop)
- **State Management**: Riverpod (`StateNotifierProvider`)
- **Routing**: go_router
- **Fonts**: Inter Variable (bundled TTF)
- **Download Engine**: yt-dlp + FFmpeg
- **Process**: Dart `dart:io` Process

## Architecture

```
UI (Flutter Widgets)
  → Riverpod Providers (StateNotifier)
    → Service Layer (DownloadService, YtDlpService, SettingsService)
      → BinaryManager (yt-dlp/ffmpeg resolution)
        → dart:io Process
```

Key design decisions:
- UI never calls yt-dlp or FFmpeg directly — all process interaction is through services
- BinaryManager provides a single point of resolution with 4-tier fallback + auto-update
- Per-task state is encapsulated in `DownloadTask` models with progress tracking
- Settings are persisted as JSON and cached via a singleton service with eager pre-loading
- Weighted progress formula prevents backward jumps at stream transitions

## License

MIT
