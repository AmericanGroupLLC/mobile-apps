# Pocket — Sentry

> Optional, opt-in crash reporting. Stubs ship today. Real SDK install is a
> 2-line change per platform plus DSN secrets.

## Wiring per platform

### iOS / watchOS

The wrapper lives in `shared/PocketCore/Sources/PocketCore/CrashReportingService.swift`:

```swift
public enum Crash {
    public static func start(dsn: String?) { /* canImport(Sentry) gate */ }
    public static func report(_ error: Error) { /* no-op until enabled */ }
}
```

To enable for real:

1. Add `https://github.com/getsentry/sentry-cocoa` (`from: "8.0.0"`) to
   `shared/PocketCore/Package.swift`.
2. Set repo Secret `SENTRY_DSN_IOS` (and `SENTRY_DSN_WEAR` for the watch app
   if you want a separate Sentry project).
3. Re-run `./scripts/release-dry-run.sh v0.1.0-rc1` locally to verify no
   compile errors with the SDK linked.

The DSN is pulled at runtime via `ProcessInfo.environment["SENTRY_DSN"]` — never compiled into a constant — so a fork without the secret simply ships the no-op path.

### Android phone / Wear

Wrappers live in `android/core/src/main/.../CrashReportingService.kt`:

```kotlin
object Crash {
    fun start(context: Context, dsn: String?) { /* gated on dsn.isNotEmpty() */ }
    fun report(error: Throwable) { /* no-op until enabled */ }
}
```

To enable for real:

1. Add `implementation("io.sentry:sentry-android:7.+")` to both
   `android/app/build.gradle.kts` and `android/wear/build.gradle.kts`.
2. Set repo Secrets `SENTRY_DSN_ANDROID` + `SENTRY_DSN_WEAR`.
3. Re-build — `BuildConfig.SENTRY_DSN` reads the env var; the `Crash.start`
   gate flips on automatically.

## DSN secrets

| Secret name | Used by | Where set |
|---|---|---|
| `SENTRY_DSN_IOS` | iOS app, watchOS app | Repo Settings → Secrets and variables → Actions |
| `SENTRY_DSN_ANDROID` | Android phone app | same |
| `SENTRY_DSN_WEAR` | Wear OS app | same |

When any secret is unset, the matching wrapper no-ops cleanly. There are no
release blockers for shipping without Sentry.

## Privacy posture

The Sentry call is wrapped by both:

1. **A user opt-in toggle** — Settings → Privacy → Crash reports. False by default. `Crash.report(_:)` checks this flag before doing anything.
2. **An event sanitiser** — strips `event.user`, drops alarm names, timezone selections, and any breadcrumbs from the alarm-edit / world-clock flows.

What Sentry sees if both gates pass:

- Stack trace (file + line + function names from your binary).
- OS version + app version + device model.
- Anonymous event ID (per-event, not per-device).

What Sentry never sees (verified by the sanitiser):

- Alarm names, schedules, sounds.
- Timezone selections in World Clock.
- Bedtime targets / sleep duration.
- Any user identifier (email, account, IDFV, AAID).
- Foreground breadcrumbs from Settings or Bedtime.

## Verifying

1. Toggle Settings → Privacy → Crash reports **on**.
2. Trigger a deliberate crash from a debug menu (or `kill -SEGV` from Xcode).
3. Watch the event appear in your Sentry dashboard within 60 seconds.

If the event doesn't appear:
- Check that `SENTRY_DSN_*` is set in CI Secrets.
- Check that the build was a CI-produced release (the env var only flows through CI, not local builds, unless you add a local `.env`).
- Check Settings shows the toggle is on.

## Self-hosting

Sentry is open source. If 5K errors/mo is too few or you want full data
ownership, deploy your own at <https://develop.sentry.dev/self-hosted/>.
The wrapper API doesn't change — just point `SENTRY_DSN_*` at your instance.

## Related docs

- Full observability stack + alternatives: [`OBSERVABILITY.md`](./OBSERVABILITY.md)
- Privacy policy: [`PRIVACY.md`](./PRIVACY.md)
- Production-readiness checklist: [`PRODUCTION.md`](./PRODUCTION.md)
