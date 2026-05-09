# MyHealth — 5-Minute Quick-Start

Each platform fits on one screen. Pick what you have a machine for.

| Platform | OS you need | Time |
|---|---|---|
| 🌐 **Marketing site** | any | 30 sec |
| 🔌 **Backend (Express + SQLite)** | macOS / Linux / Windows | 3 min |
| 📱 **Expo (Android + iOS + Web)** | macOS / Linux / Windows | 5 min |
| 🍎 **iOS app** | macOS only | 5 min |
| ⌚ **watchOS app** | macOS only | 5 min |
| 🤖 **Android phone app** | macOS / Linux / Windows | 5 min |
| ⌚ **Wear OS app** | macOS / Linux / Windows | 5 min |

For deeper testing scenarios see [`TESTING.md`](./TESTING.md). For releases see [`RELEASING.md`](./RELEASING.md).

---

## 🌐 Marketing site — 30 seconds

1. **Open** `index.html` in any browser.

That's it. No build step, no server. Tabs, gradients, smooth scrolling all work standalone.

---

## 🔌 Backend (Express + SQLite) — 3 minutes

**Prereqs**: Node.js ≥ 18.

```bash
cd server
cp .env.example .env
# Edit .env: set JWT_SECRET to any 32-char random string.
# On Windows over a network share, point DB_PATH to a local temp dir
# (e.g. C:\Users\you\AppData\Local\Temp\myhealth.db) — SQLite WAL
# doesn't work on SMB shares.
npm install
npm run dev      # → ✅ MyHealth API listening on http://localhost:4000
```

**Verify**:
```bash
# In a second terminal:
cd server && npm run smoke
# Expected: 13 / 13 passed.
```

**Troubleshooting**: `database is locked` → move `DB_PATH` to a local-disk path.

---

## 📱 Expo (cross-platform RN) — 5 minutes

**Prereqs**: Node.js ≥ 18 + the [Expo Go](https://expo.dev/client) app on your phone.

```bash
cd mobile
npm install
npm start
```

Then:
- Press `w` for **web**
- Press `i` for **iOS simulator** (macOS only)
- Press `a` for **Android emulator**
- Or **scan the QR** with Expo Go on a real Android/iOS phone.

**First screen** = Login → tap **Continue as Guest** to skip account creation entirely.

**Troubleshooting**: blank QR → `npx expo start --tunnel` (works through restrictive networks).

---

## 🍎 iOS app — 5 minutes (macOS only)

**Prereqs**: macOS · Xcode 15+ · Homebrew. Free Apple ID is fine.

```bash
brew install xcodegen
cd ios
xcodegen generate
open FitFusion.xcodeproj
```

In Xcode:
1. Edit **`ios/project.yml`** → set `DEVELOPMENT_TEAM` to your 10-char Apple Team ID (or leave blank for simulator only).
2. Pick scheme **FitFusion** + an **iPhone 15** simulator.
3. ▶️ Run.

**First screen** = Login → **Continue as Guest** → 4-page Onboarding → Home.

**Troubleshooting**: "No such module 'FitFusionCore'" → Xcode → File → Packages → Reset Package Caches.

For one-line build-+-launch:
```bash
./scripts/run-ios-sim.sh
```

---

## ⌚ watchOS app — 5 minutes (macOS only)

**Prereqs**: same as iOS (Xcode + xcodegen).

```bash
cd watch
xcodegen generate
open HealthAppWatch.xcodeproj
```

In Xcode:
1. Pick scheme **HealthAppWatch** + an **Apple Watch Series 10 (46mm)** simulator (watchOS 11+).
2. ▶️ Run.

**Pages (swipe up)**: Quick Log → Live Workout → Run → **Anatomy** → Water → Weight → Mood → History → Settings.

For real-device testing pair an Apple Watch via the iOS Watch app, set the same `DEVELOPMENT_TEAM` in `watch/project.yml`, and run on device.

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

**First screen** = 4-page Onboarding (no login) → Bottom nav: Home · Train · Diary · Sleep · More.

**Troubleshooting**:
- `SDK location not found` → set `local.properties` with `sdk.dir=/path/to/Android/sdk`.
- Health Connect permission missing → install "Health Connect by Android" from Play Store on the emulator first.

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

**Pages (swipe up)**: Quick Log → Live Workout → Run → **Anatomy** (drills into shared `core` exercise library) → Water → Weight → Mood → History → Settings.

**Watch face** → long-press → **Add complication** → MyHealth Readiness.

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
- Backend Jest + smoke (always)
- Android `:core:test*` + `:app:test*` (if Gradle installed)
- Swift Package tests + iOS sim build (if on macOS with Xcode)
- Marketing site lint (if `npx` available)

Skips suites that need tooling you don't have.

---

## 🚀 Cut a release — 2 lines

```bash
./scripts/bump-version.sh 1.2.0
git commit -am "chore(release): v1.2.0" && git tag v1.2.0 && git push origin main v1.2.0
```

GitHub Actions does the rest:
- Builds APK + AAB + Wear APK + iOS xcarchive + server tarball + web zip
- Creates a **GitHub Release** at `v1.2.0` with auto-changelog and all artefacts
- Optionally uploads the AAB to **Google Play Store** if `PLAY_STORE_SERVICE_ACCOUNT_JSON` secret is set

See [`RELEASING.md`](./RELEASING.md) for the full setup.

---

## 🆘 Help

- **Architecture & data flow**: [`DESIGN.md`](./DESIGN.md)
- **Sanity-test walkthroughs per feature**: [`TESTING.md`](./TESTING.md)
- **Releases + Play Store + App Store**: [`RELEASING.md`](./RELEASING.md)
- **iOS code-signing**: [`ios/SIGNING.md`](./ios/SIGNING.md)
- **Drop-in `.mlmodel` files**: [`ios/FitFusion/Models/README.md`](./ios/FitFusion/Models/README.md)
- **Cross-platform JSON schema**: [`shared/schemas/README.md`](./shared/schemas/README.md)
