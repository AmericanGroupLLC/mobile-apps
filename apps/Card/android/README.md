# Card — Android

Multi-module Gradle project: `:core` (pure Kotlin/JVM, JUnit-tested), `:app`
(Compose phone app + Quick Settings tile), and `:wear` (Wear Compose + Wear
tile + complication).

## Build

```bash
cd android
gradle wrapper --gradle-version 8.10   # one-time bootstrap
./gradlew :core:test                   # pure-JVM unit tests
./gradlew :app:testDebugUnitTest       # Android-side unit tests
./gradlew :wear:testDebugUnitTest
./gradlew :app:assembleDebug :wear:assembleDebug
./gradlew :app:connectedDebugAndroidTest   # Compose UI smoke (needs emu)
```

The four CI fixes from the Pocket scaffold are baked in here:

1. CI uses `gradle/actions/setup-gradle@v3` so `gradle wrapper` has a binary.
2. `:app/build.gradle.kts` and `:wear/build.gradle.kts` start with
   `import java.util.Properties` (Kotlin DSL doesn't auto-import `java.util.*`).
3. `:core` is JVM-only, so the test task is `:core:test`, not `:core:testDebugUnitTest`.
4. `:app` applies the Compose BOM to **both** `implementation(...)` and
   `androidTestImplementation(...)` so the UI test deps resolve at the
   right version.

## Module map

| Module | Purpose |
|--------|---------|
| `:core` | Pure Kotlin/JVM. `Card`, `CardKindTransitions`, `ReminderScheduler`, `CardSorter`, `CardRepository` interface, observability stubs. Mirrors `shared/CardCore/`. |
| `:app`  | Phone app. Compose UI, Hilt, Room (`CardDb`/`CardDao`), AlarmManager-based `ReminderService` + `BootReceiver`, `QuickCaptureTileService` (Quick Settings tile). |
| `:wear` | Wear OS app. Wear Compose, Wear tile + complication. Same `:core`. |

## Permissions (manifest)

`:app` declares only what it actually uses:

- `RECEIVE_BOOT_COMPLETED` — re-schedule reminders after a reboot
- `POST_NOTIFICATIONS` — fire reminder notifications (runtime perm on API 33+)
- `SCHEDULE_EXACT_ALARM` + `USE_EXACT_ALARM` — minute-accurate reminder fire times
- `WAKE_LOCK` — fire reminders even when the screen is off

**No CAMERA, no LOCATION, no Bluetooth, no NFC.**

## Quick Settings tile

`QuickCaptureTileService` is registered with `BIND_QUICK_SETTINGS_TILE` and
launches `QuickCaptureActivity` on tap. The activity is translucent and
single-screen — save or cancel ends it.

## Sentry / PostHog

Wrappers live in `:core`'s `obs` package; the SDKs aren't bundled. See
[`../SENTRY.md`](../SENTRY.md) for the wiring steps.
