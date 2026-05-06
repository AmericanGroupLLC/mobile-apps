# BuddyPlay — iOS

The iPhone app lives here. Shared models + domain logic live in
`../shared/BuddyCore/`.

## Generate the Xcode project

`BuddyPlay.xcodeproj` is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen)
and is in `.gitignore`.

```sh
brew install xcodegen
cd ios
xcodegen generate
open BuddyPlay.xcodeproj
```

## Targets

- **BuddyPlay** — the iPhone app (SwiftUI, iOS 17+).
- **BuddyPlayTests** — view-model glue tests (XCTest).
- **BuddyPlayUITests** — XCUITest smoke (Home → Host Chess → mock peer → first move).

## Bundle ID

| Target | Bundle ID |
|---|---|
| BuddyPlay | `com.americangroupllc.buddyplay` |

No App Group, no extensions, no notification service in v1 — single binary.

## Permissions

Declared in `BuddyPlay/Resources/Info.plist`:

- `NSBluetoothAlwaysUsageDescription` — BLE advertise + scan
- `NSLocalNetworkUsageDescription` — NWBrowser / NWConnection
- `NSBonjourServices` — array containing `_buddyplay._tcp`

**No camera, no microphone, no location, no notifications.**

## Where things live

```
ios/BuddyPlay/App/                        BuddyPlayApp + RootView
ios/BuddyPlay/Features/Home/              HomeScreen (game card scroller, DuoPlay/Party tabs)
ios/BuddyPlay/Features/Lobby/             HostLobbyScreen, JoinLobbyScreen, PairingCodeView
ios/BuddyPlay/Features/Games/Chess/       ChessScreen, ChessBoardView, ChessViewModel
ios/BuddyPlay/Features/Games/Ludo/        LudoScreen, LudoBoardView, LudoViewModel
ios/BuddyPlay/Features/Games/Racer/       RacerScreen, RacerCanvasView, RacerViewModel
ios/BuddyPlay/Features/Rivalries/         RivalriesScreen
ios/BuddyPlay/Features/Settings/          SettingsScreen
ios/BuddyPlay/Services/                   ConnectivityService, GameSessionService, SettingsModel, SfxService
ios/BuddyPlay/Resources/                  Info.plist, BuddyPlay.entitlements, Assets, LaunchScreen
ios/BuddyPlayTests/                       XCTest
ios/BuddyPlayUITests/                     XCUITest
ios/SIGNING.md                            code-signing notes
```

See [`SIGNING.md`](SIGNING.md) for code-signing & entitlements.
