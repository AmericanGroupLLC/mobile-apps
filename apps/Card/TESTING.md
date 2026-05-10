# Card — TESTING

This file is the manual + automated test matrix. The automated layer is also
documented in [`DESIGN.md` §7](DESIGN.md). Use this checklist before tagging a
release and to onboard a new contributor.

---

## 1. Sanity matrix (run on every push)

| Layer                     | Command / surface                                                                | Where it runs |
|---------------------------|----------------------------------------------------------------------------------|---------------|
| Rename completeness       | `grep -ri "Pocket\|PocketCore\|PocketWatch\|pocket\|pocketwear" . --exclude-dir=.git` returns zero hits | Local |
| `CardCore` Swift Package  | `xcodebuild test -scheme CardCore-Package -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'` | `ci.yml` + `ios.yml` |
| Android `:core`           | `./gradlew :core:test` (Kotlin/JVM, **not** `testDebugUnitTest`)                 | `ci.yml` |
| Android `:app` unit       | `./gradlew :app:testDebugUnitTest :app:lintDebug :app:assembleDebug`             | `ci.yml` |
| Wear `:wear` unit         | `./gradlew :wear:testDebugUnitTest :wear:assembleDebug`                          | `ci.yml` |
| iOS app build (sim)       | `xcodegen generate && xcodebuild build … iphonesimulator …`                      | `ios.yml` |
| iOS XCUITest smoke        | open app → type "Buy milk" → ⏎ → row appears → tap → "Mark as task" → checkbox  | `ios.yml` |
| watchOS build             | `xcodegen generate && xcodebuild build … watchsimulator …`                       | `ios.yml` |
| Compose UI smoke          | `./gradlew :app:connectedDebugAndroidTest`                                       | `android.yml` |

---

## 2. Pure-domain test contract (mirrored case-for-case)

The same scenarios run on both `shared/CardCore/Tests/CardCoreTests/` and
`android/core/src/test/java/com/americangroupllc/card/core/`. If you change one,
you must change the other or CI will diverge.

### `CardKindTransitions`

- `note → task` clears `reminderAt`, leaves `text`/`createdAt` untouched.
- `note → reminder` requires a non-nil reminder Date; reminders set in the past return `nil`.
- `task → note` clears `completedAt`.
- `reminder → task` clears `reminderAt` and adds `completedAt: nil`.
- Identity transition (e.g. `note → note`) is a no-op and returns the same Card.

### `ReminderScheduler`

- Next-fire-time math is correct across DST spring-forward and fall-back boundaries.
- Reminders in the past return `nil` (consumer should drop them, not reschedule them).
- Two reminders with the same calendar minute collapse into a single grouped
  notification with a count badge — verified by `nextFireGrouping` test.

### `CardSorter`

- Pinned reminders due in the next 24h sort to the top.
- Completed tasks sort to the bottom regardless of `updatedAt`.
- All other Cards sort by `updatedAt` descending.
- Empty input returns empty output (no crashes, no nil).

---

## 3. Real-device manual checklist

Run before tagging a release. Mark each ✓ in the PR description.

### Capture loop (every device)

- [ ] **Open app** → composer is focused, keyboard is up.
- [ ] Type "Buy milk" → ⏎ → row "Buy milk" appears at the top of the feed in < 200 ms.
- [ ] Tap the row → bottom action sheet shows Mark as task / Set reminder / Done / Edit / Delete.
- [ ] "Mark as task" → row gets a checkbox; tap checkbox → task marks done; row sorts to bottom.
- [ ] Long-press a row → "Edit text" → composer pre-filled; ⏎ → row updates.
- [ ] Swipe left on a row → Delete → row disappears. Reopen app → still gone.

### Reminders (iPhone + Android phone)

- [ ] Tap a row → "Set reminder" → pick a time 2 min in the future → save.
- [ ] Background the app. After 2 min, the OS notification fires.
- [ ] Reboot the phone. Set a reminder for the next morning. Reboot → reminder still fires.

### iOS Share Extension (iPhone)

- [ ] In Notes (or Safari, or any text source) select a string.
- [ ] Share → **Card – Save**.
- [ ] Relaunch Card → the row is at the top of the feed.
- [ ] Verify: extension never opened the main app; the round-trip was instant.

### Apple Watch complication

- [ ] Long-press the watch face → Edit → add the **Card – Quick capture** complication.
- [ ] Tap the complication → composer opens → dictate → save.
- [ ] Pick up the iPhone → row is in the feed (App Group sync).

### Android Quick Settings tile

- [ ] Pull down twice → tap pencil → drag the **Card** tile into the active row.
- [ ] Tap the tile → voice composer activity launches.
- [ ] Speak → tap save → row visible in main app feed.

### Wear OS tile + complication

- [ ] Long-press watch face → "Add tiles" → Card.
- [ ] Tap tile → composer opens → dictate → save → row visible in Wear feed.
- [ ] Add complication ("+") → tap → composer opens.

### Settings (every device)

- [ ] Toggle 12 ↔ 24-hour → reminder times update format.
- [ ] Toggle theme System / Light / Dark → app re-renders without restart.
- [ ] Toggle Sentry opt-in → no crash, even when SDK isn't installed (canImport stub).
- [ ] Toggle PostHog opt-in → no crash, no events sent until SDK is installed.
- [ ] Erase all data → confirm dialog → feed is empty → reopen app → still empty.

---

## 4. Coverage targets

- `shared/CardCore/Sources/CardCore/Domain/` — **100%** branch coverage. The
  domain layer is the keystone.
- `shared/CardCore/Sources/CardCore/Storage/` — ≥ 90% line coverage with
  temp-directory tests.
- iOS view-models — ≥ 60% line coverage; views are exercised by XCUITest.
- `android/core/` — **100%** branch coverage on `domain/` files, mirroring Apple.
- `android/app/` — Compose UI smoke covers the happy path; ≥ 60% line on
  `feed/`, `composer/`, `settings/` view-models.

Codecov flags (`ios`, `android`) keep these distinguishable on the dashboard;
see [`codecov.yml`](codecov.yml).
