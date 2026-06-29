---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: unknown
stopped_at: context exhaustion at 100% (2026-06-29)
last_updated: "2026-06-29T01:47:56.300Z"
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 8
  completed_plans: 0
  percent: 0
---

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
- Eng Review Implementation (2026-06-23)

## Post-Phase Fixes Applied

- Fix critical initialization: ensureInitialized, ContentService.init, AudioHandler wiring
- Dart Isolate for HTML parsing (compute()) — no UI jank
- audio_service integration for lock screen controls + media notification
- SohaCrawler updated to parse embedTTS.init() JS block
- Audio retry logic (1x retry before skip)
- Dio timeout (30s connect, 60s receive)
- AppShell: MaterialApp.builder for persistent MiniPlayer across all routes
- ArticleTile onTap → playFromIndex()
- Widget tests expanded: 55 → 65 → 109 tests

## Eng Review Tasks (2026-06-23)

- [x] AudioHandler wiring — lock screen controls now functional
- [x] Resume Session — SQLite persistence, "Tiep tuc nghe" card on Home
- [x] Stale-while-revalidate — cached data shown instantly, background crawl
- [x] Init guard — CacheService double-init protection
- [x] Buffering indicator — spinner on play button, indeterminate progress bar
- [x] Touch targets 56dp+ — all interactive elements meet driving threshold
- [x] DRY ContentService — _fetchWithFallback extracted
- [x] Semantics labels — tooltips + Semantics wrappers on key widgets
- [x] DESIGN.md — design tokens documented
- [x] Test gaps — categories CRUD, playback state, buffering UI, settings screen, audio lifecycle

## Review Fixes (2026-06-23)

- [x] P0: seekWhenReady — wait for audio source ready before seeking on resume
- [x] P0: Double-tap prevention — clear state immediately on resume tap
- [x] P1: Error state preservation — copyWith preserves error across updates
- [x] P1: playUrl error propagation — rethrow + catch in _playCurrentTrack
- [x] P2: Timer churn — skip schedule if timer already active
- [x] P3: StreamController dispose — ContentService.dispose() + ref.onDispose

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
| 2026-06-23 | Stale-while-revalidate + StreamController notify | Show cache instantly, refresh in background |
| 2026-06-23 | Save playback state via WidgetsBindingObserver | Survive OS kills |
| 2026-06-23 | seekWhenReady with Completer + timeout | Prevent seek before audio source ready |
| 2026-06-23 | Save article index (not ID) for resume | Simple for MVP, noted as P2 improvement |

## Blockers

- [x] Spike: crawl feasibility — DONE (Soha feasible, Dan Tri no audio)
- [x] Critical initialization — FIXED (c2a44ee, 1a29c21)
- [x] Lock screen controls — FIXED (e199c10)
- [ ] Legal: ToS review for Soha (robots.txt allows all, but formal review pending)
- [ ] App icon PNG files needed (1024x1024)
- [ ] Firebase project setup (google-services.json)
- [ ] Keystore generation for release signing
- [ ] Shorebird account init

## Test Status

- 109 tests passing
- Zero flutter analyze errors
- Coverage: models, services, providers, home screen, player, playlist, settings, audio lifecycle, buffering

## Git History

- e199c10 feat: implement 10 eng review tasks + gap fixes + review fixes
- 1471a72 fix: use FlutterFragmentActivity for audio_service compatibility
- 3a1def0 fix: resolve Gradle build errors (JVM target, shrinkResources)
- 376b43c feat: add Codemagic CI/CD config for iOS build + TestFlight
- 74abe74 feat: generate app icon, adaptive icon, and splash screen
- 87b1a21 chore: update STATE.md — reflect post-fix state and 65 tests
- c2a44ee feat: fix navigation, add playFromIndex, add widget tests
- 1a29c21 fix: critical initialization, isolate parsing, retry logic, cleanup
- d4c573a fix: integrate audio_service for lock screen controls, fix Soha test fixture
- fad0bed feat: Phase 3 — CI/CD, release config, app metadata, analytics
- d39a09d feat: implement Phase 0-2 — spike validation, foundation, and UI

## Session Continuity

Last session: 2026-06-29T01:47:56.293Z
Stopped at: context exhaustion at 100% (2026-06-29)
Resume file: None
