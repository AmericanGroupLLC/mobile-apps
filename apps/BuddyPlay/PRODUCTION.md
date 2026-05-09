# PRODUCTION.md

How BuddyPlay v1 behaves in the wild.

## §1 — No backend

There is no server. There are no accounts. There is no analytics pipeline.
v1 is fully offline.

Implications:
- We have no way to deprecate old clients except by relying on the
  `WireCodec` major-version mismatch toast ("Update your friend's app").
- We have no remote-config kill switch. Bugfixes ship as a normal app
  update on the App Store / Play Store.
- We have no telemetry on crashes or feature use. v1.1 will optionally
  attach Sentry behind a privacy-explicit opt-in toggle in Settings.

## §2 — Storage

Single JSON file in the app's documents directory:

| Path | iOS | Android |
|---|---|---|
| `rivalries.json` | `Documents/buddyplay/rivalries.json` | `filesDir/buddyplay/rivalries.json` |
| `device.json` | `Documents/buddyplay/device.json` | `filesDir/buddyplay/device.json` |

Both files are tiny (single-digit kilobytes even after months of play).
We do not encrypt them; an attacker with file-system access has access
to your phone anyway. Data is opaque integers (win/loss tallies) and
opponent UUIDs — no PII.

## §3 — Permissions

| Permission | iOS | Android | Why |
|---|---|---|---|
| Bluetooth | `NSBluetoothAlwaysUsageDescription` | `BLUETOOTH_*` group | BLE fallback transport. |
| Local network | `NSLocalNetworkUsageDescription` + `NSBonjourServices` | `NEARBY_WIFI_DEVICES` (33+) or `ACCESS_FINE_LOCATION` (≤30) | NSD/Bonjour scan. |
| Camera | — | — | **Not requested.** |
| Microphone | — | — | **Not requested.** |
| Notifications | — | — | **Not requested.** |
| Location | — | API ≤30 only | Required by legacy BLE scan; gated by `neverForLocation` from API 31. |

## §4 — Crash + perf

No SDK in v1. The app is small (< 25 MB on both platforms) and the surface
area is small (3 games + a lobby + connectivity). Logcat / Console.app are
the only crash signals we have until v1.1.

## §5 — Battery & data

- **Battery**: Wi-Fi is dominant; BLE is fine for hours. Mini Racer at 30 Hz
  is the heaviest workload and burns ~5–8% per hour on a Pixel 6.
- **Data**: zero cellular use. The app never reaches the internet.

## §6 — Monetisation

None in v1. `PremiumGateService` is a stub returning `unlocked = true`
unconditionally. v1.1 will:
1. Attach RevenueCat (iOS) + Google Play Billing (Android).
2. Gate Mini Racer behind a one-time IAP.
3. Optionally show ads in the lobby (cached AdMob, opt-out toggle).

Ad SDK is not pulled in for v1 to keep the .apk / .ipa under 25 MB.

## §7 — App size budget

| Surface | Target | Why |
|---|---|---|
| iOS .ipa | < 25 MB | Smaller than 30 MB so install over cellular doesn't prompt. |
| Android .aab | < 30 MB (download) | Same. |

If we exceed the budget, the suspects are: (1) game assets (sprites, sounds),
(2) ad SDK if added prematurely, (3) bundled fonts. Audit with `bundletool`
on Android and Xcode's "Generate App Size Report" on iOS.

## §8 — Cross-platform play matrix

See `CONNECTIVITY.md §7` for the matrix.

## §9 — Watch tier

Phone-only in v1. Watches add ~30% file count for negative value here:
both peers would need to be watches *and* paired phones, plus the screen is
too small for any of the three games. Revisit in v2 only if there's clear
demand.

## §10 — Push / background

Neither platform requests notification permission in v1. There are no
background modes — both peers must keep BuddyPlay foregrounded during play.
v1.1 may add a "rejoin when back in range" hint via local notifications.
