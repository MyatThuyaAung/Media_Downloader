# Media Downloader

A desktop application for downloading videos, audio, subtitles, and playlists from the web. Built with Flutter, powered by `yt-dlp` and `FFmpeg`.

## Screenshots

<p align="center">
  <img src="screenshots/home.png" alt="Home Screen" width="600"/>
</p>

## Features

- **Format Selection:** Choose your preferred video quality, resolution, and codec from available formats.
- **Subtitles:** Download subtitles alongside your video in MKV container.
- **Queue Management:** Queue multiple downloads with pause, resume, cancel, and sequential processing.
- **Multi-Stream Progress:** Real-time progress tracking with phase labels (Downloading, Merging, Remuxing).
- **Parallel Post-Processing:** Next download starts immediately while the current one finishes muxing.
- **Automatic Dependencies:** Automatically extracts and caches `yt-dlp`, `FFmpeg`, and `Deno` (JS runtime) — no manual system installation required.
- **Browser Cookies:** Import cookies from your browser to access private playlists, age-restricted, or authentication-gated content.
- **History & Persistence:** Completed downloads and queue state are saved across app restarts.
- **Customizable Output Directory:** Choose where downloaded files are saved.
- **Cross-Platform:** Windows and Linux support.

## Authentication & Cookies

To download private playlists or age-restricted content, this application can securely read your active browser session cookies. This allows the downloader to inherit your existing authentication status without requiring you to log in directly within the application.

### How to use it:

1. **Select Browser:** In the "Advanced Options" menu, click the Cookies Source dropdown.
2. **Select Active Session:** Choose the browser (e.g., Firefox, Chrome) where you are currently logged into the platform (YouTube, etc.).
3. **Fetch Info:** Click the "Fetch Info" button. The application will now use your session to authenticate the request.
4. **Verification:** Once authenticated, the UI will update to show the correct content (e.g., showing 7 videos instead of 0).

### Troubleshooting

- **0 Videos Found:** If you see "0 videos" even after pasting a URL, it usually means the application cannot access the playlist without authentication. Ensure you are logged into that browser and that you have selected the correct Cookies Source.
- **Private Playlists:** If you are trying to access a "Private" playlist that you created, you must select the browser session where that account is logged in.

## Installation

### Prerequisites

- Flutter SDK (stable)
- Windows or Linux

### Run

```bash
flutter pub get
flutter run
```

### Build

```bash
# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

> **Note:** `yt-dlp`, `FFmpeg`, and `Deno` (JS runtime) are extracted and cached automatically on the first run. No manual system installation is required.

## Known Issues

- **Screen jitter on minimize/restore:** On some Windows configurations, the window may briefly jitter when minimizing and restoring. This is a known `window_manager` platform issue and does not affect functionality.
- **yt-dlp exit code -1:** Some videos (particularly from certain regions) may fail with exit code -1 (process crash). This typically indicates a YouTube rate-limiting or blocking issue rather than a bug in the application.

## Tech Stack

- **Frontend:** Flutter (Material 3, Dark Theme)
- **State & Routing:** Riverpod + `go_router`
- **Core Engine:** `yt-dlp` + `FFmpeg` via `dart:io`
- **JavaScript Runtime:** Deno (auto-downloaded for yt-dlp JS execution)

## License

MIT
