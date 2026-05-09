# Pocket — 5-Minute Quick-Start

Each platform fits on one screen. Pick what you have a machine for.

| Platform | OS you need | Time |
|---|---|---|
| 🌐 **Marketing site** | any | 30 sec |
| 🍎 **iOS app** | macOS only | 5 min |
| ⌚ **watchOS app** | macOS only | 5 min |
| 🤖 **Android phone app** | macOS / Linux / Windows | 5 min |
| ⌚ **Wear OS app** | macOS / Linux / Windows | 5 min |

For deeper testing scenarios see [`TESTING.md`](./TESTING.md). For releases see [`RELEASING.md`](./RELEASING.md).

---

## 🌐 Marketing site — 30 seconds

1. **Open** `index.html` in any browser.

That's it. No build step, no server. Animations + table + live hero clock all work standalone.

---

## 🍎 iOS app — 5 minutes (macOS only)

**Prereqs**: macOS · Xcode 15+ · Homebrew. Free Apple ID is fine for simulator-only.

```bash
brew install xcodegen
cd ios
xcodegen generate
open Pocket.xcodeproj
```

In Xcode:
1. Edit **`ios/project.yml`** → set `DEVELOPMENT_TEAM` to your 10-char Apple Team ID (or leave blank for simulator only).
2. Pick scheme **Pocket** + an **iPhone 15** simulator.
3. ▶️ Run.

**First screen** = Onboarding (3 pages: Welcome → Permissions → Done) → Tab bar (Clock · World · Alarm · Stopwatch · Timer · Bedtime · Settings).

**Troubleshooting**: "No such module 'PocketCore'" → Xcode → File → Packages → Reset Package Caches.

For one-line build-+-launch:
```bash
./scripts/run-ios-sim.sh
```

---

## ⌚ watchOS app — 5 minutes (macOS only)

```bash
brew install xcodegen
cd watchos
xcodegen generate
open PocketWatch.xcodeproj
```

In Xcode:
1. Pick scheme **PocketWatch** + an **Apple Watch Series 10 (46mm)** simulator (watchOS 10+).
2. ▶️ Run.

**Pages (swipe up)**: Clock → World → Stopwatch → Timer → Bedtime → Settings.
**Complication**: long-press a watch face → Edit → add **NextAlarm**.

For real-device testing pair an Apple Watch via the iOS Watch app, set the same `DEVELOPMENT_TEAM` in `watchos/project.yml`, and run on device.

---

## 🤖 Android phone app — 5 minutes

**Prereqs**: JDK 17 + Android Studio Hedgehog or newer (or just `cmdline-tools` + an SDK).

```bash
cd android
# First time only — generates the gradle wrapper:
gradle wrapper --gradle-version 8.10
chmod +x gradlew

./gradlew :app:installDebug   # installs on connected emulator/device
```

Or open `android/` in **Android Studio** → "Sync Project" → ▶️ on a Pixel emulator.

**First screen** = Onboarding (Welcome → notification permission → Done) → Bottom nav: Clock · World · Alarm · Stopwatch · Timer · Bedtime · Settings.

**Troubleshooting**:
- `SDK location not found` → set `local.properties` with `sdk.dir=/path/to/Android/sdk`.
- Notifications never fire → on Android 13+ the OS asks for `POST_NOTIFICATIONS` once at first launch; revoke + reinstall to retest.

For one-line boot-emulator-+-launch:
```bash
ANDROID_HOME=/path/to/sdk ./scripts/run-android-emulator.sh
```

---

## ⌚ Wear OS app — 5 minutes

**Prereqs**: same as Android phone + a Wear OS AVD created in Android Studio.

```bash
cd android
./gradlew :wear:installDebug
```

**Pages (swipe up)**: Clock → World → Stopwatch → Timer → Bedtime → Settings.
**Watch face** → long-press → **Add complication** → Pocket Next Alarm.
**Tile** → swipe right from face → Pocket tile.

For one-line:
```bash
WEAR_AVD_NAME=Wear_Round_API_33 ./scripts/run-wear-emulator.sh
```

---

## 🧪 Run every test on your machine — 1 line

```bash
./scripts/test-all.sh
```

Runs every suite available on the current OS:
- Android `:core:test*` + `:app:test*` + `:wear:test*` (if Gradle installed)
- PocketCore Swift Package tests + iOS sim build + watchOS sim build (if on macOS with Xcode + xcodegen)
- Marketing site lint (if `npx` available)

Skips suites that need tooling you don't have.

---

## 🚀 Cut a release — 2 lines

```bash
./scripts/bump-version.sh 1.0.0
git commit -am "chore(release): v1.0.0" && git tag v1.0.0 && git push origin main v1.0.0
```

GitHub Actions does the rest:
- Builds APK + AAB + Wear APK + iOS sim .app + watchOS sim .app + marketing zip
- Creates a **GitHub Release** at `v1.0.0` with auto-changelog and all artefacts
- Optionally uploads the AAB to **Google Play Store** if `PLAY_STORE_SERVICE_ACCOUNT_JSON` secret is set
- Optionally uploads a signed iOS .ipa to **TestFlight** if `APP_STORE_CONNECT_API_KEY_P8_BASE64` is set

See [`RELEASING.md`](./RELEASING.md) for the full setup.

---

## 🆘 Help

- **Architecture & data flow**: [`DESIGN.md`](./DESIGN.md)
- **Sanity-test walkthroughs per feature**: [`TESTING.md`](./TESTING.md)
- **Releases + Play Store + TestFlight**: [`RELEASING.md`](./RELEASING.md)
- **iOS code-signing**: [`ios/SIGNING.md`](./ios/SIGNING.md)
- **Production gap audit + 3-week polish list**: [`PRODUCTION.md`](./PRODUCTION.md)
- **Privacy posture**: [`PRIVACY.md`](./PRIVACY.md)
