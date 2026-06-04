Last updated: 2026-06-04 21:44:14 +06:30

# Roadmap

## Vision
A polished Flutter Desktop media downloader for Windows (later Linux) that rivals commercial tools.
Modern UI, robust queue, format selection, real-time progress tracking.

## Milestones

### ✅ M0 — Project Bootstrap (DONE)
- Flutter project + Riverpod + go_router
- YtDlpService with asset extraction
- VideoInfo model + basic card UI
- window_manager setup

### 🔥 M1 — Core Feature Integration (CURRENT)
Goal: Working end-to-end download with format selection and real progress.

1. Fix HomeState copyWith bug (error not preserved)
2. Platform-aware executable path (Windows/Linux)
3. Format extraction (`yt-dlp -J` → formats array)
4. Format selection UI (dropdown/list)
5. Download service (yt-dlp -f FORMAT -o OUTPUT URL)
6. Progress tracking (parse stdout → progress bar)
7. UI polish: dark theme, network thumbnail, remove debug text

### 🔲 M2 — Queue System
- DownloadQueue model (list of DownloadTask)
- downloadQueueProvider (Riverpod list state)
- Add/remove/reorder tasks
- Status: queued → downloading → done/error
- Queue screen (downloads feature)

### 🔲 M3 — History & Settings
- Persist completed downloads (local storage)
- History screen
- Settings screen: default output folder, default format

### 🔲 M4 — Linux Support
- Platform detection utility
- Linux binary bundling
- CI build

## Priorities
Always: reliability > features > polish
