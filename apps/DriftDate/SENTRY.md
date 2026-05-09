# Drift — SENTRY

How Drift wires Sentry without a hard SDK dependency.

## 1. Pattern: `canImport`-gated stub + transport

Both Apple and Android keep crash reporting behind a thin interface
(`CrashReportingService`) and a swappable `CrashTransport`. The Sentry
SDKs are loaded conditionally:

- **Swift**: `#if canImport(Sentry) … #else … #endif` in
  `shared/DriftCore/Sources/DriftCore/Observability/CrashReportingService.swift`.
- **Kotlin**: `if (Class.forName("io.sentry.Sentry") ≠ null)` reflective
  load in `android/core/src/main/java/com/americangroupllc/drift/core/obs/CrashReportingService.kt`.

This keeps:

- Local builds green even if a contributor hasn't pulled the SDK.
- The release `xcodebuild` / Gradle pipelines free to add the SDK in CI without
  changing source.
- Open-source forks completely free of Sentry artefacts.

## 2. Adding the SDK in production

### Apple

`shared/DriftCore/Package.swift` adds the dependency conditionally only
in CI builds via an environment-driven `package.appendIfRelease`. To
add it locally:

```swift
.package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.30.0"),
```

…and `.target(name: "DriftCore", dependencies: ["Sentry"])`.

### Android

`android/core/build.gradle.kts`:

```kotlin
implementation("io.sentry:sentry-android:7.13.0")
```

The release `assembleRelease` step in `release.yml` reads `SENTRY_DSN`
from env, sets it as a `BuildConfig` field, and the
`CrashReportingService.attach(...)` is called from the
`DriftApplication` `onCreate` *only when DSN is non-empty*.

## 3. Opt-in toggle

`SettingsScreen` exposes:

```
[ ] Send crash reports (Sentry)
[ ] Send anonymous product analytics (PostHog)
```

The toggles set `CrashReportingService.shared.optedIn` and
`AnalyticsService.shared.optedIn`. When false, the transport is held but
no events are forwarded.

## 4. PII scrubbing

- Sentry `beforeSend` hook strips `display_name`, `phone_number`,
  `email`, `lat`, `lon` from event tags / extras / breadcrumbs.
- We never put a user's `display_name` in an exception message — use
  `profileId` instead.
- Stack traces are otherwise verbatim.

## 5. Release tagging

Release names follow the convention from `OBSERVABILITY.md` § 5:
`drift@<MARKETING_VERSION>+<CURRENT_PROJECT_VERSION>`. The CI uploads
debug symbols (dSYMs / mapping files) to Sentry per release.
