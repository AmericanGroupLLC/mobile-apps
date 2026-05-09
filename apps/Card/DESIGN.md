# Card — DESIGN

This file describes the layered architecture, the per-platform stack, and where
to find each responsibility in the repo. It is a living map of the codebase, not
a tutorial — for setup see [`QUICKSTART.md`](QUICKSTART.md).

---

## 1. Goals that constrain every design choice

1. **Sub-3-seconds from thought to stored.** Every UX decision is in service of
   shrinking the keystroke-to-disk path.
2. **One mental model.** The user sees one feed and one composer. The same
   `Card` struct is the only domain object on every platform.
3. **Local-first.** No account, no backend, no cloud sync. Storage is JSON-on-disk
   (Apple) or Room/SQLite (Android), both writable from quick-capture surfaces.
4. **Idiomatic native UI.** SwiftUI for Apple, Compose for Android — never a
   shared UI layer.
5. **Privacy by default.** Crash reporting and analytics are off until the user
   opts in. Permission strings are explicit. No camera, no location.

---

## 2. The layered architecture (every platform)

```
┌─────────────────────────────────────────┐
│  UI layer  (SwiftUI / Compose / Wear)   │  Per-platform — never shared
├─────────────────────────────────────────┤
│  Service layer                          │  CardRepository, ReminderService,
│                                         │  AppDelegate / Application bootstrap
├─────────────────────────────────────────┤
│  Domain layer  (shared)                 │  Card, CardKind, CardKindTransitions,
│                                         │  ReminderScheduler, CardSorter
├─────────────────────────────────────────┤
│  Storage layer  (per-platform impl)     │  CardStore (JSON, App Group)
│                                         │  Room (CardDb / CardDao / CardEntity)
├─────────────────────────────────────────┤
│  Observability  (canImport-gated)       │  AnalyticsService, CrashReportingService
└─────────────────────────────────────────┘
```

The **domain layer is the keystone**. It is mirrored case-for-case across
`shared/CardCore/Sources/CardCore/Domain/` (Swift) and
`android/core/src/main/java/com/americangroupllc/card/core/domain/` (Kotlin),
and **both are tested with the same scenarios** (`CardCoreTests` / `:core:test`).
If a behaviour change lands on one side without the other, CI fails on the side
that didn't update.

---

## 3. The Card domain model

A single struct/data class:

```
Card
├─ id            UUID / String
├─ text          String                        // the body
├─ kind          .note | .task | .reminder
├─ reminderAt    Date?                          // populated only for .reminder
├─ completedAt   Date?                          // populated only when a task is done
├─ createdAt     Date
└─ updatedAt     Date
```

Three pure helpers operate on it:

- **`CardKindTransitions`** — legal transitions between kinds (note↔task↔reminder)
  and rules for what fields get cleared. Example: `note → reminder` requires a
  non-nil reminder Date and validates it isn't in the past.
- **`ReminderScheduler`** — pure helpers that compute the next-fire time for a
  reminder Date, handling DST boundaries. Returns `nil` for past reminders.
  Collapses identical-minute reminders into a single grouped notification.
- **`CardSorter`** — pure feed-sort logic. Pinned reminders due soon → undated
  cards by recency → completed tasks at the bottom.

These three files **must compile and test green on both stacks before any UI
work happens**. They are the equivalent of Pocket's `CalculatorEngine` — the
keystone test-targets that prove the contract.

---

## 4. Per-platform stack

### iPhone

| Concern         | Stack                                                       |
|-----------------|-------------------------------------------------------------|
| UI              | SwiftUI `WindowGroup` + `NavigationStack`                   |
| State           | `@StateObject CardRepository` (publishes `[Card]`)          |
| Storage         | `CardStore` JSON in App Group container                     |
| Reminders       | `UNUserNotificationCenter` (one request per Card)           |
| Quick capture   | **Share Extension** writes directly to App Group `CardStore`|
| Voice fallback  | `Speech` framework — only invoked from the share-ext flow   |

Bundle IDs:
- App: `com.americangroupllc.card`
- Share Extension: `com.americangroupllc.card.share`
- App Group: `group.com.americangroupllc.card`

### Apple Watch

| Concern         | Stack                                                       |
|-----------------|-------------------------------------------------------------|
| UI              | SwiftUI `WindowGroup` (watchOS 10)                          |
| State           | Same `CardStore` shape, scoped to watch container           |
| Composer        | **Voice-first** via `SFSpeechRecognizer`; standard dictation as fallback |
| Quick capture   | WidgetKit **complication** — `accessoryCircular`, `.accessoryInline`, `.accessoryRectangular` — all deep-link to the composer |

### Android

| Concern         | Stack                                                       |
|-----------------|-------------------------------------------------------------|
| UI              | Jetpack Compose, single `MainActivity` host                 |
| Nav             | `androidx.navigation:navigation-compose` (`feed`, `settings`)|
| State           | Hilt-bound `FeedViewModel` exposing `StateFlow<List<Card>>` |
| Storage         | **Room** — `CardDb` / `CardDao` / `CardEntity`              |
| Reminders       | `AlarmManager.setExactAndAllowWhileIdle` + `BootReceiver` re-schedules incomplete reminders after reboot |
| Quick capture   | **Quick Settings tile** (`TileService`) → launches `QuickCaptureActivity` (voice composer) |

Manifest perms: `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS`,
`SCHEDULE_EXACT_ALARM`, `WAKE_LOCK`. No camera, no location.

### Wear OS

| Concern         | Stack                                                       |
|-----------------|-------------------------------------------------------------|
| UI              | Wear Compose                                                |
| State           | Same `:core` repository contract, in-memory backed          |
| Quick capture   | **Wear Tile** (`androidx.wear.tiles.TileService`) launches voice composer; **Complication** (`androidx.wear.watchface.complications`) shows a "+" tap target |
| Reminders       | Inherits from `:core`; `AlarmManager` on the Wear side too  |

---

## 5. Quick-capture path latency budget

The 3-second target is the absolute upper bound. The realistic budget is:

| Step                                       | Budget   |
|--------------------------------------------|----------|
| Surface tap to composer focus              | < 400 ms |
| Type / dictate input                       | user     |
| ⏎ → JSON / Room write + UI update          | < 200 ms |
| Reminder schedule (when applicable)        | < 100 ms |

If any single step exceeds budget, treat it as a regression and reach for a
flame graph.

---

## 6. Observability

`shared/CardCore/Sources/CardCore/Observability/` (Swift) and
`android/core/src/main/java/com/americangroupllc/card/core/obs/` (Kotlin) both
ship `canImport`-gated stubs:

- `AnalyticsService` — backed by PostHog when present; no-op otherwise.
- `CrashReportingService` — backed by Sentry when present; no-op otherwise.

Both expose a `Surface` enum (`.app`, `.shareExtension`, `.watch`,
`.complication`, `.tile`) so the per-surface capture latencies can be
distinguished without adding bespoke event names per platform.

See [`OBSERVABILITY.md`](OBSERVABILITY.md) for the wrapper contract and
[`SENTRY.md`](SENTRY.md) for the real install steps if you choose to wire
the SDKs in.

---

## 7. CI / CD

Six workflows, each lifted from the Pocket reference scaffold with the four
known fixes already baked in (`gradle/actions/setup-gradle@v3`,
`import java.util.Properties`, `:core:test` not `testDebugUnitTest`,
`androidTestImplementation(composeBom)`).

- **`ci.yml`** — every push: Android unit + lint + assemble debug, iOS/watchOS
  Swift Package tests, marketing-site lint.
- **`ios.yml`** — iOS app build (sim) + iOS XCUITest + watchOS app build (sim).
- **`android.yml`** — Compose UI smoke on AVD (API 33, x86_64, `-camera-back none`).
- **`marketing.yml`** — deploys `/` to GitHub Pages.
- **`pre-release-tests.yml`** — gate that runs the full matrix before any tag.
- **`release.yml`** — tag-driven Fastlane Match release builds; gracefully
  no-ops when secrets are absent.

See [`RELEASING.md`](RELEASING.md) for the tag → release flow.
