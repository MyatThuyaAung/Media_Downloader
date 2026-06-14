Last updated: 2026-06-14 21:30:00 +06:30

# Work In Progress

## Status: Session Wrap-Up

### Session Completed (2026-06-14)
- Fixed pause bug (onError/onDone check paused status)
- Fixed progress size instability (reset at stream transitions, direct assignment)
- Fixed sidebar badges on History & Settings pages
- Fixed progress display (emit _mainSizeLabel not raw sizeLabel)
- Fixed window jiggling (progress throttle + manual center())
- Deno auto-download bundled for JS runtime (resume fix)
- All fixes tested with real downloads — working

### Next
- Linux Support (M4)
- Or any new features/improvements you'd like

### Files changed (uncommitted)
- `lib/app/app.dart` — init screen, app restructuring
- `lib/core/services/download_service.dart` — size labels, JS runtime args
- `lib/core/services/yt_dlp_service.dart` — JS runtime args
- `lib/core/utils/binary_manager.dart` — Deno download
- `lib/core/utils/platform_utils.dart` — Deno platform info
- `lib/features/downloads/download_queue_provider.dart` — pause fix, progress throttle
- `lib/features/history/history_page.dart` — badge count
- `lib/features/home/home_page.dart` — init integration
- `lib/features/home/home_provider.dart` — updates
- `lib/features/home/home_state.dart` — updates
- `lib/features/settings/settings_page.dart` — badge count
- `lib/features/init/` — init screen (new)
- `lib/models/playlist_info.dart` — playlist model (new)
- `lib/main.dart` — center() fix
- `pubspec.lock` — deps update

### Uncommitted new files
- `lib/features/init/init_screen.dart`
- `lib/features/init/init_provider.dart`
- `lib/models/playlist_info.dart`
