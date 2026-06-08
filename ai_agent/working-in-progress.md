Last updated: 2026-06-08 20:21:18 +06:30

# Work In Progress

## Status: Subtitle system overhaul + process hang fix

### Recently Done
- **CC checkbox replaced** with `DropdownButton<String>` in both `VideoDownloadTile` and `_UrlInputCard` — options: "None" (default), "English"
- **`subtitleLang` (`String?`)** replaces `downloadSubtitles` (`bool`) across entire app: models, services, providers, UI
- **Process hang fix** in `download_service.dart`:
  - Process execution wrapped in `try/finally` — ensures controller always closes, subscriptions always cancel
  - Stream subscriptions stored and cancelled in `finally` block
  - `_processes.remove(taskId)` moved to `finally` — no more leaked process references
- **Previous fixes**: format selection now works, sentinel bug in SettingsState fixed, HomeNotifier settings sync via `ref.listen`, shared AppSidebar widget, lint cleanup
- `flutter analyze` — **0 issues found**
