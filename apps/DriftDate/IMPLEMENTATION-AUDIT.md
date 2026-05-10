# Drift — IMPLEMENTATION AUDIT

**Date:** 2026-05-08
**Scope:** Round-4 Phase-7a verification pass against `DRIFT-FEATURES.md`,
`README.md`, `DESIGN.md`, `SAFETY.md`.
**Method:** static read of source under `ios/`, `watchos/`, `android/`,
`shared/DriftCore/`, `backend/supabase/`. No code executed.

---

## Severity legend

| Tag | Meaning                                                                    |
|-----|----------------------------------------------------------------------------|
| P0  | Blocker — promised feature not present, or production-blocking placeholder |
| P1  | Significant — skeleton/stub gates a real promised flow                     |
| P2  | Functional gap — UI exists but action is a no-op / hard-coded value        |
| P3  | Cosmetic / test-only / acceptable per design                               |

---

## 1. Promised features → implementation citations

Citations use `path:line`. Primary location is listed; mirrored
implementations on the second platform are noted in the Notes column.

### 1.1 Discovery

| # | Promised feature                                  | Citation                                                                          | Status | Sev | Notes |
|---|---------------------------------------------------|-----------------------------------------------------------------------------------|--------|-----|-------|
| 1 | Layer selector Server/State/County/ZIP            | `ios/Drift/Features/Discover/DiscoverScreen.swift:13`                              | OK     | —   | Android mirror `android/app/src/main/java/com/americangroupllc/drift/discover/DiscoverScreen.kt:47` |
| 2 | Per-card layer chip ("same ZIP" / "same county")  | `ios/Drift/Features/Discover/ProfileCard.swift:16`                                 | OK     | —   | Android `discover/DiscoverScreen.kt:72` shows raw layer name only — partial |
| 3 | Per-layer pool sizes ("8 nearby on ZIP, 42 …")    | —                                                                                  | **GAP**| P1  | No counter UI in either `DiscoverScreen.swift` or `discover/DiscoverScreen.kt` |

### 1.2 Profile

| # | Promised feature                                  | Citation                                                                          | Status | Sev | Notes |
|---|---------------------------------------------------|-----------------------------------------------------------------------------------|--------|-----|-------|
| 4 | 6 photos, one tagged verification selfie          | `ios/Drift/Features/Profile/PhotoGridEditor.swift:10`; schema `backend/supabase/migrations/0001_init.sql:73` (unique `is_verification_selfie`) | OK | — | Android `profile/ProfileScreen.kt:23` is empty skeleton — **P1 GAP for Android** |
| 5 | Voice prompt 30 s clip (`AVAudioRecorder`)        | `ios/Drift/Features/Profile/VoicePromptRecorder.swift:14`                          | Partial| P1  | Skeleton — toggles `isRecording` only; no `AVAudioRecorder`, no upload. Android **GAP** |
| 6 | Intent badge (Dating / Serious / Friendship / Open)| `ios/Drift/Features/Discover/ProfileCard.swift:20`; `shared/DriftCore/Sources/DriftCore/Models/Enums.swift` | OK | — | Android shows raw text `discover/DiscoverScreen.kt:71` |
| 7 | Vibe tags (~30 fixed taxonomy)                    | `ios/Drift/Features/Discover/ProfileCard.swift:21`; schema `0001_init.sql:42` (constraint cardinality ≤5) | Partial | P2 | Fixed-taxonomy enforcement not present (free-text); Android UI **GAP** |
| 8 | Three Hinge-style structured prompts              | schema `backend/supabase/migrations/0001_init.sql:62`                              | **GAP**| P1  | No prompt editor in `ios/Drift/Features/Profile/EditProfileScreen.swift` and no Android UI |

### 1.3 Matching loop

| # | Promised feature                                  | Citation                                                                          | Status | Sev | Notes |
|---|---------------------------------------------------|-----------------------------------------------------------------------------------|--------|-----|-------|
| 9 | Wave / Pass tap actions                           | `ios/Drift/Features/Discover/WaveActions.swift:17` (Wave); `WaveActions.swift:11` (Pass — comment-only) | Partial | P2 | Pass is a no-op (`WaveActions.swift:28`); Android `discover/DiscoverScreen.kt:75` both no-op |
|10 | Like-a-prompt (server mode)                       | —                                                                                  | **GAP**| P1  | Mentioned `DRIFT-FEATURES.md:22`, marketing `index.html:67`; no UI / endpoint |
|11 | Mutual Wave → chat unlocks (verification-gated)   | `backend/supabase/functions/verify-selfie/index.ts:60` (sets `verified_at`); `backend/supabase/migrations/0003_rls_helpers.sql` (RLS) | Partial | P1 | Server-side present; client never checks `isVerified` to gate composer (`ios/Drift/Features/Chat/ChatScreen.swift:21` allows send unconditionally) |
|12 | No "super likes" paywall                          | (absence of feature, by design)                                                    | OK     | —   | No IAP code in repo |

### 1.4 Chat

| # | Promised feature                                  | Citation                                                                          | Status | Sev | Notes |
|---|---------------------------------------------------|-----------------------------------------------------------------------------------|--------|-----|-------|
|13 | Realtime via Supabase (Postgres LISTEN/NOTIFY)    | `backend/supabase/migrations/0002_realtime.sql:7` (`drift_realtime` publication)   | Partial | P1 | Server publication exists; client has only "Realtime subscription stub" — `ios/Drift/Services/ChatService.swift:4`. Android **GAP**. |
|14 | Three reply suggestions on every screen entry     | `ios/Drift/Features/Chat/ChatScreen.swift:30` → `ios/Drift/Services/ReplyService.swift:13`; `backend/supabase/functions/reply-suggest/index.ts:131` (LLM call) | OK | — | Android mirror `android/app/src/main/java/com/americangroupllc/drift/chat/ChatScreen.kt:38` (hard-coded sample, no service call — **P2**) |
|15 | Tone evolves (slow/energetic/deep/meetupReady)    | `shared/DriftCore/Sources/DriftCore/Domain/ToneClassifier.swift:20`                 | OK     | —   | Android mirror `android/core/src/main/java/com/americangroupllc/drift/core/domain/ToneClassifier.kt` |

### 1.5 Safety

| # | Promised feature                                  | Citation                                                                          | Status | Sev | Notes |
|---|---------------------------------------------------|-----------------------------------------------------------------------------------|--------|-----|-------|
|16 | Selfie verification (AWS Rekognition CompareFaces, threshold ≥90) | `backend/supabase/functions/verify-selfie/index.ts:54`; `verify-selfie/index.ts:19` (threshold 90); iOS `ios/Drift/Services/VerificationService.swift:26` | OK | — | iOS Storage upload stubbed (`VerificationService.swift:21`). Android **GAP** — no `VerificationService` |
|17 | Report on every profile + chat                    | `ios/Drift/Features/Safety/ReportSheet.swift:12`                                   | Partial | P1 | Submit button only fires analytics, no `INSERT` (`ReportSheet.swift:21`). Android **GAP** (string only `app/src/main/res/values/strings.xml:7`) |
|18 | Block on every profile + chat                     | `ios/Drift/Features/Safety/BlockedUsersScreen.swift:12` (Unblock stub)             | Partial | P1 | List view present; no Block action wired on cards / chat. Android **GAP** |
|19 | Mute per-conversation                             | schema `backend/supabase/migrations/0001_init.sql:126` (`muted_by_a/b`)            | **GAP**| P1  | No mute toggle in iOS `ChatScreen.swift` or Android `chat/ChatScreen.kt` |
|20 | Anonymous display name until mutual Wave + verification | schema `backend/supabase/migrations/0001_init.sql:39` (`legal_name` ops-only)       | Partial | P2 | Schema enforces ops-only `legal_name`; no client logic to reveal real name post-match — design implies clients always show `display_name`, treat as OK |
|21 | Location fuzzing (ZIP-3 / county-FIPS / state)    | `shared/DriftCore/Sources/DriftCore/Domain/LocationFuzzer.swift:24`; backend `backend/supabase/functions/fuzz-location/index.ts:46` | OK | — | iOS `LocationService.swift:36` admits ZIP-prefix lookup is a skeleton — emits empty fuzz **P1** |
|22 | Public-meetup framing                             | `shared/DriftCore/Sources/DriftCore/Domain/ToneClassifier.swift:14` (`meetupPatterns`); `shared/DriftCore/Sources/DriftCore/Domain/ReplyPromptBuilder.swift` | OK | — | |
|23 | Screenshot disclosure on iOS + Android            | —                                                                                  | **GAP**| P1  | No `UIScreen.userDidTakeScreenshotNotification` observer in iOS; no first-chat disclosure in Android. Promise in `SAFETY.md:74-83` and `DRIFT-FEATURES.md:42` |

### 1.6 Watch surfaces

| # | Promised feature                                  | Citation                                                                          | Status | Sev | Notes |
|---|---------------------------------------------------|-----------------------------------------------------------------------------------|--------|-----|-------|
|24 | Match notification complication ("Sara matched")  | `watchos/DriftWatchComplication/MatchesComplication.swift:17`; Android `android/wear/src/main/java/com/americangroupllc/driftwear/complication/QuickReplyComplicationService.kt:14` | Partial | P2 | iOS provider hard-codes `unread:0` (`MatchesComplication.swift:35,41`); Android complication hard-codes `"0"` (`QuickReplyComplicationService.kt:25`) |
|25 | Glanceable layer + unread match count             | `watchos/DriftWatchComplication/MatchesComplication.swift:50-65`                    | Partial | P2 | iOS UI present but data static; Android wear tile `tile/MatchTileService.kt:22` returns empty timeline entry — **P1 GAP** for layer indicator on Wear OS |
|26 | Wave-back tile — 1-tap accept on a pending Wave   | `watchos/DriftWatch/Views/QuickReplyView.swift:14` (button placeholder action)      | Partial | P2 | iOS button is no-op (`/* PATCH /rest/v1/waves */`). Android wear `tile/MatchTileService.kt` has no wave-back affordance — **P1 GAP** |

### 1.7 Settings

| # | Promised feature                                  | Citation                                                                          | Status | Sev | Notes |
|---|---------------------------------------------------|-----------------------------------------------------------------------------------|--------|-----|-------|
|27 | Layer toggles                                     | `ios/Drift/Features/Onboarding/OnboardingFlowView.swift:112`                       | Partial | P2 | Present only in onboarding; not editable from `SettingsScreen.swift`. Android **GAP** |
|28 | Intent (editable post-onboarding)                 | `ios/Drift/Features/Profile/EditProfileScreen.swift:12`                            | OK     | —   | Android **GAP** (`profile/ProfileScreen.kt:23` empty) |
|29 | Invisibility toggle                               | `ios/Drift/Features/Settings/SettingsScreen.swift:12`                              | OK     | —   | Android `settings/SettingsScreen.kt:36` |
|30 | Pause discoverability                             | `ios/Drift/Features/Settings/SettingsScreen.swift:13`                              | OK     | —   | Android `settings/SettingsScreen.kt:40` |
|31 | 12/24-hour clock                                  | `ios/Drift/Features/Settings/SettingsScreen.swift:20`                              | Partial | P2 | Android **GAP** |
|32 | Theme (system/light/dark)                         | `ios/Drift/Features/Settings/SettingsScreen.swift:21`                              | Partial | P2 | Android **GAP** |
|33 | Sentry / PostHog opt-ins                          | `ios/Drift/Features/Settings/SettingsScreen.swift:16-17`; `android/app/src/main/java/com/americangroupllc/drift/settings/SettingsScreen.kt:43-51` | OK | — | |
|34 | Erase-all-data                                    | `ios/Drift/Features/Settings/SettingsScreen.swift:31`                              | **GAP**| P0  | iOS button comment references `DELETE /functions/v1/wipe-me`, but **no `wipe-me` Edge Function exists** under `backend/supabase/functions/`. Android **GAP** |
|35 | Account deletion                                  | `ios/Drift/Features/Settings/SettingsScreen.swift:32`                              | Partial | P1 | iOS only signs out (`SettingsScreen.swift:32` → `AppSession.signOut`); does not close `auth.users` row. Android **GAP** |

### 1.8 Push

| # | Promised feature                                  | Citation                                                                          | Status | Sev | Notes |
|---|---------------------------------------------------|-----------------------------------------------------------------------------------|--------|-----|-------|
|36 | iOS rich push (decrypts previews + thumbnail)     | `ios/DriftNotificationService/NotificationService.swift:10`                        | OK     | —   | App Group decrypt at line 48 |
|37 | Android FCM `DriftMessagingService` (real impl)   | `android/app/src/main/java/com/americangroupllc/drift/push/DriftMessagingService.kt:14` | **GAP** | **P0** | **Round-3 carry-over not actually fixed.** Class extends `android.app.Service` only so the `Instantiatable` lint passes; doc-comment line 7-13 still self-describes as `"placeholder class"`. Does **not** extend `FirebaseMessagingService`, has no `onMessageReceived`, no `onNewToken`. |

---

## 2. Bug list (`TODO|FIXME|XXX|HACK|stub|placeholder` across source)

Production-source occurrences only (test, docs, marketing, build configs excluded).

| File:line | Snippet | Severity |
|---|---|---|
| `android/app/src/main/java/com/americangroupllc/drift/push/DriftMessagingService.kt:8-13` | "Firebase Cloud Messaging receiver - stub … placeholder class" | **P0** |
| `ios/Drift/Services/SettingsScreen.swift:31` (`Features/Settings/SettingsScreen.swift:31`) | `Button("Erase all data") { /* DELETE /functions/v1/wipe-me */ }` — **endpoint does not exist** | **P0** |
| `ios/Drift/Services/AuthService.swift:24` | `let token = "stub-token-for-\(phone)"` — bypasses real Supabase OTP verify | P1 |
| `ios/Drift/Services/AuthService.swift:4` | "Stub Supabase client singleton" | P1 |
| `ios/Drift/Services/ChatService.swift:4` | "plus a Realtime subscription stub" — no websocket subscription wired | P1 |
| `ios/Drift/Services/VerificationService.swift:21` | "Storage upload is omitted in skeleton" — Edge Function called with random `selfie_image_id` | P1 |
| `ios/Drift/Services/LocationService.swift:35-40` | "Skeleton: real impl resolves ZIP-prefix from a baked-in polygon table … only emit nils" | P1 |
| `ios/Drift/Features/Profile/VoicePromptRecorder.swift:5-9` | "skeleton — wires up AVAudioRecorder only when permissions are granted" — no recorder instance | P1 |
| `android/app/src/main/java/com/americangroupllc/drift/profile/ProfileScreen.kt:23` | `// Skeleton — bind to a ViewModel that loads Profile` | P1 |
| `android/app/src/main/java/com/americangroupllc/drift/discover/DiscoverScreen.kt:38` | `val candidates = remember { listOf<Profile>() }   // wired up in DiscoverViewModel` | P1 |
| `android/app/src/main/java/com/americangroupllc/drift/chat/ChatScreen.kt:37,81` | empty messages, `Button(onClick = { /* send */ })` | P2 |
| `android/app/src/main/java/com/americangroupllc/drift/chat/ChatListScreen.kt:21` | `val convos = remember { listOf<Conversation>() }` — no fetch | P2 |
| `android/app/src/main/java/com/americangroupllc/drift/discover/DiscoverScreen.kt:75-77` | `OutlinedButton(onClick = { /* pass */ })`, `Button(onClick = { /* wave */ })` | P2 |
| `android/app/src/main/java/com/americangroupllc/drift/matches/MatchesScreen.kt:21` | `val matches = remember { listOf<Wave>() }` — never populated | P2 |
| `android/wear/src/main/java/com/americangroupllc/driftwear/tile/MatchTileService.kt:22-29` | empty `TimelineEntry.Builder().build()` — tile shows nothing | P1 |
| `android/wear/src/main/java/com/americangroupllc/driftwear/complication/QuickReplyComplicationService.kt:23-25` | "Real implementation reads `wave_aggregates.pending_total` …" → returns hard-coded `"0"` | P2 |
| `android/wear/src/main/java/com/americangroupllc/driftwear/MainActivity.kt:31` | `val matches = listOf("Sara matched", "Maya waved")` — hard-coded sample | P2 |
| `watchos/DriftWatch/Views/QuickReplyView.swift:14` | `Button("Wave back") { /* PATCH /rest/v1/waves */ }` | P2 |
| `watchos/DriftWatch/Views/QuickReplyView.swift:29` | `Button { /* send */ }` reply rows are no-op | P2 |
| `watchos/DriftWatch/Views/MatchesListView.swift:5` | `@State private var matches: [Wave] = []` never populated | P2 |
| `watchos/DriftWatchComplication/MatchesComplication.swift:34-43` | `placeholder`, `getSnapshot`, `getTimeline` all return same hard-coded `LayerEntry(layer:.zip, unread:0)` | P2 |
| `ios/Drift/Features/Discover/WaveActions.swift:28-29` | `// no-op in v1; record locally so it doesn't reappear` | P2 |
| `ios/Drift/Features/Safety/ReportSheet.swift:21-24` | Submit fires analytics, no `INSERT` into `reports` | P2 |
| `ios/Drift/Features/Safety/BlockedUsersScreen.swift:12` | `Button("Unblock") { /* DELETE /rest/v1/blocked_users */ }` | P2 |
| `ios/DriftNotificationService/NotificationService.swift:49-50` | "Production wires up an actual crypto key derived from the user's auth" — currently App-Group lookup only | P2 |
| `ios/DriftUITests/DriftUITests.swift:4` | "requires a stubbed Supabase; in CI we just verify the app boots" | P3 |
| `shared/DriftCore/Sources/DriftCore/Observability/AnalyticsService.swift:107` | "This stub keeps the API surface stable" | P3 |

No `TODO`, `FIXME`, `XXX`, or `HACK` literal markers were found in any production source file.

---

## 3. Round-3 carry-over verification

| Round-3 claim | Verdict |
|---|---|
| `DriftMessagingService` was a placeholder, fixed in Round 3 (now extends Service with real FCM handling) | **NOT FIXED.** File extends `android.app.Service`, not `FirebaseMessagingService`; has no `onMessageReceived` / `onNewToken` overrides; class doc-comment still labels itself a placeholder (`DriftMessagingService.kt:8`). The Round-3 change only swapped the parent class so the `Instantiatable` lint check passes. No FCM dependency is referenced from `app/build.gradle.kts` (push functionality remains absent on Android). **Severity P0**. |
| `watchos/` directory was thin | **CONFIRMED THIN BUT FUNCTIONAL.** `watchos/DriftWatch/` contains `App/DriftWatchApp.swift`, `Views/MatchesListView.swift`, `Views/QuickReplyView.swift`. `watchos/DriftWatchComplication/MatchesComplication.swift` provides accessory-circular / inline / rectangular families. All are skeleton-grade: matches list never loads data, complication uses hard-coded `unread:0`, wave-back / send buttons are comments. Adequate for project-yml + build but no live data path. **Severity P2** (cosmetic / data-binding). |

---

## 4. Summary counts

| Metric | Count |
|---|---|
| Promised features audited | **37** |
| Fully OK | **14** |
| Partial (UI present, data/wiring incomplete) | **15** |
| Outright GAPs | **8** |
| Bug-list entries (production source) | **27** |

### Severity totals (across § 1 statuses + § 2 bug list, deduplicated)

| Severity | Count |
|---|---|
| **P0** | **3** (Android FCM service still a placeholder · iOS Erase-all-data references non-existent `wipe-me` Edge Function · Erase-all-data also missing on Android) |
| **P1** | **17** |
| **P2** | **18** |
| **P3** | **2** |

### Top action items (in priority order)

1. **P0** Implement `backend/supabase/functions/wipe-me/index.ts` and wire `SettingsScreen.swift:31` to call it; add Android equivalent.
2. **P0** Replace `android/app/.../push/DriftMessagingService.kt` with a real `FirebaseMessagingService` subclass; add `firebase-messaging` to `app/build.gradle.kts` and the `<service>` declaration to the manifest.
3. **P1** Wire `ios/Drift/Features/Safety/ReportSheet.swift:21` Submit to `INSERT` into `reports`; add Block action on profile cards + chat header; add Android Compose `ReportSheet` + `BlockedUsersScreen`.
4. **P1** Add screenshot disclosure: `UIScreen.userDidTakeScreenshotNotification` observer on iOS chat screen; one-time first-open toast on Android `chat/ChatScreen.kt`.
5. **P1** Implement Three-prompts editor (`profile_prompts` table is already in `0001_init.sql`).
6. **P1** Implement Like-a-prompt server-mode action.
7. **P1** Replace iOS auth stub-token (`AuthService.swift:24`) with real Supabase Auth REST call.
8. **P1** Wire mute toggles to `conversations.muted_by_a/b` columns.
9. **P1** Bind Android `discover/DiscoverScreen.kt`, `chat/ChatScreen.kt`, `matches/MatchesScreen.kt`, `profile/ProfileScreen.kt` to real ViewModels backed by `DiscoverService` / `ChatService` / `ProfileService` (none of these services exist on the Android side yet).
10. **P1** Add Android `VerificationService` + camera selfie capture.
