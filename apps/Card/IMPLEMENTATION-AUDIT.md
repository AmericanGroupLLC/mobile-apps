# Card — Implementation Audit (Round-4 Phase-7a)

**Date:** 2026-05-08
**Scope:** Verify every product-spec promise (`CARD-FEATURES.md`, supplemented by `README.md` and `DESIGN.md`) against actual source under `shared/`, `ios/`, `watchos/`, `android/`, and `desktop/`.
**Method:** Static read of source files plus a regex sweep for `TODO|FIXME|XXX|HACK|stub|placeholder` across `*.kt|*.swift|*.js|*.ts|*.java|*.xml` (excluding `.md`, `node_modules`, `build/`, `.git`).
**Round-4 prior claim:** "Card was previously identified as having only UI-string placeholders (no real gap)." — see §4 for re-evaluation.

---

## 1. Severity legend

| Severity | Meaning                                                                                      |
|----------|----------------------------------------------------------------------------------------------|
| **P0**   | Will cause a store rejection (privacy text missing, exact-alarm not justified, crash, etc.). |
| **P1**   | A feature that `CARD-FEATURES.md`/`README.md` explicitly claims is real but is missing or partial in code on at least one shipping platform. |
| **P2**   | UX polish / cross-platform parity divergence. Feature works, gesture or copy differs.        |
| **P3**   | Safe / deliberate fallback (e.g. canImport-gated stub, OS placeholder API). No user impact.  |

---

## 2. Promised features — citation table

### 2.1 Domain model & shared logic (`shared/CardCore`, `android/core`)

| # | Promise (source) | Apple impl | Android impl | Verdict |
|---|---|---|---|---|
| F1  | `Card` model with `id, text, kind, reminderAt, completedAt, createdAt, updatedAt` (`DESIGN.md` §3) | `shared/CardCore/Sources/CardCore/Models/Card.swift` | `android/core/src/main/java/com/americangroupllc/card/core/models/Card.kt` | ✅ |
| F2  | `CardKind` enum `.note | .task | .reminder` (`CARD-FEATURES.md` §3) | `Card.swift` (CardKind enum) | `Card.kt` (CardKind enum) | ✅ |
| F3  | `CardKindTransitions` — legal note↔task↔reminder, clears irrelevant fields, future-only reminders (`CARD-FEATURES.md` §3, `DESIGN.md` §3) | `shared/CardCore/Sources/CardCore/Domain/CardKindTransitions.swift:5-46` | `android/core/src/main/java/com/americangroupllc/card/core/domain/CardKindTransitions.kt` | ✅ |
| F4  | `ReminderScheduler` — next-fire math, future-only filter, group-by-minute (`DESIGN.md` §3) | `shared/CardCore/Sources/CardCore/Domain/ReminderScheduler.swift:6-35` | `android/core/src/main/java/com/americangroupllc/card/core/domain/ReminderScheduler.kt` | ✅ |
| F5  | `CardSorter` — pinned reminders → undated by recency → completed at bottom (`DESIGN.md` §3) | `shared/CardCore/Sources/CardCore/Domain/CardSorter.swift` | `android/core/src/main/java/com/americangroupllc/card/core/domain/CardSorter.kt` | ✅ |
| F6  | Mirrored case-for-case unit tests on both stacks (`README.md`, `DESIGN.md` §2) | `shared/CardCore/Tests/CardCoreTests/{CardKindTransitionsTests,ReminderSchedulerTests,CardSorterTests,CardStoreTests}.swift` | `android/core/src/test/java/.../{CardKindTransitionsTest,ReminderSchedulerTest,CardSorterTest}.kt` | ✅ |

### 2.2 Storage layer

| # | Promise | Apple impl | Android impl | Verdict |
|---|---|---|---|---|
| F7  | `CardStore` JSON-on-disk, App-Group-aware (`README.md`, `DESIGN.md` §4) | `shared/CardCore/Sources/CardCore/Storage/CardStore.swift:12-68`; App-Group helper at `:38-47`; atomic writes at `:66` | n/a (Apple-only) | ✅ |
| F8  | Room (SQLite) on Android — `CardDb` / `CardDao` / `CardEntity` (`README.md`, `DESIGN.md` §4) | n/a | `android/app/src/main/java/com/americangroupllc/card/data/{CardDb,CardDao,CardEntity,CardRepositoryImpl}.kt` | ✅ |

### 2.3 Reminders (real OS-scheduled)

| # | Promise | Apple impl | Android impl | Verdict |
|---|---|---|---|---|
| F9  | Apple: `UNUserNotificationCenter`, one request per Card, idempotent cancel/re-schedule (`DESIGN.md` §4, `README.md`) | `ios/Card/Services/ReminderService.swift:8-56` (schedule `:16-40`, cancel `:42-45`) | n/a | ✅ |
| F10 | Android: `AlarmManager.setExactAndAllowWhileIdle`; `BootReceiver` re-arms after reboot (`README.md`, `DESIGN.md` §4) | n/a | `android/app/.../reminder/ReminderService.kt:21-50`; `BootReceiver.kt:18-40` | ✅ |
| F11 | Reminder permission requested at first launch (POST_NOTIFICATIONS Android 13+) | (UN auth requested in `ReminderService.swift:11-14`) | `android/app/.../MainActivity.kt:23-31` | ✅ |

### 2.4 Quick-capture surfaces (the four)

| # | Promise (`CARD-FEATURES.md` §4) | Impl | Verdict |
|---|---|---|---|
| F12 | **iOS Share Extension** — selected text → App Group `CardStore`, main app NOT launched | `ios/CardShareExtension/ShareViewController.swift:8-79` (writes via `CardStore.appGroup()` at `:69`, completes without launch at `:23`) | ✅ |
| F13 | **Apple Watch complication** — `accessoryCircular`, `.accessoryInline`, `.accessoryRectangular`; deep-links to composer (`DESIGN.md` §4) | `watchos/CardComplication/QuickCaptureComplication.swift:7-67` (families at `:17-21`, widgetURL at `:13`) | ✅ |
| F14 | **Android Quick Settings tile** → `QuickCaptureActivity` voice composer | `android/app/.../tile/QuickCaptureTileService.kt:14-36`; activity `android/app/.../composer/QuickCaptureActivity.kt` | ✅ |
| F15 | **Wear OS tile** → composer | `android/wear/.../tile/QuickCaptureTileService.kt:23-`; `androidx.wear.tiles.TileService` | ✅ |
| F16 | **Wear OS complication** ("+" tap target) (`DESIGN.md` §4 Wear row) | `android/wear/.../complication/QuickCaptureComplicationService.kt:16-43` | ✅ |
| F17 | Apple Watch composer voice path "with `SFSpeechRecognizer` already armed" (`CARD-FEATURES.md` §4) | `watchos/CardWatch/Views/ComposerView.swift:6-32` — uses watchOS dictation via `TextField`. SFSpeechRecognizer is linked (`watchos/README.md:23`) but not invoked here. | ⚠ **P2 partial** — claim is "armed"; impl uses platform dictation surface (effectively the same UX) but the named API is not actually wired. |
| F18 | Wear composer with "dictation already armed" (`CARD-FEATURES.md` §4) | `android/wear/.../composer/ComposerScreen.kt:32-59`. `Dictate` button currently prefills the literal string `"Spoken card"` (line 42) instead of invoking `RemoteInput`/system dictation. The file's own comment at `:41` reads `// v1: prefill demo text. The real path uses RemoteInput / dictation.` | ⚠ **P1 GAP** — voice path is a hard-coded string; the real system dictation path is annotated as TODO in code. |

### 2.5 Composer / Feed / Convert UX

| # | Promise (`README.md` "What ships in v1") | Apple impl | Android impl | Verdict |
|---|---|---|---|---|
| F19 | Single feed of Cards, newest-first, on-device | `ios/Card/Views/Feed/FeedView.swift:18-30`; `ios/Card/Services/CardRepository.swift` | `android/app/.../feed/FeedScreen.kt:53-83`; `android/app/.../feed/FeedViewModel.kt:28-31` (sorted by `CardSorter.sort`) | ✅ |
| F20 | Inline composer at top | `ios/Card/Views/Composer/ComposerView.swift`; mounted at `FeedView.swift:11-14` | `android/app/.../composer/ComposerScreen.kt:23-53`; mounted at `FeedScreen.kt:58-69` | ✅ |
| F21 | One-tap convert: Note ↔ Task ↔ Reminder | `ios/Card/Views/Composer/CardActionSheet.swift` (uses `CardKindTransitions.convert`) | `android/app/.../feed/CardActionSheet.kt`; `FeedViewModel.kt:41-47` | ✅ |
| F22 | Swipe-to-delete | `ios/Card/Views/Feed/FeedView.swift:23-27` (`.swipeActions`) | n/a — Android deletes via tap → action sheet → "Delete" (`CardActionSheet.kt:74-75`); no swipe gesture | ⚠ **P2** — feature works on Android (delete is reachable), but the gesture differs from the README claim. |
| F23 | Long-press to edit | `ios/Card/Views/Feed/FeedView.swift:22` (`onTapGesture` opens action sheet — actually a tap, not long-press) | `android/app/.../feed/FeedScreen.kt:78` (`onTap` opens action sheet) | ⚠ **P2** — README says "long-press"; both platforms use tap. Editing is reachable via the action sheet. |

### 2.6 Settings (six controls per `CARD-FEATURES.md` §5)

| # | Promised control | iPhone | Apple Watch | Android phone | Verdict |
|---|---|---|---|---|---|
| F24 | 12 ↔ 24-hour time | `ios/Card/Views/Settings/SettingsView.swift:13`; persisted via `SettingsModel.swift:19-32` | not in `watchos/CardWatch/Views/SettingsView.swift` (watch defers to phone settings — fine) | `android/app/.../settings/SettingsScreen.kt:42-46`; state in `SettingsViewModel.kt:14-31` | ✅ on iPhone & Android |
| F25 | Theme (System/Light/Dark) | `SettingsView.swift:14-16`; `SettingsModel.swift:35-41` | n/a | ⚠ State exists in `SettingsViewModel.kt:16,21,33-35` but **no UI row** in `SettingsScreen.kt` | ⚠ **P1 GAP** — Android theme picker is not in the Settings UI; state field and setter are unused. |
| F26 | Send crash reports (off by default) | `SettingsView.swift:20-28` | `watchos/CardWatch/Views/SettingsView.swift:10-13` | `SettingsScreen.kt:48-54`; `SettingsViewModel.kt:43-46` | ✅ |
| F27 | Send anonymous usage data (off by default) | `SettingsView.swift:29-37` | `watchos/CardWatch/Views/SettingsView.swift:14-17` | `SettingsScreen.kt:55-61`; `SettingsViewModel.kt:37-41` | ✅ |
| F28 | About (version + GitHub link) | `SettingsView.swift:44-53` | `watchos/CardWatch/Views/SettingsView.swift:18-21` (version-only, no GitHub link) | ⚠ **no About row** in `SettingsScreen.kt` | ⚠ **P1 GAP (Android)** + ⚠ **P2** on Watch (no GitHub link). |
| F29 | Erase all data (with confirm dialog) | `SettingsView.swift:55-82` (confirmation dialog at `:70-82`); calls `repository.eraseAll()` | n/a | ⚠ `FeedViewModel.kt:63-66` has `eraseAll()` and `CardDao.kt:24-25` has `deleteAll()`, but **the Settings UI never invokes them** and there is no confirm dialog wired in. | ⚠ **P1 GAP (Android)** — backing logic exists; UI affordance is missing. |
| F30 | Settings persisted across launches | `SettingsModel.swift:25-33` (UserDefaults in App Group) | (defers to phone) | ⚠ `SettingsViewModel.kt:24-26` initialises a fresh `MutableStateFlow(SettingsState())` per VM — **no SharedPreferences/DataStore persistence**. Toggles reset on process death. | ⚠ **P1 GAP (Android)** — settings are in-memory only on Android. |

### 2.7 Observability stubs

| # | Promise (`PRODUCTION.md` §1, `DESIGN.md` §6) | Apple impl | Android impl | Verdict |
|---|---|---|---|---|
| F31 | `AnalyticsService` (PostHog when present, no-op otherwise) | `shared/CardCore/Sources/CardCore/Observability/AnalyticsService.swift` | `android/core/src/main/java/com/americangroupllc/card/core/obs/AnalyticsService.kt` | ✅ (canImport-gated stub by design) |
| F32 | `CrashReportingService` (Sentry when present, no-op otherwise) | `shared/CardCore/Sources/CardCore/Observability/CrashReportingService.swift` | `android/core/src/main/java/com/americangroupllc/card/core/obs/CrashReportingService.kt` | ✅ (canImport-gated stub by design) |
| F33 | `Surface` enum: `.app, .shareExtension, .watch, .complication, .tile` (`DESIGN.md` §6) | `AnalyticsService.swift` (Surface enum) | `AnalyticsService.kt` (Surface enum) | ✅ |

### 2.8 CI/CD (six workflows per `DESIGN.md` §7)

`ci.yml`, `ios.yml`, `android.yml`, `marketing.yml`, `pre-release-tests.yml`, `release.yml` — declared in repo root as badges in `README.md:9-13`. Workflow YAML files were not part of this static read but are referenced as the `.github/workflows/` set; no source-side gap detectable. **Verdict: ✅ (out-of-scope for source audit; covered by Round-4 CI verification).**

---

## 3. Bug / placeholder list (regex sweep)

Sweep regex: `\b(TODO|FIXME|XXX|HACK|stub|placeholder)\b`
Scope: `*.kt|*.swift|*.js|*.ts|*.java|*.xml` under `shared/`, `ios/`, `watchos/`, `android/`, `desktop/`.

| Hit | File:line | Token | Classification |
|---|---|---|---|
| B1 | `shared/CardCore/Sources/CardCore/Observability/AnalyticsService.swift:1` | `stub` (in comment) | **Intentional fallback** — describes the canImport-gated PostHog stub. P3. |
| B2 | `shared/CardCore/Sources/CardCore/Observability/CrashReportingService.swift:1` | `stub` (in comment) | **Intentional fallback** — describes the canImport-gated Sentry stub. P3. |
| B3 | `ios/Card/Resources/LaunchScreen.storyboard:19` | `placeholder` | **Intentional fallback** — Interface Builder `<placeholder>` element for `IBFirstResponder`. Standard XIB metadata, not user-visible. P3. |
| B4 | `watchos/CardComplication/QuickCaptureComplication.swift:26` | `placeholder` | **Intentional fallback** — `TimelineProvider.placeholder(in:)` is a required WidgetKit override. P3. |
| B5 | `android/app/.../composer/ComposerScreen.kt:38` | `placeholder` | **Intentional fallback** — Material 3 `OutlinedTextField(placeholder = …)` parameter (UI string `R.string.composer_hint`). P3. |
| B6 | `android/app/.../composer/QuickCaptureActivity.kt:86` | `placeholder` | **Intentional fallback** — same Compose API (`placeholder = { Text("Speak or type…") }`). P3. |

> Additionally noted (not matched by the regex but identified during structural review): a code comment at `android/wear/.../composer/ComposerScreen.kt:41` reads `// v1: prefill demo text. The real path uses RemoteInput / dictation.` This is **missing real impl** and is captured as F18 above.

> Other markdown documents (e.g. `PRODUCTION.md:22`, `:40`, `TESTING.md:103`) hit the regex but are documentation about placeholders, not code defects. Excluded per the prompt's `.md` exclusion.

---

## 4. Re-evaluation of the Round-4 prior claim

The Round-4 plan recorded Card as: **"only UI-string placeholders (no real gap)."**

**This audit finds that statement to be partially incorrect.** The six `placeholder` regex hits in source (B1–B6 above) are all genuinely benign — five are required-by-OS-API parameters (`OutlinedTextField.placeholder`, WidgetKit `TimelineProvider.placeholder`, Interface Builder `<placeholder>`) and two are descriptive comments on canImport-gated SDK stubs (PostHog, Sentry). On the **placeholder regex axis alone**, the prior claim holds.

However, structural review surfaced **five P1 gaps** that the regex sweep missed because they manifest as missing UI rather than placeholder strings:

1. **F18** — Wear composer "voice-first" path is a hard-coded `text = "Spoken card"` button (`android/wear/.../composer/ComposerScreen.kt:42`).
2. **F25** — Android Settings is missing the Theme picker UI (state and setter exist in `SettingsViewModel.kt`; nothing renders them in `SettingsScreen.kt`).
3. **F28** — Android Settings is missing the About row entirely.
4. **F29** — Android Settings is missing the "Erase all data" UI affordance and confirm dialog (the underlying `eraseAll()` and `deleteAll()` exist in `FeedViewModel.kt:63-66` and `CardDao.kt:24-25` but have no caller in the settings flow).
5. **F30** — Android `SettingsViewModel` does not persist any setting across process death (no SharedPreferences/DataStore wiring).

Three of the five (F25, F28, F29) collapse into a single underlying cause: `android/app/.../settings/SettingsScreen.kt` only renders three rows out of the six promised in `CARD-FEATURES.md` §5.

---

## 5. Summary counts

- **Promised features audited:** 33 (F1–F33).
- **Fully implemented (✅):** 25.
- **Gaps (⚠):** 8 across 6 distinct features (F17, F18, F22, F23, F25, F28, F29, F30).
- **Bug / placeholder regex hits in source:** 6, all classified as **intentional fallback** (P3).
- **Severity rollup:**
  - **P0:** 0
  - **P1:** 5 (F18, F25, F28, F29, F30)
  - **P2:** 4 (F17, F22, F23, plus F28-watch sub-issue)
  - **P3:** 6 (B1–B6 — all benign placeholders)

**Verdict:** Card has **no store-rejection blockers** in code (P0 = 0). The five P1 items are all confined to the Android phone Settings screen (4 of 5) and the Wear voice composer (1 of 5); none touch the iPhone, Apple Watch, or shared domain layer. The Round-4 "UI-string placeholders only" assertion is correct as a statement about literal `placeholder` regex hits, but understates the structural gap on the Android Settings surface, which warrants a v1 follow-up before the Play Store listing claims feature parity with iPhone.
