# QUICKSTART

## Prereqs

| | macOS | Linux / Windows |
|---|---|---|
| iOS | Xcode 15+, `brew install xcodegen` | n/a |
| Android | JDK 17, Android SDK 34 (`ANDROID_HOME` set) | JDK 17, Android SDK 34 |
| Marketing site | none — open `index.html` directly | none |

## 60-second iOS spin-up (macOS)

```sh
git clone git@github.com:AmericanGroupLLC/BuddyPlay.git
cd BuddyPlay
brew install xcodegen
./scripts/run-ios-sim.sh
```

This generates the `ios/BuddyPlay.xcodeproj`, builds the Debug app, boots
iPhone 15 Simulator, installs, and launches it.

## 60-second Android spin-up

```sh
cd BuddyPlay
./scripts/run-android-emulator.sh
```

Requires `ANDROID_HOME` and at least one created AVD (default name:
`Pixel_6_API_34`; override with `AVD_NAME=...`).

## Pairing two real devices

1. Both phones on the **same Wi-Fi router** (or one running a hotspot the
   other has joined).
2. Phone A: open BuddyPlay → tap a game card → **Host** → note 4-char code.
3. Phone B: open BuddyPlay → tap **Join Nearby Game** → tap the host in the
   list → confirm code.
4. Game starts.

No internet required. If Wi-Fi is unavailable the lobby auto-falls back to
BLE; turn-based games will still work, Mini Racer won't.

## Dev workflow

```sh
# Edit shared logic in shared/BuddyCore/Sources/...
# Or shared logic mirror in android/core/src/main/...

# Run every test suite locally (skips iOS on non-macOS)
./scripts/test-all.sh

# Just iOS unit tests
cd shared/BuddyCore && swift test

# Just Android unit tests
cd android && ./gradlew :core:test :app:testDebugUnitTest

# Marketing site preview
python3 -m http.server   # then http://localhost:8000
```

## Common gotchas

- **iOS Local Network prompt**: BuddyPlay surfaces it on the first Host/Join
  action, not at launch. Reject it once and the Settings → Privacy → Local
  Network toggle is the only way back.
- **Android BLE on API ≤30**: requires `ACCESS_FINE_LOCATION` even though
  we never collect location. Gated with `usesPermissionFlags="neverForLocation"`
  on API 31+ to skip the prompt entirely.
- **`:core` is JVM-only**: use `./gradlew :core:test`, NOT `:core:testDebugUnitTest`.
- **Same-version Bonjour**: both peers must be on the same `WireCodec` major
  version. v1 → v1.x is fine; v1 → v2 will toast "Update your friend's app".
