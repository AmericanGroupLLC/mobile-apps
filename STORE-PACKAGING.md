# STORE-PACKAGING.md

How BuddyPlay v1 ships to the App Store and Google Play.

## §1 — App Store (iPhone)

| Field | Value |
|---|---|
| Display name | BuddyPlay |
| Bundle ID | `com.americangroupllc.buddyplay` |
| Min OS | iOS 17 |
| Devices | iPhone (no iPad-specific layout in v1) |
| Category | Games |
| Subcategory | Board / Card |
| Age rating | 4+ (no UGC, no chat, no IAP, no ads) |

### Capabilities used

- **Bluetooth (always)** — `bluetooth-central` + `bluetooth-peripheral`
  background modes are NOT enabled in v1 (foreground play only).
- **Bonjour services** — declared in `Info.plist`'s `NSBonjourServices`
  array as `_buddyplay._tcp`.
- **Local Network usage** — `NSLocalNetworkUsageDescription` rationale
  string presented to user on first Host/Join action.

### NOT used

- Push notifications (no APS entitlement).
- App Groups (single-app, single-process).
- HealthKit, Contacts, Camera, Microphone, Location, Photos.
- In-App Purchase (no StoreKit dependency in v1).
- Sign in with Apple (no accounts).
- Family Sharing — N/A (no IAPs).

### Privacy nutrition label

| Section | v1 |
|---|---|
| Data Used to Track You | None |
| Data Linked to You | None |
| Data Not Linked to You | None |

There is genuinely no data sent to any server.

### App Review notes

> BuddyPlay is an offline multiplayer hub. To test the full experience,
> two devices on the same Wi-Fi network are required. A solo Demo Mode is
> available from Settings → Demo Match for review purposes; it spins up an
> in-process mock peer.

(The Demo Mode is NOT user-facing in production builds — it's behind an
`#if DEBUG` gate plus a build-config flag flipped on for App Review only.)

## §2 — Google Play (Android)

| Field | Value |
|---|---|
| Application label | BuddyPlay |
| Package | `com.americangroupllc.buddyplay` |
| `minSdkVersion` | 26 (Android 8) |
| `targetSdkVersion` | 34 (Android 14) |
| Category | Games → Board |
| Content rating | Everyone |
| Ads | None |
| In-app purchases | None |

### Permissions declared

See `CONNECTIVITY.md §9`. Summary: Bluetooth scan/connect/advertise + Wi-Fi
state + nearby Wi-Fi (API 33+) only. **No camera, no mic, no location on
modern Android, no notifications.**

### Data safety form

| Question | Answer |
|---|---|
| Does your app collect or share any user data? | **No** |
| Does your app encrypt data in transit? | N/A (no internet traffic) |
| Can users request deletion? | N/A (no remote data; "Erase all rivalries" wipes local store) |

### Play Console release tracks

`release.yml` routes by tag suffix:
- `vX.Y.Z`              → production
- `vX.Y.Z-rc.N`         → beta
- `vX.Y.Z-beta.N`       → beta
- `vX.Y.Z-alpha.N`      → alpha
- `vX.Y.Z-internal.N`   → internal

## §3 — Marketing assets

Per-store screenshots live in `distribution/screenshots/<platform>/<lang>/`
(not committed; generated on demand from Simulator / Emulator). Required:

- iOS: 6.7" (iPhone 16 Pro Max), 6.5" (iPhone 11 Pro Max), 5.5" (iPhone 8 Plus).
- Android: phone (1080×1920) — minimum 2, maximum 8.

## §4 — What's new

`distribution/whatsnew/whatsnew-en-US/whatsnew.txt` is uploaded by
`release.yml` as the Play Store release notes. Keep it under 500 chars.

## §5 — Bundle size budget

See `PRODUCTION.md §7`.

## §6 — Why no Watch / Wear tier

Out of scope for v1. Watch UX needs a partner watch *and* phone, and our
target use case (two phones nearby) doesn't benefit. Revisit in v2 only
on demand.
