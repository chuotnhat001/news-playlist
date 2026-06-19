# Requirements: News Playlist MVP

## Core Requirements

### R1: Article Crawling
- App crawl listing pages tu Dan Tri va Soha
- Extract article URLs tu listing page
- Parse article pages de lay audio URLs
- Rate limiting: max 10 articles/batch, delay 500ms giua requests
- Chay trong background Dart Isolate (khong block UI)

### R2: Local Cache
- SQLite database luu articles (title, source, audioUrl, category, publishedAt, cachedAt)
- Cache TTL: 6 gio
- Auto-refresh khi data stale va user mo chuyen muc
- Pull-to-refresh manual

### R3: Playlist & Categories
- Home screen hien thi danh sach chuyen muc (Cong nghe, Kinh doanh, Chung khoan)
- Playlist screen hien thi bai moi nhat theo chuyen muc
- Play All button bat dau phat tu bai dau tien

### R4: Audio Playback
- Background playback (tiep tuc phat khi app bi minimize/lock screen)
- Lock screen controls (play/pause, skip next/previous)
- Media notification voi controls
- Auto-next: tu dong chuyen bai khi het
- Skip bai loi va play bai tiep

### R5: Player UI
- Mini player (bottom bar) hien thi tren moi screen
- Full player screen voi progress bar, controls
- Play/pause, skip next, skip previous
- Progress bar (seekable)

### R6: Error Handling
- Retry khi audio URL fail
- Toast notification khi skip bai loi
- Empty state khi chuyen muc khong co bai audio
- Graceful handling khi mat mang (pause + retry)

## Non-functional Requirements

### N1: Performance
- UI khong bao gio bi jank (crawl chay trong Isolate)
- Audio buffer truoc 30s
- SQLite reads < 10ms

### N2: Compatibility
- iOS 14+ va Android 8+
- Flutter 3.x

### N3: Distribution
- Android APK + Google Play
- iOS TestFlight + App Store
- Shorebird OTA cho Dart code updates

## Out of Scope (MVP)
- Backend server
- User accounts / authentication
- AI / personalization
- TTS (text-to-speech)
- Search
- Offline download
- Social features
- Push notifications
- Multiple languages
