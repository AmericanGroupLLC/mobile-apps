# OBSERVABILITY.md

## v1: nothing

By design. BuddyPlay is offline-first; we have no server to receive metrics
and no consent flow yet for sending data home. The user gets an explicit
guarantee:

> **BuddyPlay does not send any data to us.**

This appears in the Settings screen and on the marketing site.

## What still exists in code

The `canImport`-gated stubs from the Drift / Card scaffold are kept so v1.1
can opt in trivially without an architecture refactor:

- `shared/BuddyCore/Sources/BuddyCore/Observability/AnalyticsService.swift`
- `shared/BuddyCore/Sources/BuddyCore/Observability/CrashReportingService.swift`
- `android/core/src/main/.../observability/AnalyticsService.kt`
- `android/core/src/main/.../observability/CrashReportingService.kt`

All four implement a no-op interface in v1. The methods exist; they do
nothing. No SDK is imported.

## v1.1 plan (NOT in scope for v1)

If we ever want metrics, the smallest possible step is:

1. Add a Settings toggle: **"Help improve BuddyPlay (sends anonymous game
   counts; never opponent names)"**. Default OFF.
2. Behind that toggle, attach **PostHog** (open-source, self-hostable) or
   **Sentry** (crash only).
3. Whitelist: `game_started(kind, transport)`, `game_finished(kind, durationSec)`,
   `crash(stack)`. Nothing else.
4. Update `PRIVACY.md` to call out the new optional flow.

## Local-only logs

Both apps log via the platform-native logger:
- iOS: `os_log` / `Logger`. Visible in Console.app while a Sim or device is
  attached.
- Android: `android.util.Log`. Visible via `adb logcat`.

No log persistence. No log forwarding. No file rotation.

## Production debugging without telemetry

Until v1.1 attaches a real backend, our debugging story is:

1. **Repro locally** with two devices on the same Wi-Fi.
2. **`adb logcat -s BuddyPlay`** for Android.
3. **Console.app filtered to `com.americangroupllc.buddyplay`** for iOS.
4. **Reproduce on Simulator** for Wi-Fi/BLE issues — Simulator's BLE works
   between two simulator instances.
5. Ask users to **send a screen recording**; we don't request crash logs.
