# Project State

## Current Phase
Phase 4: Public Launch (Post-MVP)

## Current Status
READY_TO_START

## Completed Phases
- Phase 0: Spike & Validation (2026-06-20)
- Phase 1: Project Foundation (2026-06-20)
- Phase 2: UI & User Experience (2026-06-20)
- Phase 3: Polish & Ship (2026-06-20)

## Post-Phase Fixes Applied
- Fix critical initialization: ensureInitialized, ContentService.init, AudioHandler wiring
- Dart Isolate for HTML parsing (compute()) — no UI jank
- audio_service integration for lock screen controls + media notification
- SohaCrawler updated to parse embedTTS.init() JS block
- Audio retry logic (1x retry before skip)
- Dio timeout (30s connect, 60s receive)
- AppShell: MaterialApp.builder for persistent MiniPlayer across all routes
- ArticleTile onTap → playFromIndex()
- Widget tests expanded: 55 → 65 tests

## Decisions Log
| Date | Decision | Context |
|------|----------|---------|
| 2026-06-20 | Flutter (not React Native, not PWA) | Best native experience for driving use case |
| 2026-06-20 | Client-only (no backend) | Simplify ops, solo dev |
| 2026-06-20 | SQLite local cache, TTL 6h | Balance freshness vs network load |
| 2026-06-20 | Background Dart Isolate for crawl | Keep UI smooth |
| 2026-06-20 | Riverpod single provider | Simple for MVP, refactor later |
| 2026-06-20 | Feature-first folder structure | Scales better |
| 2026-06-20 | Soha primary source, Dan Tri deferred | Dan Tri has no native audio; Soha has TTS CDN |
| 2026-06-20 | SohaCrawler extracts from embedTTS.init() JS | Spike confirmed URL pattern |
| 2026-06-20 | GitHub Actions for CI/CD | Standard, free for public repos |
| 2026-06-20 | ProGuard + minify for release APK | Smaller APK, obfuscated code |
| 2026-06-20 | MaterialApp.builder for AppShell | MiniPlayer persists across all routes |

## Blockers
- [x] Spike: crawl feasibility — DONE (Soha feasible, Dan Tri no audio)
- [x] Critical initialization — FIXED (c2a44ee, 1a29c21)
- [x] Lock screen controls — FIXED (d4c573a)
- [ ] Legal: ToS review for Soha (robots.txt allows all, but formal review pending)
- [ ] App icon PNG files needed (1024x1024)
- [ ] Firebase project setup (google-services.json)
- [ ] Keystore generation for release signing
- [ ] Shorebird account init

## Test Status
- 65 tests passing
- Zero flutter analyze issues
- Coverage: models, services, providers, home screen, player, playlist

## Git History
- c2a44ee feat: fix navigation, add playFromIndex, add widget tests
- 1a29c21 fix: critical initialization, isolate parsing, retry logic, cleanup
- d4c573a fix: integrate audio_service for lock screen controls, fix Soha test fixture
- fad0bed feat: Phase 3 — CI/CD, release config, app metadata, analytics
- d39a09d feat: implement Phase 0-2 — spike validation, foundation, and UI

## Session Continuity
Last session: 2026-06-20
Stopped at: All code-level work complete. Next: manual setup (icon, keystore, Firebase) then Phase 4 (store submission)
Resume file: none
