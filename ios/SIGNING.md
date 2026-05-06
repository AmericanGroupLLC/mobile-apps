# Drift — iOS code-signing

Notes on getting the Drift iOS app + Notification Service Extension to
build with code-signing both locally and in CI.

## 1. Local development (free Apple ID)

A free Apple ID can sign for the iPhone Simulator (no entitlements
needed) and for a single tethered device (no APNs entitlements). For
APNs + App Group during dev:

1. Open `Drift.xcodeproj` in Xcode.
2. Select the **Drift** target → Signing & Capabilities.
3. Pick your team. Xcode will create an "Automatic Provisioning Profile"
   for `com.americangroupllc.drift`.
4. Repeat for **DriftNotificationService** with bundle id
   `com.americangroupllc.drift.notify`.
5. Both targets must opt into the **App Groups** capability with the same
   group identifier `group.com.americangroupllc.drift`. Otherwise the
   notification extension can't read the local cache.

## 2. Entitlements files

- `Drift/Resources/Drift.entitlements`
- `DriftNotificationService/DriftNotificationService.entitlements`

Both declare the App Group. The main app additionally declares
`aps-environment`.

## 3. CI signing (Fastlane Match + App Store Connect API)

`release.yml` uses **Fastlane Match** (free, OSS) to sync
provisioning profiles from a private git repo. Required GitHub Secrets:

- `MATCH_GIT_URL` — git remote (SSH) where Match stores certs/profiles
- `MATCH_PASSWORD` — passphrase that decrypts the Match repo
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8_BASE64` — base64 of the .p8 file
- `APPLE_TEAM_ID`

When any of these secrets are absent, the relevant CI step **skips
gracefully** rather than failing. See `release.yml` § publish-testflight.

## 4. App Store Connect: bundle IDs you need to register

Before the first TestFlight upload, register all four bundle IDs in App
Store Connect → Certificates, Identifiers & Profiles → Identifiers:

- `com.americangroupllc.drift`
- `com.americangroupllc.drift.notify`
- `com.americangroupllc.drift.watchkitapp` (registered later when the
  watch project is embedded into the iOS .ipa — see
  [`../STORE-PACKAGING.md`](../STORE-PACKAGING.md) §1)
- `com.americangroupllc.drift.complication`

## 5. Push certificate

Push uses the App Store Connect API key (above) — no .p12 / .p8 push
cert required. The Notification Service Extension shares the same APNs
config as the main app via the App Group + same team.
