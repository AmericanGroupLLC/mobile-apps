# BuddyPlay — iOS code-signing

Notes on getting the BuddyPlay iOS app to build with code-signing both
locally and in CI.

## 1. Local development (free Apple ID)

A free Apple ID can sign for the iPhone Simulator (no entitlements needed)
and for a single tethered device.

1. Open `BuddyPlay.xcodeproj` in Xcode.
2. Select the **BuddyPlay** target → Signing & Capabilities.
3. Pick your team. Xcode will create an "Automatic Provisioning Profile"
   for `com.americangroupllc.buddyplay`.

No App Group, no APNs, no extension targets in v1 — signing is the simplest
case.

## 2. Entitlements

`BuddyPlay/Resources/BuddyPlay.entitlements` is empty in v1 (no APNs, no
App Group, no push). The Bluetooth + Local Network permissions live in
`Info.plist` as usage-description strings only.

## 3. CI signing (Fastlane Match + App Store Connect API)

`release.yml` uses **Fastlane Match** (free, OSS) to sync provisioning
profiles from a private git repo. Required GitHub Secrets:

- `MATCH_GIT_URL` — git remote (SSH) where Match stores certs/profiles
- `MATCH_PASSWORD` — passphrase that decrypts the Match repo
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8_BASE64` — base64 of the .p8 file
- `APPLE_TEAM_ID`

When any of these secrets are absent, the relevant CI step **skips
gracefully** rather than failing. See `release.yml` § publish-testflight.

## 4. App Store Connect: bundle IDs you need to register

Before the first TestFlight upload, register the single bundle ID in App
Store Connect → Certificates, Identifiers & Profiles → Identifiers:

- `com.americangroupllc.buddyplay`

(No notification service, no widget, no watch app in v1 — only one entry.)
