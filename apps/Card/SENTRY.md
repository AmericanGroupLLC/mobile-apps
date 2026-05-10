# Card — SENTRY (and PostHog) install

The wrappers in `shared/CardCore/Sources/CardCore/Observability/` and
`android/core/.../core/obs/` are `canImport`-gated — they no-op when the SDKs
aren't on the classpath. This file is the actual install steps for when you
decide to wire them up. See [`OBSERVABILITY.md`](OBSERVABILITY.md) for the
contract these SDKs implement.

---

## 1. iOS / watchOS Sentry

```bash
# In ios/ (and copy the same to watchos/ if you want the watch covered too)
# Edit ios/project.yml — add Sentry as a SwiftPM dependency

packages:
  CardCore:
    path: ../shared/CardCore
  Sentry:
    url: https://github.com/getsentry/sentry-cocoa.git
    from: 8.30.0
```

Then add `Sentry` as a dependency on the `Card` target:

```yaml
targets:
  Card:
    dependencies:
      - package: CardCore
        product: CardCore
      - package: Sentry
        product: Sentry
```

Re-run `xcodegen generate`. The `#if canImport(Sentry)` blocks in
`CrashReportingService.swift` will now compile in.

Set `SENTRY_DSN` as a GitHub Secret; `release.yml` already passes it through
to the build environment. The runtime opts in via the user settings toggle.

---

## 2. iOS / watchOS PostHog

Same shape:

```yaml
packages:
  CardCore:
    path: ../shared/CardCore
  PostHog:
    url: https://github.com/PostHog/posthog-ios.git
    from: 3.10.0
```

Add `PostHog` as a target dependency, re-run `xcodegen generate`.

`shared/CardCore/Sources/CardCore/Observability/AnalyticsService.swift` already
has the `#if canImport(PostHog)` extension; nothing else needs to change.

---

## 3. Android Sentry

```kotlin
// android/app/build.gradle.kts
plugins {
    id("io.sentry.android.gradle") version "4.11.0"
}

dependencies {
    implementation("io.sentry:sentry-android:7.13.0")
}
```

Add a `sentry { … }` block:

```kotlin
sentry {
    autoUploadProguardMapping.set(false)
    autoInstallation.enabled.set(false)
    includeProguardMapping.set(false)
}
```

Then in `CardApplication.onCreate()`:

```kotlin
val dsn = BuildConfig.SENTRY_DSN
if (dsn.isNotBlank()) {
    SentryAndroid.init(this) { options ->
        options.dsn = dsn
        options.environment = BuildConfig.BUILD_TYPE
    }
    CrashReportingService.shared.attach(object : CrashTransport {
        override fun capture(throwable: Throwable) { Sentry.captureException(throwable) }
        override fun capture(message: String)      { Sentry.captureMessage(message) }
    })
}
```

Then in your `:app:build.gradle.kts`, expose the secret to BuildConfig:

```kotlin
android {
    defaultConfig {
        buildConfigField("String", "SENTRY_DSN", "\"${System.getenv("SENTRY_DSN") ?: ""}\"")
    }
    buildFeatures { buildConfig = true }
}
```

`release.yml` already plumbs `SENTRY_DSN` (and `SENTRY_DSN_WEAR` for the wear
module) through as env vars during the release build.

---

## 4. Android PostHog

```kotlin
dependencies {
    implementation("com.posthog:posthog-android:3.7.0")
}
```

Then in `CardApplication.onCreate()`:

```kotlin
val key = BuildConfig.POSTHOG_API_KEY
if (key.isNotBlank()) {
    val cfg = PostHogAndroidConfig(apiKey = key, host = BuildConfig.POSTHOG_HOST)
    PostHogAndroid.setup(this, cfg)
    AnalyticsService.shared.attach(object : AnalyticsTransport {
        override fun track(name: String, properties: Map<String, String>) {
            PostHog.capture(name, properties = properties)
        }
    })
}
```

Mirror the `buildConfigField` lines for `POSTHOG_API_KEY` and `POSTHOG_HOST`.

---

## 5. Verification

Once the SDKs are wired, run the iOS app + Android app + Wear app on real
devices, toggle the opt-ins from Settings, and check:

- Sentry: throw a test exception from a hidden debug menu (or set
  `SENTRY_DSN` to your dev project, capture a single message at launch).
- PostHog: capture `card_captured` from the composer; verify the event in the
  PostHog dashboard within 60 seconds.

If neither shows up, the wrapper is no-oping — the most likely cause is
`optedIn == false` (the user must flip the Settings toggle).

---

## 6. Why this isn't on by default

Card's privacy contract says nothing leaves the device unless the user opts
in. Shipping the SDKs without a hard opt-in would:

- Force a "we're tracking you" disclosure on first launch.
- Trigger Apple's privacy-nutrition-label "Data Linked to You" requirement
  even if you're only tracking session counts.
- Make the app feel like every other one in the category.

The wrapper pattern keeps the door open without ever opening it for the user.
