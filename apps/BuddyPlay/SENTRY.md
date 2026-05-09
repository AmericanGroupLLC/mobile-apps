# SENTRY.md

## TL;DR — Sentry is NOT enabled in v1.

BuddyPlay is offline-first. There is no Sentry DSN, no init call, no SDK
binary in the v1 .ipa or .aab. This document is a forward-looking spec for
v1.1 only.

## Why we kept the stub

The `canImport`-gated `CrashReportingService` stub from the Drift / Card
scaffold is preserved so v1.1 can wire Sentry up without an architecture
refactor:

```swift
// shared/BuddyCore/Sources/BuddyCore/Observability/CrashReportingService.swift
public protocol CrashReportingService {
    func capture(error: Error, context: [String: String])
    func breadcrumb(_ message: String, category: String)
}

public final class NoopCrashReportingService: CrashReportingService {
    public init() {}
    public func capture(error: Error, context: [String: String]) {}
    public func breadcrumb(_ message: String, category: String) {}
}

#if canImport(Sentry)
import Sentry
public final class SentryCrashReportingService: CrashReportingService { ... }
#endif
```

Same shape on Android (`android/core/src/main/.../observability/CrashReportingService.kt`).

## v1.1 wiring plan (NOT in scope for v1)

1. Add **opt-in** Settings toggle: *"Send anonymous crash reports"*. Default OFF.
2. Behind that toggle, init Sentry with `tracesSampleRate = 0`,
   `enableUserInteractionTracing = false`, `attachScreenshot = false`.
3. Scrub PII: `beforeSend` strips opponent display names + peer UUIDs from the
   event payload.
4. Update `PRIVACY.md` to disclose what's sent and link to Sentry's privacy doc.
5. Set DSN via env var (CI secret), not hard-coded — same pattern Drift uses.

## What stays no-op forever

- **Replays**: never. Our screen content includes opponent display names.
- **User identification**: never. Peer UUIDs are not user IDs and are not
  stable across devices.
- **Performance traces**: only via the Settings opt-in.

## Why not in v1

- Adds ~2 MB to each platform binary.
- Requires a backend to receive events; we don't have one.
- Requires a privacy-policy update we don't want to ship as part of the
  initial release.

## Where the no-SDK choice is enforced

- `release.yml` does NOT set `SENTRY_DSN_*` env vars in v1. (Slot exists
  for v1.1.)
- `ios/project.yml` does NOT add the Sentry SPM package.
- `android/app/build.gradle.kts` does NOT add the `io.sentry:sentry-android`
  dependency.
- `Info.plist` and `AndroidManifest.xml` do NOT request crash-related
  permissions or background modes.
