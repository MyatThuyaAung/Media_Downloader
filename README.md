# Media Downloader

A minimal desktop app for downloading videos, audio, and subtitles. Built with Flutter, powered by `yt-dlp` and `FFmpeg`.

## Features

- **Format Selection:** Choose your preferred video quality, codec, and container.
- **Subtitles:** Download and embed subtitles directly into the video.
- **Queue Management:** Queue multiple links with pause, resume, and concurrent post-processing.
- **Automatic Dependencies:** Automatically fetches, caches, and updates `yt-dlp` and `FFmpeg` in the background.
- **Browser Cookies:** Import cookies from your browser to download private or age-restricted content.

## Installation

### Prerequisites
- Flutter SDK (stable)
- Windows, or Linux

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

*Note: `yt-dlp` and `FFmpeg` are bundled automatically on the first run. No manual system installation is required.*

## Tech Stack

* **Frontend:** Flutter
* **State & Routing:** Riverpod + `go_router`
* **Core Engine:** `yt-dlp` + `FFmpeg` via `dart:io`

## License

MIT
