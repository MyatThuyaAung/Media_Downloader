Last updated: 2026-06-04 21:44:14 +06:30

# Project Rules

## Architecture (HARD)
- UI never calls yt-dlp or ffmpeg directly
- UI only interacts with Riverpod providers
- Riverpod providers call Services
- Services call Process executables
- Models are pure data (no logic, no imports of Flutter/Riverpod)

## Code Style
- Use StateNotifier (not Notifier/AsyncNotifier) for all providers — project standard
- All state classes must have copyWith
- No direct Process.run/start calls outside of core/services/
- Platform detection belongs in a utility or service, never in UI
- Keep features self-contained: feature/xxx/ holds page + provider + state

## File Placement
- New services → lib/core/services/
- New models → lib/models/
- New shared widgets → lib/widgets/
- Feature-scoped widgets stay inside the feature folder
- Process helpers → lib/core/process/
- Constants → lib/core/constants/
- Utilities → lib/core/utils/

## Naming
- Files: snake_case
- Classes: PascalCase
- Providers: camelCase suffix `Provider` (e.g. homeProvider, downloadQueueProvider)
- State classes: PascalCase suffix `State`
- Notifiers: PascalCase suffix `Notifier`

## Flutter/Dart
- Flutter SDK managed via FVM
- Min window size: 1000×700
- Use Material3 throughout
- No hardcoded colors — use theme tokens
- Prefer const constructors everywhere possible

## Git
- Never commit without showing diff to human first
- Never git push under any circumstances
