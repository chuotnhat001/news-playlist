# Design Review — News Playlist

## Review Context
- Date: 2026-06-23
- Reviewer: /plan-design-review
- Initial Score: 5/10
- UI Scope: 4 screens (Home, Playlist, Player full, Mini player) + Settings

---

## Pass 1: Information Architecture (6/10 → 9/10)

### Visual Hierarchy per Screen

**Home Screen:**
1. FIRST: "Tiếp tục nghe" card (if resume session exists) — primary action, 1-tap play
2. SECOND: Category list — browse & select
3. THIRD: Mini player (if audio active) — passive awareness

**Playlist Screen:**
1. FIRST: Play All button — primary action, prominent
2. SECOND: Article list — content to browse
3. THIRD: Mini player — persistent bottom

**Full Player Screen:**
1. FIRST: Track info (title + source) — what's playing
2. SECOND: Controls (play/pause/skip) — interaction
3. THIRD: Progress bar — awareness of position

**Settings Screen:**
1. FIRST: "Thêm danh mục" input/button — primary action
2. SECOND: Existing categories list — manage

### Navigation Flow
```
App Launch
  └─ Home Screen
       ├─ [tap "Tiếp tục nghe"] → Resume playback immediately
       ├─ [tap category card] → Playlist Screen
       │     ├─ [tap article] → playFromIndex
       │     ├─ [tap Play All] → start full playlist
       │     └─ [pull down] → refresh articles
       ├─ [swipe left / long-press] → Reload / Delete actions
       └─ [tap gear icon] → Settings Screen
             └─ [add/remove URLs] → return to Home

Mini Player (persistent bottom, all screens)
  └─ [tap] → Full Player Screen
       ├─ [seek] → jump position
       ├─ [prev/next] → skip tracks
       └─ [back] → return to previous screen
```

---

## Pass 2: Interaction State Coverage (7/10 → 9/10)

### State Table

| Feature | Loading | Empty | Error | Success | Partial |
|---------|---------|-------|-------|---------|---------|
| Home (categories) | Centered cyan spinner | "Chưa có danh mục" + add button + RSS icon | Retry toast | Category card list | Some cards show count, others "Chưa tải" |
| Playlist (articles) | Grey placeholder boxes (5 items) | EmptyState: article icon + "Không có bài viết" + refresh button | Toast + EmptyState with error icon | Article list with Play All | N/A |
| Mini Player | Hidden when idle | Hidden (SizedBox.shrink) | Shows last valid track, no error display | Track title + source + play/pause + progress | Buffering: progress bar animates pulse |
| Full Player | N/A (opened from mini player) | "No track selected" + back | Toast on playback error | Full controls + progress + track info | **Buffering: circular indicator overlay on play button** |
| Settings | Spinner while saving | "Chưa có danh mục" + input field | Toast on invalid URL | Category added, return to list | N/A |
| Resume card | Shimmer placeholder | Hidden (no prior session) | Hidden (corrupted data → clear) | "Tiếp tục nghe: [title]" card | N/A |

### Buffering Spec (Driving Context)
- When audio is buffering: play button shows circular progress indicator (replaces play icon)
- Mini player: linear progress bar pulses (indeterminate animation)
- No text change needed — visual feedback only (driver shouldn't read text)
- After 10s buffer without progress: show toast "Kết nối chậm, đang thử lại..."

---

## Pass 3: User Journey & Emotional Arc (4/10 → 8/10)

### Driving-Context UX Specs

**Resume Session:**
- On app close: save `lastPlaylist` (category ID, article list) + `lastPosition` (article index, seek position) to SQLite
- On app open: if `lastPlaylist` exists and < 24h old → show "Tiếp tục nghe" card at top of Home
- Card content: "▶ Tiếp tục: [article title]" with source and progress indicator
- 1 tap → resume playback at exact position. Maximum 1 interaction to continue listening.

**Quick-Start Flow:**
```
Open app (has prior session):
  → See "Tiếp tục nghe" card immediately (no loading required, data from cache)
  → 1 tap → audio resumes
  Total: 1 tap, <1 second to audio

Open app (no prior session):
  → See category list
  → Tap category → see articles (target: <2s load)
  → Tap Play All
  Total: 3 taps, <3 seconds to audio
```

**Loading Time Budget:**
- Category list: instant (from cache/SQLite)
- Article fetch: target <2s (show loading after 500ms, articles from cache if available while refreshing in background)
- Audio start: target <3s (just_audio buffering)

---

## Pass 4: AI Slop Risk (7/10 → 8/10)

### Assessment: APP UI type — PASS (no hard rejections)

**Actions taken:**
- Swipe-to-reveal: KEEP but add long-press as alternative (driving-safe, doesn't require precision)
- Motion spec: Add entry/exit transitions for screen navigation (MaterialPageRoute default is OK for MVP)
- Cards: JUSTIFIED — each card IS the interaction (navigate to playlist)

### Long-press Alternative Spec
- Long-press on CategoryCard (500ms) → show bottom sheet with actions: "Tải lại", "Xóa"
- Bottom sheet has large touch targets (56px height per action)
- Swipe remains as power-user shortcut
- Both trigger same onReload/onDelete callbacks

---

## Pass 5: Design System (3/10 → 7/10)

### Design Tokens (to be documented in DESIGN.md)

**Colors:**
- `--bg-gradient-start`: #0D0D2B
- `--bg-gradient-mid1`: #1A1A4E
- `--bg-gradient-mid2`: #0A2647
- `--bg-gradient-end`: #144272
- `--accent-primary`: #00DCFF (cyan)
- `--accent-secondary`: #7C3AED (purple, progress gradient only)
- `--surface-card`: #FFFFFF
- `--text-primary`: #FFFFFF (on dark bg), #1A1A1A (on cards)
- `--text-secondary`: rgba(255,255,255,0.7) on dark, #888 on cards
- `--success`: #10B981 (green dot)
- `--error`: Material colorScheme.error

**Typography:**
- Font: System default (Flutter MaterialApp default)
- Scale: Material 3 TextTheme (headlineSmall, titleMedium, bodyMedium, bodySmall)

**Spacing:**
- Base unit: 4px
- Common: 8, 12, 16, 24, 32
- Screen padding: 16px
- Card gap: 8px (vertical list)

**Border Radius:**
- Cards: 12px
- Buttons: 24px (rounded pill for primary CTAs)
- Mini player icon: 10px

**Touch Targets (Driving-safe):**
- Primary actions (Play All, Tiếp tục nghe): 56px height minimum
- Player controls: 64px (play/pause), 48px (skip)
- Category cards: full-width tap area, 76px height minimum
- Settings actions in bottom sheet: 56px height

**Elevation:**
- Cards: 2 (default), 4 (hover/pressed)
- Mini player: surface + top shadow

---

## Pass 6: Responsive & Accessibility (2/10 → 7/10)

### Orientation
- **Lock to portrait** for MVP (driving context = phone mounted vertically in most car mounts)
- Set in AndroidManifest.xml: `android:screenOrientation="portrait"`
- Set in iOS Info.plist: only portrait orientations

### Touch Targets (Driving-Safe)
- All tappable elements: minimum 56px height (exceeds Material 48px guideline)
- Play/pause in full player: 64px
- Category cards: full-width, 76px height
- Mini player: full-width, 72px height tap area

### Screen Reader Semantics
- CategoryCard: `Semantics(label: "Danh mục [name], [count] bài viết, nhấn để mở")`
- MiniPlayer: `Semantics(label: "Đang phát: [title], nhấn để mở trình phát")`
- Play/Pause buttons: `Semantics(label: isPlaying ? "Tạm dừng" : "Phát")`
- Skip buttons: `Semantics(label: "Bài trước" / "Bài kế tiếp")`

### Font Scaling
- Support Dynamic Type up to 1.5x without layout breaks
- Test: increase system font → verify no overflow/clip on card titles

### Contrast
- Cyan (#00DCFF) on dark (#0D0D2B): ratio ~11:1 ✅
- White on dark: ~18:1 ✅
- Dark text (#1A1A1A) on white cards: ~17:1 ✅

---

## Pass 7: Unresolved Design Decisions

### Resolved (this review):
1. ✅ Resume session → SQLite persistence, "Tiếp tục nghe" card
2. ✅ Quick-start → 1-tap resume, 3-tap new session
3. ✅ Landscape → Lock portrait for MVP
4. ✅ Font → System default (not Inter)
5. ✅ Touch targets → 56px minimum (driving-safe)
6. ✅ Long-press → Alternative to swipe for category actions
7. ✅ Buffering → Visual indicator on play button + progress pulse

### Deferred (post-MVP):
- Landscape support
- CarPlay / Android Auto integration
- Voice control
- Dark/Light theme toggle (dark-only for MVP)
- Inter font integration
- Tablet layout

---

## NOT in scope
- CarPlay/Android Auto — requires separate UI framework, post-MVP
- Landscape layout — locked portrait for driving mount simplicity
- Dark/Light toggle — dark-only matches audio app conventions
- Full WCAG 2.1 AA compliance — personal tool, driving-safe targets sufficient
- Inter font — system default acceptable for mobile MVP

## What already exists
- Dark gradient theme implemented in code
- CategoryCard with swipe-to-reveal (functional)
- MiniPlayer with progress bar and play/pause
- Full PlayerScreen with controls
- EmptyState shared widget
- Error toast function
- Mockup HTML (`mockup/app-preview.html`) as visual reference

---

## Implementation Tasks

Synthesized from this review's findings. Each task derives from a specific finding above.

- [ ] **T1 (P1, human: ~3h / CC: ~20min)** — Resume Session — Add SQLite persistence for last playlist + position, show "Tiếp tục nghe" card on Home
  - Surfaced by: Pass 3 — no session persistence, 3+ taps to start listening
  - Files: `lib/services/cache_service.dart`, `lib/features/home/home_screen.dart`, `lib/providers/audio_player_provider.dart`
  - Verify: Close app while playing → reopen → see resume card → tap → audio resumes at same position

- [ ] **T2 (P2, human: ~1h / CC: ~10min)** — Buffering Indicator — Add visual feedback when audio is buffering
  - Surfaced by: Pass 2 — no buffering state spec, driver doesn't know if app is working
  - Files: `lib/features/player/mini_player.dart`, `lib/features/player/widgets/player_controls.dart`
  - Verify: Throttle network → see pulsing progress + spinner on play button

- [ ] **T3 (P2, human: ~30min / CC: ~5min)** — Long-press Alternative — Add long-press bottom sheet for category actions
  - Surfaced by: Pass 4 — swipe requires precision, unsafe while driving
  - Files: `lib/features/home/widgets/category_card.dart`
  - Verify: Long-press category → bottom sheet with Reload/Delete options

- [ ] **T4 (P2, human: ~30min / CC: ~5min)** — Lock Portrait — Set portrait-only orientation
  - Surfaced by: Pass 6 — undefined landscape behavior
  - Files: `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`
  - Verify: Rotate device → app stays portrait

- [ ] **T5 (P2, human: ~1h / CC: ~10min)** — Touch Target Sizing — Increase touch targets to 56px+ for driving context
  - Surfaced by: Pass 6 — 48px targets too small for one-hand driving use
  - Files: `lib/features/home/widgets/category_card.dart`, `lib/features/player/widgets/player_controls.dart`
  - Verify: Visual inspection — all primary targets ≥56px

- [ ] **T6 (P3, human: ~1h / CC: ~10min)** — Semantics Labels — Add screen reader annotations
  - Surfaced by: Pass 6 — no accessibility semantics
  - Files: `lib/features/home/widgets/category_card.dart`, `lib/features/player/mini_player.dart`, `lib/features/player/widgets/player_controls.dart`
  - Verify: Enable TalkBack/VoiceOver → navigate app → hear meaningful descriptions

- [ ] **T7 (P3, human: ~2h / CC: ~15min)** — Create DESIGN.md — Document design tokens from this review
  - Surfaced by: Pass 5 — no design system document exists
  - Files: `DESIGN.md` (new)
  - Verify: File exists with colors, typography, spacing, components documented

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 0 | — | — |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | ISSUES_OPEN | score: 5/10 → 8/10, 7 decisions |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

**VERDICT:** DESIGN CLEARED — 7 design decisions resolved, 6 deferred to post-MVP. Eng review required before implementation.

**UNRESOLVED DECISIONS:**
- Buffering indicator exact animation style (pulse vs indeterminate linear)
- Settings screen detailed UX flow (input validation, URL format help)
