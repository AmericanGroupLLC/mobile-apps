# Signing — BuddyPlay

This document lists every secret used by the release pipeline and the
exact code-signing wiring for each platform. Workflows degrade
gracefully when secrets are absent (Android → unsigned APK; iOS →
unsigned Simulator `.app.zip`; Desktop → unsigned binaries).

See the canonical secret reference in the umbrella repo:
<https://github.com/AmericanGroupLLC/AmericanGroupLLC/blob/main/SECRETS.md>

---

## Android

| Secret                          | Required | Purpose                  |
|---------------------------------|:-:|----------------------------------|
| `ANDROID_KEYSTORE_BASE64`     | optional | Base64-encoded `upload.jks` |
| `ANDROID_KEYSTORE_PASSWORD`   | optional | Keystore password         |
| `ANDROID_KEY_ALIAS`           | optional | Key alias                 |
| `ANDROID_KEY_PASSWORD`        | optional | Key password              |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | optional | Google Play upload   |
| `PLAY_STORE_PACKAGE_NAME`     | optional | Play Console package      |

A template is at `keystore.properties.example`.

---

## iOS

The build-ios job takes one of two paths based on whether
`APPLE_CERTIFICATE_BASE64` is set:

- **Set** → import .p12 to a temp keychain, install the
  provisioning profile, archive `-sdk iphoneos`, generate
  `exportOptions.plist` from `release.config.json.bundleId`
  (overridable via `APPLE_BUNDLE_ID`), `xcodebuild -exportArchive`,
  attach `<AppSlug>-iOS-<version>.ipa` to the GitHub Release.
- **Unset** → unsigned `-sdk iphonesimulator` build attached as
  `<AppSlug>-iOS-<version>-Simulator.app.zip` (Simulator-only,
  cannot run on real devices).

| Secret                                  | Required | Purpose            |
|-----------------------------------------|:-:|----------------------------|
| `APPLE_CERTIFICATE_BASE64`            | optional | .p12 (Distribution) |
| `APPLE_CERTIFICATE_PASSWORD`          | optional | .p12 password       |
| `APPLE_KEYCHAIN_PASSWORD`             | optional | Temp keychain pw    |
| `APPLE_PROVISIONING_PROFILE_BASE64`   | optional | Wildcard mobileprovision (recommended for (none)) |
| `APPLE_TEAM_ID`                       | optional | 10-char team ID     |
| `APPLE_BUNDLE_ID`                     | optional | Override the default bundle id (`com.americangroupllc.buddyplay`) |
| `APP_STORE_CONNECT_API_KEY_ID`        | optional | TestFlight upload   |
| `APP_STORE_CONNECT_API_ISSUER_ID`     | optional | TestFlight upload   |
| `APP_STORE_CONNECT_API_KEY_P8_BASE64` | optional | TestFlight upload   |

### Provisioning profile shape

The default bundle ID is `com.americangroupllc.buddyplay`. Because this app ships with
extensions (`(none)`), use a **wildcard** profile such as
`com.americangroupllc.buddyplay.*` so the profile covers the host app and every
extension target. App Store Connect requires explicit IDs for each
target, but the *upload step* is gated by a separate secret and only
runs after the .ipa is built.

---

## Desktop

The desktop build job runs on Ubuntu and produces:

- Windows NSIS installer `*.exe` (signed only if you add Windows
  Authenticode in a follow-up — out of scope here).
- Linux AppImage (unsigned, portable, no install required).
- macOS .dmg (**unsigned**; Gatekeeper will block on first launch.
  See `STORE-PACKAGING.md` for the `xattr -cr` bypass and the
  notarization roadmap).

---

## watchOS

The release job builds watchOS as a **standalone Simulator .app.zip**
for QA. Submitting a watch app to the App Store requires the watch
target to be embedded inside the iOS `.ipa` (watch2-app pattern),
which kicks in automatically once `APPLE_CERTIFICATE_BASE64` is set
and the Xcode project's iOS target depends on the watch target.
