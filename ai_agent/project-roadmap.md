Last updated: 2026-06-12 21:00:00 +06:30

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

### ✅ M1 — Core Feature Integration (DONE)
- End-to-end download with format selection and real progress
- Dark Material3 UI with sidebar
- UTF-8 encoding + cookies auth

### ✅ M2 — Queue System (DONE)
- Sequential download queue with pause/resume
- Multi-process network + post-processing decoupling
- Phase-aware progress, multi-pass detection, badge
- Subtitle download (no embed) with correct phase tracking

### ✅ M3 — History & Settings (DONE)
- Persist completed downloads (local storage)
- History screen
- Settings screen: default output folder, default subtitles
- Queue state persistence across restarts

### 🔲 M4 — Linux Support
- Platform detection utility
- Linux binary bundling
- CI build

## Priorities
Always: reliability > features > polish
