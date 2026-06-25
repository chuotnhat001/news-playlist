# News Playlist

Vietnamese news audio playlist app built with Flutter. Crawls TTS audio from Soha.vn, creates continuous playlists for listening while driving.

## Tech Stack
- Flutter 3.x (Dart)
- Riverpod (state management)
- just_audio + audio_service (background playback)
- SQLite/sqflite (local cache, 6h TTL)
- dio + html (HTTP + HTML parsing in Dart Isolates)

## Architecture
- Client-only (no backend)
- Feature-first folder structure: lib/features/, lib/services/, lib/providers/, lib/models/
- Single AudioPlayerProvider for global playback state
- CrawlerService runs HTML parsing in Dart Isolates (compute())

## Commands
- `flutter test` — run all tests
- `flutter analyze` — lint check
- `flutter build apk --release` — build Android release
- `flutter build ios --release --no-codesign` — build iOS

## Conventions
- Vietnamese UI text, English code/comments
- Material 3 theme with dark gradient background
- Riverpod StateNotifier pattern for state management

## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Author a backlog-ready spec/issue → invoke /spec
