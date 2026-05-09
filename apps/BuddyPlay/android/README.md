# BuddyPlay — Android

Multi-module Gradle: `:core` (pure-Kotlin/JVM, shared logic), `:app` (phone).

## Build

```sh
cd android
./gradlew :core:test                # pure-Kotlin/JVM tests — NOT testDebugUnitTest
./gradlew :app:lintDebug :app:testDebugUnitTest :app:assembleDebug
./gradlew :app:connectedDebugAndroidTest    # Compose UI smoke (needs emulator)
```

Or use the shell helper:

```sh
../scripts/run-android-emulator.sh
./gradlew :app:installDebug
```

## Application ID

- `com.americangroupllc.buddyplay` (phone, only target)

## Permissions

`:app/AndroidManifest.xml` declares:

- `INTERNET` (BLE peripheral library sometimes wants it during pairing; ad SDK lands later)
- `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT` + `BLUETOOTH_ADVERTISE` (API 31+)
- `BLUETOOTH` + `BLUETOOTH_ADMIN` (API ≤30 fallback)
- `ACCESS_FINE_LOCATION` (API ≤30, gated by `usesPermissionFlags="neverForLocation"` on 31+)
- `NEARBY_WIFI_DEVICES` (API 33+)
- `ACCESS_WIFI_STATE` + `CHANGE_WIFI_STATE`

**No camera, no microphone, no foreground service, no notifications, no location on modern Android.**

## Where things live

```
android/core/                                 pure-Kotlin/JVM (NO Android deps)
  src/main/java/com/americangroupllc/buddyplay/core/
    models/                                   Peer, GameKind, GameSession, Rivalry, Transport, WireFrame
    domain/                                   HostElection, WireCodec, GameStateReducer, ChessRules, LudoRules, RacerPhysics
    storage/                                  LocalRivalryStore (JVM-friendly), DeviceIdProvider (interface)
    connectivity/                             BuddyTransport interface, DiscoveredPeer, ConnectivityBridge
    observability/                            AnalyticsService, CrashReportingService

android/app/                                  phone app
  src/main/java/com/americangroupllc/buddyplay/
    BuddyApplication.kt  MainActivity.kt  ui/RootNav.kt
    home/   lobby/   rivalries/   settings/
    games/chess/  games/ludo/  games/racer/
    connectivity/                             Android-API-bound transports
    data/   di/AppModule.kt
```

## Module rules

- `:core` is **JVM-only**. No Android dependencies. Unit tests run via
  `:core:test`, **not** `:core:testDebugUnitTest`.
- `:app` depends on `:core` and applies the Compose plugin.
- The Compose BOM is applied to **both** `implementation(...)` and
  `androidTestImplementation(...)` so `compose.ui:ui-test-junit4` resolves
  with a matching version. Removing it from one breaks the
  Compose smoke test.

## Hilt + DataStore

- DI: Hilt. The `:app` `AppModule.kt` provides `ConnectivityService`,
  `LocalRivalryStore`, `DeviceIdProvider`, `SettingsRepo`, `SfxService`.
- Local store: DataStore for user preferences + a single JSON file for the
  rivalries (no Room — the data shape is too small to justify a DB).
