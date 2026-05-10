# OBSERVABILITY.md

## v1: nothing on by default

By design. Offline AI Buddy is offline-first; we have no server to
receive metrics and no consent flow yet for sending data home. The user
gets an explicit guarantee on the Settings screen and on the marketing
site:

> **Offline AI Buddy does not send any data to us.**

## What still exists in code

The `canImport`-gated stubs from the Card / Drift / BuddyPlay scaffold
are kept so v1.1 can opt in trivially without an architecture refactor:

- `shared/BuddyAICore/Sources/BuddyAICore/Observability/AnalyticsService.swift`
- `shared/BuddyAICore/Sources/BuddyAICore/Observability/CrashReportingService.swift`
- `android/core/src/main/.../observability/AnalyticsService.kt`
- `android/core/src/main/.../observability/CrashReportingService.kt`

All four implement a no-op interface in v1. The methods exist; they do
nothing. No SDK is imported.

## v1.1 plan (NOT in scope for v1)

If we want metrics, the smallest possible step is:

1. Add a Settings toggle: **"Help improve Offline AI Buddy (sends
   anonymous usage counts; never chat content)"**. Default OFF.
2. Behind that toggle, attach **PostHog** (open-source, self-hostable)
   or **Sentry** (crash only).
3. Whitelist: `chat_started(language, kind)`,
   `chat_finished(durationSec, tokenCount)`, `crash(stack)`. Nothing
   else. **Never** chat content.
4. Update `PRIVACY.md` to call out the new optional flow.

## Local-only logs

Both apps log via the platform-native logger:
- iOS: `os_log` / `Logger`. Visible in Console.app while a Sim or
  device is attached.
- Android: `android.util.Log`. Visible via `adb logcat`.

No log persistence. No log forwarding. No file rotation.

## Production debugging without telemetry

Until v1.1 attaches a real backend, our debugging story is:

1. **Repro locally** with the same model build.
2. **`adb logcat -s OfflineAIBuddy`** for Android.
3. **Console.app filtered to `com.americangroupllc.offlineaibuddy`** for
   iOS.
4. Ask users to **send a screen recording**; we don't request crash
   logs.
