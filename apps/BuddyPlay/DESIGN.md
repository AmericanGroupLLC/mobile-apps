# BuddyPlay — Design

## Pitch

BuddyPlay is an **offline multiplayer mini-games hub**. Two phones nearby
discover each other over Wi-Fi, Mobile Hotspot, or Bluetooth LE — no internet,
no accounts, no servers. v1 ships three games: **Royal Chess**, **Dice Kingdom**
(Ludo-style), and **Mini Racer**. The 2-player sub-mode is named **DuoPlay**.

## Brand

- **App name**: BuddyPlay
- **Tagline**: *Play anywhere. No internet needed.*
- **Sub-mode for 2P games**: DuoPlay
- **Palette**: deep slate (`#0E1A2B`) + warm coral accent (`#FF6F61`).

## Repo map

```
shared/BuddyCore/          Swift Package: models, domain helpers, connectivity
                           adapters, storage, observability stubs, tests.
ios/                       SwiftUI iPhone app (XcodeGen-generated project).
android/                   Multi-module Gradle build:
                             :core    pure-Kotlin/JVM mirror of BuddyCore.
                             :app     Compose phone app + Android-API-bound
                                      connectivity adapters.
.github/workflows/         6 CI workflows. No backend.
scripts/                   Local helpers (test-all, run-*-emulator, bump-version,
                           release-dry-run).
distribution/whatsnew/     Per-locale Play Store whatsnew text.
index.html, styles.css,    Marketing one-pager.
script.js, robots.txt,
sitemap.xml
```

## Layered architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│ UI                  iOS SwiftUI                Android Compose       │
│                     ──────────                 ───────────────       │
│                     HomeScreen                 HomeScreen             │
│                     Lobby (Host/Join)          Lobby                  │
│                     Chess / Ludo / Racer       Chess / Ludo / Racer  │
│                     Rivalries / Settings       Rivalries / Settings  │
├──────────────────────────────────────────────────────────────────────┤
│ App services        ConnectivityService        ConnectivityViewModel │
│                     GameSessionService         GameSessionService    │
│                     SettingsModel              SettingsRepo          │
├──────────────────────────────────────────────────────────────────────┤
│ Shared domain       BuddyCore (Swift)          :core (Kotlin/JVM)    │
│ (mirrored 1:1)      ────────────────           ──────────────────    │
│                     Models                     Models                 │
│                     HostElection               HostElection           │
│                     WireCodec                  WireCodec              │
│                     GameStateReducer           GameStateReducer       │
│                     ChessRules                 ChessRules             │
│                     LudoRules                  LudoRules              │
│                     RacerPhysics               RacerPhysics           │
│                     LocalRivalryStore          LocalRivalryStore      │
│                     DeviceIdProvider           DeviceIdProvider       │
├──────────────────────────────────────────────────────────────────────┤
│ Connectivity        WifiTransport (NW.Socket)  WifiTcpTransport      │
│ adapters            BleTransport (CoreBT)      BleTransport (GATT)   │
│                     DiscoveryService (Bonjour) NsdDiscovery (NSD)    │
│                     HotspotAdvisor             HotspotAdvisor        │
└──────────────────────────────────────────────────────────────────────┘
```

The shared-domain layer is pure: no platform APIs, fully unit-tested. Every
keystone helper has an XCTest **and** a JUnit twin so behaviour cannot drift
between the two implementations.

## Per-platform stack

| | iPhone | Android |
|---|---|---|
| Language | Swift 5.9 | Kotlin 1.9 |
| UI framework | SwiftUI | Jetpack Compose |
| Min OS | iOS 17 | API 26 (Android 8) |
| Project generator | XcodeGen (`ios/project.yml`) | Gradle (`build.gradle.kts`) |
| DI | manual (env objects) | Hilt |
| Storage | `UserDefaults` + JSON-on-disk | DataStore + JSON-on-disk |
| Local network | `Network.framework` (NWBrowser/NWConnection) | `NsdManager` + `Socket` |
| Bluetooth | `CoreBluetooth` | `BluetoothGattServer` + `BluetoothLeScanner` |
| Build automation | `xcodebuild` via scripts/CI | `./gradlew` via scripts/CI |

## Connectivity ladder

See [`CONNECTIVITY.md`](CONNECTIVITY.md) for the full spec. Summary: try Wi-Fi
first (NSD/Bonjour + raw TCP), then Mobile Hotspot (same path), then BLE GATT
fallback. Mini Racer rejects BLE and surfaces a "needs Wi-Fi or Hotspot" toast.

## Telemetry

**None in v1.** No Sentry, no PostHog, no analytics SDKs are pulled in.
`canImport`-gated stubs exist (`AnalyticsService`, `CrashReportingService`)
so v1.1 can opt in trivially without an architecture change.

## Backend

**None.** All state is local. The `LocalRivalryStore` is the only persistent
data; it lives in a single JSON file in the app's documents directory.

## Domain model

| Type | Notes |
|---|---|
| `Peer` | UUID, displayName, platform, lastSeenAt. |
| `GameKind` | enum: `chess`, `ludo`, `racer`. Extensible. |
| `GameSession` | id, kind, host, guest, transport, startedAt. |
| `Rivalry` | opponentId, opponentName, perGame: `[GameKind: Record]`. |
| `WireFrame` | versioned envelope (`v: 1`) wrapping every payload. |

## Why no Wi-Fi Direct?

Android-only API (`WifiP2pManager`); brittle interop. Mobile Hotspot covers
the same use case with a clean cross-platform path. Revisit in v2.

## Why no foreground service / background mode?

v1 is a same-room synchronous experience: app is always foregrounded during
play. No need to maintain connections in the background. v1.1 may add a
background-resume hint when both peers are still on the same Wi-Fi.
