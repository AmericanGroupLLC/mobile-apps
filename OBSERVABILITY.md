# Card — OBSERVABILITY

The contract for analytics + crash reporting wrappers. Both are **off by
default** and shipped without any third-party SDK as a hard dependency.

---

## 1. Why wrappers, not SDKs

Adding a Sentry / PostHog SDK as a hard dependency would:

- Bloat `CardCore` from kilobytes to megabytes.
- Force every consumer of `CardCore` (including the Share Extension) to ship
  the same SDK, even though the extension shouldn't phone home.
- Break the privacy contract that "no events leave the device unless the user
  flips a switch in Settings".

Wrapper pattern instead:

```
                ┌────────────────────────────────────────┐
                │  AnalyticsService.shared (always live) │
                │  ─ optedIn: Bool                       │
                │  ─ attach(transport)                   │
                │  ─ track(event)                        │
                └────────────────────────────────────────┘
                                 ▲
                                 │ canImport(PostHog)
                                 │
                ┌────────────────────────────────────────┐
                │  PostHogTransport (only built when     │
                │  PostHog SDK is on the classpath)      │
                └────────────────────────────────────────┘
```

If PostHog isn't there, the wrapper exists but `track()` is a no-op. If it is
there, you call `AnalyticsService.shared.usePostHog(apiKey:host:)` once at
launch, and events flow when `optedIn == true`.

`CrashReportingService` follows the exact same pattern with `Sentry`.

---

## 2. The `Surface` enum

Every event is tagged with the **capture surface** so per-surface latency can
be distinguished. Mirrored across Swift and Kotlin:

| Surface          | Where it fires                                                    |
|------------------|-------------------------------------------------------------------|
| `.app`           | Main app composer / action sheet                                  |
| `.shareExtension`| iOS Share Extension save                                          |
| `.watch`         | watchOS composer (voice or text)                                  |
| `.complication`  | Apple Watch complication tap → composer                           |
| `.tile`          | Android Quick Settings tile / Wear tile launch                    |

Adding a sixth surface (e.g. a future iOS WidgetKit interactive widget) means:
add a case to `Surface` in both `shared/CardCore/Sources/CardCore/Observability/`
and `android/core/src/main/java/com/americangroupllc/card/core/obs/`.

---

## 3. Event taxonomy (v1)

| Event                | Properties                                | Fired by                          |
|----------------------|-------------------------------------------|-----------------------------------|
| `card_captured`      | `surface`, `kind` (note/task/reminder)    | every successful save             |
| `card_converted`     | `from_kind`, `to_kind`                    | action sheet                      |
| `reminder_scheduled` | `surface`, `delay_minutes`                | `ReminderService` schedule call   |
| `reminder_fired`     | `surface`                                 | OS notification handler           |
| `card_deleted`       | `kind`                                    | swipe-to-delete                   |
| `settings_toggled`   | `name`, `enabled`                         | settings screen                   |
| `onboarding_completed` | —                                       | last onboarding page              |

Events are **not** fired when `optedIn == false`. There is also no buffering —
opting in mid-session does not flush historical events.

---

## 4. Crash reports

`CrashReportingService` exposes two methods:

- `capture(error: Error)` — for caught throws / `Result.failure`.
- `capture(message: String)` — for invariant-violation log lines.

Use these sparingly. The point of Sentry on Card is to catch storage
corruption (JSON decode failures, Room migration errors) and reminder
scheduling failures, **not** to replace `print` debugging.

---

## 5. Wiring it up

### Apple

```swift
// In AppDelegate.application(_:didFinishLaunchingWithOptions:)

#if canImport(PostHog)
if let key = ProcessInfo.processInfo.environment["POSTHOG_API_KEY"], !key.isEmpty {
    AnalyticsService.shared.usePostHog(
        apiKey: key,
        host: ProcessInfo.processInfo.environment["POSTHOG_HOST"] ?? "https://us.i.posthog.com"
    )
}
#endif

#if canImport(Sentry)
if let dsn = ProcessInfo.processInfo.environment["SENTRY_DSN"], !dsn.isEmpty {
    CrashReportingService.shared.useSentry(dsn: dsn)
}
#endif

// User-facing toggles drive opt-in:
AnalyticsService.shared.optedIn = settings.analyticsOptedIn
CrashReportingService.shared.optedIn = settings.crashOptedIn
```

### Android

```kotlin
// In CardApplication.onCreate()

BuildConfig.SENTRY_DSN.takeIf { it.isNotEmpty() }?.let { dsn ->
    // when Sentry SDK is present:
    // CrashReportingService.shared.attach(SentryTransport(dsn))
}

BuildConfig.POSTHOG_API_KEY.takeIf { it.isNotEmpty() }?.let { key ->
    // PostHog Android setup
    // AnalyticsService.shared.attach(PostHogTransport(key))
}
```

The actual SDK installation steps live in `SENTRY.md` (the same file covers
PostHog because the wiring is symmetric).
