# Roadmap: News Playlist MVP

## Phase 0: Spike & Validation (Pre-development)
**Goal:** Confirm technical feasibility before writing production code.
**Duration:** 1 day

### Tasks:
1. Inspect 10 articles on Dan Tri — find audio URL pattern
2. Inspect 10 articles on Soha — find audio URL pattern
3. Test audio URL accessibility (hotlink protection? CORS?)
4. Read ToS of Dan Tri and Soha regarding scraping
5. Document findings in spike-results.md

### Exit criteria:
- Audio URLs can be extracted and streamed
- No legal blockers identified (or fallback plan documented)

---

## Phase 1: Project Foundation
**Goal:** Flutter project setup with core infrastructure (crawl + cache + audio engine).
**Duration:** ~1 week

### Tasks:
1. Flutter project init (flutter create)
2. Add dependencies: riverpod, dio, html, sqflite, just_audio, audio_service
3. Feature-first folder structure setup
4. Article model (data class + SQLite schema)
5. CacheService: SQLite CRUD + TTL logic
6. CrawlerService: HTTP + HTML parse in Isolate
7. Crawl Dan Tri listing page + article pages
8. Crawl Soha listing page + article pages
9. AudioService: just_audio + audio_service wrapper
10. AudioPlayerProvider (Riverpod): global state

### Exit criteria:
- Can crawl articles from Dan Tri and Soha
- Articles cached in SQLite with TTL
- Audio plays in background with lock screen controls
- All core services have unit tests

---

## Phase 2: UI & User Experience
**Goal:** Complete UI cho 3 screens (Home, Playlist, Player).
**Duration:** ~1 week

### Tasks:
1. Home screen: category grid/list
2. Playlist screen: article list with Play All
3. Mini player (persistent bottom bar)
4. Full player screen (artwork, progress, controls)
5. Auto-next logic
6. Skip-on-error logic
7. Empty states (no articles, no audio)
8. Pull-to-refresh
9. Loading states
10. Error toasts

### Exit criteria:
- User can open app → choose category → tap Play → listen continuously
- Background playback works with lock screen controls
- Errors handled gracefully (skip, retry, toast)

---

## Phase 3: Polish & Ship
**Goal:** Prepare for beta distribution.
**Duration:** ~1 week

### Tasks:
1. App icon and splash screen
2. App name and metadata
3. Firebase Analytics setup
4. Build APK (release mode)
5. iOS build + TestFlight setup
6. GitHub Actions CI/CD
7. Shorebird setup
8. Beta testing with 10+ users
9. Collect feedback
10. Bug fixes from beta

### Exit criteria:
- APK distributed to 10+ beta testers
- iOS TestFlight available
- Firebase Analytics tracking usage
- No P0/P1 bugs

---

## Phase 4: Public Launch (Post-MVP)
**Goal:** Publish to app stores.
**Duration:** ~1 week

### Tasks:
1. App Store screenshots and description
2. Google Play listing
3. Submit to Apple App Store review
4. Submit to Google Play
5. Monitor analytics and retention
6. Iterate based on Week 4-8 retention data

### Exit criteria:
- App live on both stores
- Retention data available for go/no-go decision

---

## Success Metrics (from Design Doc)
- **Week 4:** 10+ beta users
- **Week 6:** iOS TestFlight + Google Play internal
- **Week 8:** 3+ users returning >=3x/week
- **Fail signal:** After 8 weeks, no one returns except founder → pivot or kill
