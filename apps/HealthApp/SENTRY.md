# MyHealth — Sentry Crash Reporting

> **Free Developer tier · Opt-in · Privacy-first**

Sentry is wired into every platform but **off by default**. The user must
explicitly turn on "Send crash reports" in Settings, AND a DSN must be
configured at build time, before a single byte leaves the device.

---

## 1. Free tier reality check

| Plan | Cost | Errors/month | Performance events | Replays | Retention |
|---|---|---|---|---|---|
| **Developer** | **$0** | 5,000 | 10,000 | 50 | 30 days |
| Team | $26/mo | 50,000 | 100,000 | 500 | 90 days |

For early-stage apps the **free Developer tier is more than enough** — 5,000
errors/month covers thousands of MAUs at typical crash rates. Sign up at
[sentry.io/signup](https://sentry.io/signup/).

We deliberately **disable performance tracing** (`tracesSampleRate: 0`) on
every platform so quota is reserved for actual crashes.

---

## 2. Privacy posture (what gets sent and what doesn't)

| Field | Sent? |
|---|---|
| Stack trace (file, line, function) | ✅ yes |
| Device model + OS version | ✅ yes |
| App version + build | ✅ yes |
| Anonymous device ID (Sentry's `installation_id`) | ✅ yes |
| Email, name, account id | ❌ never — `sendDefaultPii: false` + `beforeSend` strips `event.user` |
| HealthKit / Health Connect data | ❌ never — never logged |
| Medicine names, doses, mood entries | ❌ never — never logged |
| Photos, screen recordings, videos | ❌ never — replays disabled |
| URL query strings or POST bodies | ❌ never — request bodies not captured |

The `beforeSend` callback on every platform strips `event.user` to belt-and-
suspenders enforce zero-PII even if a future SDK update tries to attach it.

---

## 3. Wiring per platform

### iOS / watchOS

- **Dependency**: `getsentry/sentry-cocoa` (SwiftPM, in `Package.swift`)
- **Wrapper**: [`shared/FitFusionCore/Sources/FitFusionCore/CrashReportingService.swift`](./shared/FitFusionCore/Sources/FitFusionCore/CrashReportingService.swift)
- **Boot**: `FitFusionApp.init` calls `CrashReportingService.shared.bootstrapIfEnabled(release:)`
- **DSN source** (in priority order):
  1. Env var `SENTRY_DSN` (CI / dev)
  2. `Info.plist` key `SentryDSN` (release builds; injected by xcodegen build setting)
- **User toggle**: Settings → Privacy → "Send crash reports"

### Android phone

- **Dependency**: `io.sentry:sentry-android:7.18.0` (in `app/build.gradle.kts`)
- **Wrapper**: [`android/app/src/main/java/com/myhealth/app/crash/CrashReportingService.kt`](./android/app/src/main/java/com/myhealth/app/crash/CrashReportingService.kt)
- **Boot**: `MyHealthApp.onCreate` calls `CrashReportingService.bootstrapIfEnabled(...)`
- **DSN source** (in priority order):
  1. Env var `SENTRY_DSN` (dev shell)
  2. `BuildConfig.SENTRY_DSN` (injected at build time from env var or `gradle.properties`)
- **User toggle**: Settings → Privacy → "Send crash reports (Sentry)"

### Wear OS

- Same Gradle dep declared in `wear/build.gradle.kts`
- The wrapper lives in the phone module and Wear can call it via the shared `core` library if needed
- Currently no boot init in `wear/MainActivity.kt` — most crashes will surface in the phone app anyway since the watch shares much of the data layer

### Backend (Express)

- **Dependency**: `@sentry/node` (in `server/package.json`)
- **Middleware**: [`server/middleware/sentry.js`](./server/middleware/sentry.js)
- **Boot**: `server.js` calls `Sentry.init` + `Sentry.requestHandler` first, then `Sentry.errorHandler` after all routes
- **DSN source**: `SENTRY_DSN` env var only
- **No-op safe**: middleware is a graceful shim — local dev / CI smoke runs work without `@sentry/node` installed

### Expo (React Native)

- **Dependency**: `sentry-expo` (in `mobile/package.json`)
- **Wrapper**: [`mobile/src/crash.js`](./mobile/src/crash.js)
- **Boot**: Call `bootstrapIfEnabled({ release })` from `App.js`
- **DSN source**: `EXPO_PUBLIC_SENTRY_DSN` env var (set in `eas.json` or `.env`)
- **User toggle**: AsyncStorage flag `crashReportsEnabled` (wire a toggle in Settings screen)

---

## 4. Setup steps (one-time per project)

### 4.1 Create the Sentry project

1. Sign up at [sentry.io/signup](https://sentry.io/signup/) (free)
2. Create an org (e.g. `american-group-llc`)
3. Create **5 separate projects** (one per platform — keeps quota and stack-trace symbolication isolated):
   - `myhealth-ios` (platform: iOS)
   - `myhealth-android` (platform: Android)
   - `myhealth-wear` (platform: Android)
   - `myhealth-server` (platform: Node.js)
   - `myhealth-expo` (platform: React Native)
4. Each project gives you a **DSN** that looks like:
   `https://abc123@o12345.ingest.sentry.io/67890`

### 4.2 Add the DSN as a GitHub Secret

In Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
|---|---|
| `SENTRY_DSN_IOS` | iOS project DSN |
| `SENTRY_DSN_ANDROID` | Android project DSN |
| `SENTRY_DSN_WEAR` | Wear project DSN (same as Android is fine to share quota) |
| `SENTRY_DSN_SERVER` | Server project DSN |
| `SENTRY_DSN_EXPO` | Expo project DSN |

### 4.3 Wire the secrets into release builds

In `release.yml`'s `build-android` job:

```yaml
- name: Build phone APK + AAB
  working-directory: android
  env:
    SENTRY_DSN: ${{ secrets.SENTRY_DSN_ANDROID }}
  run: ./gradlew :app:assembleRelease :app:bundleRelease
```

In `build-ios`:

```yaml
- name: Build MyHealth.app
  working-directory: ios
  env:
    SENTRY_DSN: ${{ secrets.SENTRY_DSN_IOS }}
  run: xcodebuild ...
```

For the backend: set `SENTRY_DSN` as an env var on whatever PaaS you deploy
to (Heroku, Render, Fly, etc.).

For Expo: add `EXPO_PUBLIC_SENTRY_DSN` to your EAS build profile.

---

## 5. User-visible toggle

Already wired:

| Platform | Where the toggle lives |
|---|---|
| iOS | Settings → Privacy → "Send crash reports" |
| Android | Settings → Privacy → "Send crash reports (Sentry)" |
| Expo | TODO: add toggle to mobile Settings screen |

The toggle takes effect:
- **Immediately** on iOS (SDK closes when user opts out at runtime)
- **Next launch** on Android (SDK can't be re-initialized in the same process)
- **Next launch** on Expo (same constraint)

---

## 6. Testing the wiring

```bash
# iOS — flip the toggle on, then trigger a crash:
SentrySDK.crash()

# Android — flip the toggle on, then:
throw RuntimeException("test crash")

# Backend — flip the env var on, restart, then hit a route that throws:
curl http://localhost:4000/api/test-error  # add this route locally to test
```

Within ~30 seconds the event should appear in your Sentry dashboard.

---

## 7. What's NOT done

- [ ] Expo Settings screen lacks a UI toggle (data layer is wired, just needs the React component)
- [ ] Wear OS Application class doesn't yet call `bootstrapIfEnabled` (most wear crashes will surface in the phone app anyway since the data layer is shared via `:core`)
- [ ] Source maps / dSYM upload to Sentry is not automated (manual upload from Xcode / `gradle uploadSentryNativeSymbols` task) — set up the `sentry-cli` GitHub Action when you need symbolicated crashes
