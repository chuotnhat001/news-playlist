# Project State

## Current Phase
Phase 3: Polish & Ship

## Current Status
COMPLETED

## Completed Phases
- Phase 0: Spike & Validation (2026-06-20)
- Phase 1: Project Foundation (2026-06-20)
- Phase 2: UI & User Experience (2026-06-20)
- Phase 3: Polish & Ship (2026-06-20)

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

## Blockers
- [x] Spike: crawl feasibility — DONE (Soha feasible, Dan Tri no audio)
- [ ] Legal: ToS review for Soha (robots.txt allows all, but formal review pending)
- [ ] App icon PNG files needed (1024x1024)
- [ ] Firebase project setup (google-services.json)
- [ ] Keystore generation for release signing
- [ ] Shorebird account init

## Notes
- Spike results: .planning/spike-results.md
- 55 tests passing, zero analyze issues
- Full UI flow: Home → Playlist → Player (mini + full)
- CI/CD: .github/workflows/ci.yml
- Release signing: android/key.properties.example (template)
- Icon/splash configs ready — need PNG assets

## Session Continuity
Last session: 2026-06-20
Stopped at: Phase 3 code complete. Remaining items are manual/external (icon design, Firebase console, keystore, Shorebird account)
Resume file: none
