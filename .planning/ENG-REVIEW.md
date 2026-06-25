# Engineering Review — News Playlist

## Review Context
- Date: 2026-06-23
- Reviewer: /plan-eng-review
- Branch: master
- Scope: Full codebase (Phase 0-3 implementation + design review tasks)

---

## Step 0: Scope Challenge

- Codebase: 7 service/provider files, 4 feature directories — within complexity budget
- Architecture: Client-only, Riverpod StateNotifier, SQLite cache, Dart Isolate parsing
- Distribution: GitHub Actions + Codemagic configured ✅
- No complexity check triggered

---

## Section 1: Architecture Review

### System Design Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (Client-only)              │
├─────────────────────────────────────────────────────────┤
│  UI Layer                                                │
│  HomeScreen → PlaylistScreen → PlayerScreen + MiniPlayer │
│  + SettingsScreen (new, untracked)                       │
├─────────────────────────────────────────────────────────┤
│  State Layer (Riverpod)                                  │
│  contentServiceProvider (singleton)                      │
│  audioPlayerProvider (StateNotifier)                     │
├─────────────────────────────────────────────────────────┤
│  Service Layer                                           │
│  ContentService ← CacheService(SQLite) + CrawlerService │
│  AudioPlayerService(just_audio) + AudioHandler(null!)    │
├─────────────────────────────────────────────────────────┤
│  External: soha.vn CDN (TTS audio), soha.vn (HTML)      │
└─────────────────────────────────────────────────────────┘
```

### Findings

| # | Severity | Confidence | File:Line | Issue | Resolution |
|---|----------|-----------|-----------|-------|------------|
| D1 | P2 | 9/10 | cache_service.dart:12 | No double-init guard on CacheService.init() | Add `_initialized` flag |
| D2 | P2 | 8/10 | crawler_service.dart:55-76 | Sequential crawl = 5-10s blocking when cache stale | Implement stale-while-revalidate |
| D3 | P1 | 9/10 | audio_player_provider.dart:229-231 | audioHandlerProvider always returns null — lock screen controls broken | Implement NewsAudioHandler |

---

## Section 2: Code Quality Review

| # | Severity | Confidence | File:Line | Issue | Resolution |
|---|----------|-----------|-----------|-------|------------|
| D4 | P3 | 7/10 | content_service.dart:53-91 | 4 methods with identical stale→crawl→fallback pattern | Extract `_fetchWithFallback()` |

---

## Section 3: Test Review

### Coverage Diagram

```
CODE PATHS                                              STATUS
[+] cache_service.dart
  ├── init/insert/query/stale/clear                     [★★★ TESTED]
  └── categories CRUD                                   [GAP]

[+] crawler_service.dart
  ├── crawlCategory happy + error                       [★★★ TESTED]
  └── partial failure (some URLs fail)                  [GAP]

[+] content_service.dart
  ├── getArticles (cache fresh + stale)                 [★★★ TESTED]
  ├── getArticlesFromUrl                                [GAP]
  └── refreshUrl                                        [GAP]

[+] audio_player_provider.dart
  ├── setPlaylist/skipNext/skipPrevious/error            [★★  TESTED]
  └── seekTo, pause/resume lifecycle                    [GAP]

[+] features/home/                                      [★★  TESTED]
  └── custom categories reload/delete/empty             [GAP]

[+] features/player/                                    [★★  TESTED]
  └── buffering state, seekTo interaction               [GAP]

[+] features/settings/                                  [GAP] entirely untested

COVERAGE: ~65% paths | GAPS: 8 significant
TARGET: 85%+ after fixes
```

### Test Tasks

1. Settings screen widget test
2. CacheService categories CRUD test
3. ContentService.getArticlesFromUrl + refreshUrl tests
4. AudioPlayerProvider seekTo/pause lifecycle test
5. Resume session persistence test (when implemented)

---

## Section 4: Performance Review

No additional issues beyond D2 (sequential crawl bottleneck).
- SQLite reads: <10ms (indexed queries) ✅
- HTML parsing: off-main-thread (Dart Isolate) ✅
- Audio buffering: handled by just_audio internally ✅
- Memory: lightweight models, max 10 articles per fetch ✅

---

## Implementation Tasks (from this review)

- [ ] **T1 (P1, human: ~3h / CC: ~20min)** — AudioHandler — Implement NewsAudioHandler for lock screen controls
  - Surfaced by: Section 1 D3 — audioHandlerProvider returns null
  - Files: `lib/services/audio_player_service.dart`, `lib/providers/audio_player_provider.dart`, `lib/main.dart`
  - Verify: Play audio → lock screen → media notification visible → pause/skip from notification works

- [ ] **T2 (P2, human: ~2h / CC: ~15min)** — Stale-while-revalidate — Show cached data immediately, crawl in background
  - Surfaced by: Section 1 D2 — 5-10s blocking crawl
  - Files: `lib/services/content_service.dart`, `lib/providers/content_provider.dart`
  - Verify: Cache expired → open playlist → see old articles immediately → new articles appear after refresh

- [ ] **T3 (P2, human: ~20min / CC: ~3min)** — Init guard — Add double-init protection to CacheService
  - Surfaced by: Section 1 D1 — retry could double-open database
  - Files: `lib/services/cache_service.dart`
  - Verify: Call init() twice → no error, second call is no-op

- [ ] **T4 (P3, human: ~1h / CC: ~5min)** — DRY ContentService — Extract common fetch pattern
  - Surfaced by: Section 2 D4 — 4 methods with same pattern
  - Files: `lib/services/content_service.dart`
  - Verify: All 4 public methods delegate to single private method, tests pass

- [ ] **T5 (P2, human: ~4h / CC: ~25min)** — Test gaps — Write tests for all 8 coverage gaps
  - Surfaced by: Section 3 — 65% coverage, 8 gaps
  - Files: `test/services/`, `test/features/settings/`, `test/providers/`
  - Verify: `flutter test` passes, new tests cover categories CRUD, settings screen, getArticlesFromUrl

---

## NOT in scope
- Backend/API layer (client-only architecture by design)
- Dan Tri crawler (deferred — no native audio)
- CarPlay/Android Auto integration (post-MVP)
- End-to-end tests (unit + widget tests sufficient for MVP)

## What already exists
- 65 passing tests with good service/provider coverage
- GitHub Actions CI with test + build
- Codemagic iOS TestFlight pipeline
- Dart Isolate parsing (no UI jank)
- SQLite cache with 6h TTL

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | ISSUES_OPEN | 5 issues (1 P1, 2 P2, 1 P3, 8 test gaps) |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | ISSUES_OPEN | score: 5/10 → 8/10, 7 decisions |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**VERDICT:** ENG REVIEW COMPLETED — 1 P1 issue (AudioHandler), 2 P2 issues, 1 P3 issue, 8 test gaps identified. All approved for implementation.

**UNRESOLVED DECISIONS:**
- Stale-while-revalidate exact UX: show loading indicator while background refresh? Or silent refresh?
