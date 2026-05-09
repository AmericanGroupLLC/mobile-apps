# Drift — iOS

The iPhone app + Notification Service Extension live here. The watch app
is in `../watchos/`. Shared models + domain logic live in
`../shared/DriftCore/`.

## Generate the Xcode project

`Drift.xcodeproj` is generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen)
and is in `.gitignore`.

```sh
brew install xcodegen
cd ios
xcodegen generate
open Drift.xcodeproj
```

## Targets

- **Drift** — the iPhone app (SwiftUI, iOS 17+).
- **DriftNotificationService** — Notification Service Extension that
  decrypts message previews and downloads thumbnails for rich pushes.
- **DriftTests** — view-model glue tests (XCTest).
- **DriftUITests** — XCUITest smoke (onboarding stub → discover → wave →
  chat → reply suggestion picker).

## Bundle IDs

| Target | Bundle ID |
|---|---|
| Drift                       | `com.americangroupllc.drift` |
| DriftNotificationService    | `com.americangroupllc.drift.notify` |
| App Group                   | `group.com.americangroupllc.drift` |

## Permissions

Declared in `Drift/Resources/Info.plist`:

- `NSCameraUsageDescription` — selfie verification + profile photos
- `NSPhotoLibraryUsageDescription` — pick existing photos
- `NSMicrophoneUsageDescription` — 30s voice prompt
- `NSLocationWhenInUseUsageDescription` — fuzz to ZIP-3 on-device
- `NSUserNotificationsUsageDescription` — match + message pushes

**No Bluetooth, no precise-location-always.**

## Where things live

```
ios/Drift/App/                       DriftApp + RootView
ios/Drift/Features/Onboarding/       5-page onboarding (welcome → phone → photos → selfie → layers/intent)
ios/Drift/Features/Discover/         layer switcher + ProfileCard + WaveActions
ios/Drift/Features/Matches/          MatchesScreen + Realtime
ios/Drift/Features/Chat/             ChatScreen + ReplySuggestionsBar + MessageBubble
ios/Drift/Features/Profile/          ProfileScreen + EditProfileScreen + PhotoGridEditor + VoicePromptRecorder
ios/Drift/Features/Settings/         SettingsScreen
ios/Drift/Features/Safety/           ReportSheet + BlockedUsersScreen
ios/Drift/Services/                  AuthService, ProfileService, ChatService, DiscoverService, ReplyService, VerificationService, LocationService, PushService
ios/Drift/Resources/                 Info.plist, Drift.entitlements, Assets, LaunchScreen
ios/DriftNotificationService/        rich-push extension
ios/DriftTests/                      XCTest
ios/DriftUITests/                    XCUITest
ios/SIGNING.md                       code-signing notes
```

See [`SIGNING.md`](SIGNING.md) for code-signing & entitlements.
