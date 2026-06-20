# News Playlist

Flutter mobile app nghe playlist tin tức tự động khi lái xe. App crawl audio từ báo Việt Nam (Soha.vn), tạo playlist theo chuyên mục, phát liên tục với background playback.

## Features

- Crawl audio (TTS) từ Soha.vn theo chuyên mục
- Playlist tự động phát liên tục
- Background playback với lock screen controls
- Mini player persistent trên mọi screen
- Full player với progress bar, skip, seek
- SQLite cache (TTL 6h) cho offline experience
- Pull-to-refresh

## Tech Stack

- Flutter 3.x (Dart)
- Riverpod (state management)
- just_audio + audio_service (background playback)
- SQLite/sqflite (local cache)
- dio + html (HTTP + HTML parsing)
- GitHub Actions (CI/CD)

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Run tests
flutter test

# Analyze
flutter analyze

# Build release APK
flutter build apk --release
```

## Project Structure

```
lib/
├── main.dart                  # App entry with async initialization
├── app_shell.dart             # Shell with persistent mini player
├── models/
│   └── article.dart           # Article data model
├── services/
│   ├── audio_player_service.dart   # just_audio + audio_service wrapper
│   ├── cache_service.dart          # SQLite CRUD + TTL
│   ├── content_service.dart        # Crawl orchestrator
│   ├── crawler_service.dart        # HTTP + Isolate parsing
│   ├── analytics_service.dart      # Event tracking
│   └── crawlers/
│       ├── dantri_crawler.dart     # Dan Tri parser (deferred)
│       └── soha_crawler.dart       # Soha.vn TTS parser
├── providers/
│   ├── audio_player_provider.dart  # Playback state management
│   └── content_provider.dart       # Content + category providers
├── features/
│   ├── home/                       # Category grid screen
│   ├── playlist/                   # Article list + Play All
│   └── player/                     # Mini player + full player
└── shared/
    └── widgets/                    # EmptyState, error toast
```

## Release Setup

1. Generate keystore: `keytool -genkey -v -keystore android/keystore/news-playlist.jks -keyalg RSA -keysize 2048 -validity 10000 -alias news-playlist`
2. Copy `android/key.properties.example` to `android/key.properties` and fill in values
3. Place app icon at `assets/icon/app_icon.png` (1024x1024)
4. Run `dart run flutter_launcher_icons`
5. Run `dart run flutter_native_splash:create`
6. Build: `flutter build apk --release`

## Architecture

Client-only — app crawls audio URLs directly from Soha.vn TTS CDN, caches in SQLite, plays via just_audio with audio_service for background/notification controls. HTML parsing runs in Dart Isolates to prevent UI jank.
