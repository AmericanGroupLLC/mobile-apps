# Pocket — Observability

> All free tier. All opt-in. Disabled by default. Drop-in stubs ship today;
> real SDK install is documented below as a follow-up.

## Stack

| Concern | Tool | Free tier | Wired in (stub) |
|---|---|---|---|
| Crashes / APM | **Sentry** | 5K errors/mo | iOS · watchOS · Android · Wear |
| Product analytics + feature flags + replays | **PostHog** | 1M events/mo (OSS, EU region) | iOS · Android |

## How the stubs work

Both Apple (`shared/PocketCore/Sources/PocketCore/CrashReportingService.swift`,
`AnalyticsService.swift`) and Android (`android/core/src/main/.../CrashReportingService.kt`,
`AnalyticsService.kt`) ship as **no-op wrappers** behind a `canImport(Sentry)` /
`if (BuildConfig.SENTRY_DSN.isNotEmpty())` gate. The wrapper API is stable,
so app code can call `Crash.report(error)` and `Analytics.track("alarm_set")`
today; whether anything is sent depends on:

1. Whether the user opted in via Settings → Privacy.
2. Whether the SDK is actually compiled in (controlled by `Package.swift` /
   `app/build.gradle.kts` dependencies).
3. Whether a DSN / API key is set (CI build env or local `.env`).

When any of those conditions is false, the wrappers no-op. No crashes, no
warnings.

## Privacy contract

Every event passes through a sanitiser that:

- Removes `event.user` entirely (no UUIDs, no IDFV/AAID, no emails).
- Strips alarm names, timezone selections, sound choices, and bedtime targets.
- Allows only counts, anonymous feature usage events, and SDK-internal context.
- Drops the event entirely if the user toggled the opt-in off.

## How to drop in real SDKs (post-launch)

### iOS / watchOS — Sentry

1. Edit `shared/PocketCore/Package.swift`, add the dependency:
   ```swift
   .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0"),
   ```
2. Add the product to the `PocketCore` target's `dependencies`.
3. Set `SENTRY_DSN_IOS` (and `SENTRY_DSN_WEAR` separately if you want a
   distinct project for the watch app) in repo Secrets.
4. The `canImport(Sentry)` gate flips on automatically.

### Android phone / wear — Sentry

1. In `android/app/build.gradle.kts` and `android/wear/build.gradle.kts`, add:
   ```kotlin
   implementation("io.sentry:sentry-android:7.+")
   ```
2. Set `SENTRY_DSN_ANDROID` and `SENTRY_DSN_WEAR` in repo Secrets.
3. `BuildConfig.SENTRY_DSN` is wired from the env var; the `if` gate flips on.

### iOS / watchOS — PostHog

1. Add `https://github.com/PostHog/posthog-ios` to `Package.swift`.
2. Set `POSTHOG_API_KEY_IOS` + `POSTHOG_HOST` (default
   `https://eu.i.posthog.com`) in repo Secrets.

### Android — PostHog

1. Add `implementation("com.posthog:posthog-android:3.+")` to
   `android/app/build.gradle.kts`.
2. Set `POSTHOG_API_KEY_ANDROID` + `POSTHOG_HOST`.

## Alternatives matrix

| Need | Sentry/PostHog | Alternative | Why you might switch |
|---|---|---|---|
| Crash reporting | Sentry (free 5K/mo) | Firebase Crashlytics (free, unlimited) | If you're already on Firebase |
| Crash reporting | Sentry | Bugsnag (free 7.5K/mo) | Better release-health UI |
| Analytics | PostHog (free 1M/mo, OSS, self-host option) | Mixpanel (free 100K MTU) | Cohort / funnel UI |
| Analytics | PostHog | Amplitude (free 10M events/mo) | Charting depth |
| Analytics | PostHog | Plausible (privacy-first, paid) | Strict GDPR / no cookies |
| Server metrics | n/a | Grafana Cloud Free | If you ever add a backend |
| Uptime | n/a | UptimeRobot Free | Marketing-site uptime |

The wrapper pattern (`Crash.report(_:)` / `Analytics.track(_:)`) was chosen
specifically so swapping providers is a 1-file change.

## Local development

For local crash-test smoke:

- **iOS**: `xcrun simctl push <udid> com.americangroupllc.pocket` with a stub payload.
- **Android**: throw a deliberate `RuntimeException` from a debug menu, observe it gets routed to Sentry only when (a) opt-in is true and (b) DSN is set.

In dev builds without secrets, both wrappers print to console at `.debug` level so you can see what *would* have been reported.
