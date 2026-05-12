# Care+ v1.5.0 — readiness, testing & emulator runbook

> Companion to `CHANGELOG.md` v1.5.0 and `PRIVACY-CARE.md`. Answers the
> question **"Can I ship this to production?"** and gives the exact
> commands to test on each platform.

---

## TL;DR

| Track | Ready for | Blocked by |
|---|---|---|
| Internal stakeholder review (TestFlight + Play Internal Testing) | ✅ once iOS + Android builds verify locally on the right host machines | Local builds (this Windows box can only validate the backend) |
| Public TestFlight beta / Play Open Testing | ⚠️ technically yes once builds pass, but **without** the BAA closed below, do not ship any feature that calls `/api/fhir`, `/api/insurance`, or `/api/doctors` | BAA + production hosting |
| App Store / Play Production | ❌ **not yet** | Items in §1 |

---

## 1. Production gates that have NOT cleared yet

These are real blockers — most are tracked in `PRIVACY-CARE.md` §4. Until they
all close, the app should remain feature-flagged for clinical features in
release builds, or restricted to internal-only distribution.

| # | Gate | Why it blocks production | Owner |
|---|---|---|---|
| 1 | iOS `xcodebuild` clean release build on a Mac | Never been compiled — week 1 was authored on Windows | Build/CI |
| 2 | Android `./gradlew :app:assembleRelease` | Same — need JDK 17 + Android SDK + the four new deps to fetch | Build/CI |
| 3 | Backend `npm test` + `node smoke.js` green on CI | New `careplus.test.js` not yet validated on CI | Build/CI |
| 4 | **Signed BAA** with backend hosting provider (Render / Fly / AWS) | HIPAA: any PHI-storing endpoint hitting prod without one is a violation | Compliance |
| 5 | **Epic App Orchard** production credentials | Sandbox client_id can't ship; production needs per-tenant ID | Vendor |
| 6 | HIPAA compliance review of `PRIVACY-CARE.md` policy | Doc is engineering's first draft; needs sign-off | Compliance / Legal |
| 7 | Real-device QA on iPhone + Pixel (Onboarding → Care home → MyChart sandbox login → all 4 tabs) | Spec calls for click-through QA | QA |
| 8 | Production code-signing for Android | Existing `MYHEALTH-FEATURES.md` "NOT in v1" list flag | You |
| 9 | Sentry / PostHog DSNs configured for prod | Currently empty in `BuildConfig` and `.env` | You |
| 10 | App Store + Play Store metadata refresh for v1.5.0 (4-tab screenshots, what's-new) | Stores still show v1.4.0 messaging | Marketing / You |
| 11 | Real meal-vendor partner identity + sample data swap | Week-1 ships against `routes/vendor.js` stub data | Vendor |
| 12 | Ribbon Health API key (or commit to NPPES-only for v1) | Doctor finder ships on NPPES week 1; v1.1 swap point is documented | Vendor |

**Recommendation**: cut a v1.5.0-internal TestFlight + Play Internal Testing
build today **after** §1.1–1.3 pass. Hold v1.5.0 public until §1.4–1.6 close.

---

## 2. What runs *here* (Windows)

This machine has Node 24 + npm. **No JVM, no Android SDK, no Xcode, no VS Build Tools.**

> **Heads-up I hit during this session:** `npm install` failed because `better-sqlite3@11.10.0` needs to compile native bindings on Windows, and Node 24 doesn't have a published prebuild yet. Two ways forward on this machine:
> 1. **Easiest:** install Node 22 LTS (`winget install OpenJS.NodeJS.LTS`) — the prebuilt binary will download successfully.
> 2. **Or:** install Visual Studio 2022 Build Tools with the "Desktop development with C++" workload (~5 GB) so node-gyp can compile from source.
>
> CI doesn't hit this — GitHub Actions' `ubuntu-latest` runners have prebuilt binaries.

```powershell
cd Z:\home\spatchava\AmericanGroupLLC\mobile-apps\apps\HealthApp\server
Copy-Item .env.example .env   # if not already done
npm install                   # ← will fail on Node 24 + Windows; see note above
npm test                      # runs api.test.js + careplus.test.js
node smoke.js                 # cold-boots server and pings every route
node server.js                # interactive dev server on :4000
```

While the dev server is running, you can probe the new Care+ routes:

```powershell
# Vendor browse — public, no auth, returns 6 sample vendors
curl http://localhost:4000/api/vendor/menu
curl "http://localhost:4000/api/vendor/menu?conditions=hypertension"

# Doctor finder — public, requires 5-digit ZIP
curl "http://localhost:4000/api/doctors/search?zip=94089"
curl "http://localhost:4000/api/doctors/search?zip=94089&specialty=Family"

# Insurance + FHIR — auth required (will return 401 without a JWT)
curl -X POST http://localhost:4000/api/insurance -H "Content-Type: application/json" -d "{}"
curl http://localhost:4000/api/fhir/Patient/123 -H "X-FHIR-Issuer: https://example"
```

---

## 3. Android — emulator commands (needs your machine, not this one)

> The Flutter VS Code plugin you mentioned **does not apply** — this codebase is native Kotlin + Jetpack Compose, not Dart/Flutter. Use Android Studio's bundled emulator or `gradlew` directly.

### Prerequisites on your machine

- JDK 17 (Temurin / OpenJDK)
- Android Studio Hedgehog or newer (provides `adb`, `emulator`, AVD)
- An AVD running API 34 (Android 14)
- `ANDROID_HOME` env var set, `$ANDROID_HOME/platform-tools` and `$ANDROID_HOME/emulator` on `PATH`

### Build, install, run

```bash
cd Z:\home\spatchava\AmericanGroupLLC\mobile-apps\apps\HealthApp\android

# First-time only: bootstrap the gradle wrapper if not present
gradle wrapper --gradle-version 8.10

# Boot an emulator (replace Pixel_7_API_34 with your AVD name from `emulator -list-avds`)
& "$env:ANDROID_HOME\emulator\emulator.exe" -avd Pixel_7_API_34 -netdelay none -netspeed full

# In another terminal, debug build + install on the running emulator
.\gradlew.bat :app:installDebug

# Run JVM unit tests (includes the new InsuranceCardOcrTest)
.\gradlew.bat :app:testDebugUnitTest

# Watch logs
adb logcat | Select-String "MyHealth|CarePlus|FHIR"
```

### What you should see

1. App boots to Onboarding (6 pages — Welcome → Login → Birth → Permissions → Goal → Health issues).
2. After "Finish", lands on the **Care** tab with avatar + bell header and 4 tabs at the bottom.
3. Tap "Connect MyChart" → Custom Tab opens to `https://fhir.epic.com/...` Epic sandbox login. Sign in with `fhircamila / epicepic1`.
4. Switch to Diet → existing diary screen. Train → existing programs. Workout → ring placeholder + RPE rating sheet (first `ModalBottomSheet` in the app).

### Backend reachability from emulator

The Android emulator reaches the host's `localhost` via `10.0.2.2`. The
new `network/ApiBaseUrl.kt` defaults to that. If your dev server runs on
a different port, override via Settings → API base URL (or the DataStore
key `api_base_url`).

---

## 4. iOS — emulator commands (Mac required)

This one cannot be run from Windows at all. Hand to whoever has the Mac.

### Prerequisites on a Mac

- macOS 14+ with Xcode 15+
- `xcodegen` (`brew install xcodegen`)
- iPhone 15 simulator installed (or any iOS 17+ simulator)

### Build, install, run

```bash
cd ios
xcodegen generate
xcodebuild -project FitFusion.xcodeproj -scheme FitFusion \
  -sdk iphonesimulator -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  CODE_SIGNING_ALLOWED=NO build

# Open in Xcode for live run / step-debug
open FitFusion.xcodeproj
# Then: select iPhone 15 simulator → Cmd+R
```

### Critical things to verify in the iOS sim

1. After onboarding, the bottom bar shows **Care · Diet · Train · Workout** (4 tabs, not the old 5).
2. Care tab → "Connect MyChart" → `ASWebAuthenticationSession` opens to Epic sandbox. The `myhealth://oauth/fhir/callback` URL scheme must be registered in `Info.plist` (it is — added week 1).
3. Workout tab → tap any workout → RPE half-sheet (1–10 slider with Borg labels) appears.
4. Profile (avatar tap on any tab) → Connected sources section lists Apple Health, Epic MyChart, Insurance card, Pharmacy with checkmark / Connect / Add affordances.

---

## 5. Backend — running locally for emulator integration

Both emulators (Android & iOS) need a backend on `:4000`.

```powershell
# Windows (this machine)
cd Z:\home\spatchava\AmericanGroupLLC\mobile-apps\apps\HealthApp\server
node server.js
# Output: ✅ MyHealth API listening on http://localhost:4000
```

| Caller | Reaches localhost via |
|---|---|
| Android emulator | `http://10.0.2.2:4000` (auto-set by `ApiBaseUrl.kt`) |
| iOS simulator | `http://localhost:4000` (auto-set by `APIClient.swift` `APIConfig.baseURL`) |
| Real device | Set via Settings → API base URL → your machine's LAN IP, e.g. `http://192.168.1.42:4000` |

---

## 6. CI path (skip the local toolchain entirely)

Your repo already has `release.yml` and a "Pre-Release Tests" workflow
(per `CHANGELOG.md`). Push the v1.5.0 branch and let CI:

1. Run `npm test` (Jest) on the backend.
2. Run `./gradlew :core:testDebugUnitTest :app:testDebugUnitTest` on Android.
3. Run iOS-sim build via `xcodebuild` on a `macos-14` runner.
4. Build the Android APK + iOS Archive for TestFlight upload.

If CI was green on master before v1.5.0, the shape of the new work
(additive routes + new entities + new screens) shouldn't break the build
gates that already exist. Things most likely to surface as CI hits:

- **Android**: gradle sync fetches `androidx.security:security-crypto`,
  `net.zetetic:android-database-sqlcipher`, `net.openid:appauth`,
  `androidx.browser:browser`. First sync is slower; no version conflicts
  expected.
- **iOS**: `xcodegen generate` will pick up the 14 new Swift files
  automatically (XcodeGen scans `FitFusion/`); no `project.yml` update
  needed.
- **Backend**: `audit_log` table is created at `db.js` import time, so
  the first test that writes to it works on a fresh DB.

---

## 7. What this Windows box can do for you right now

I just kicked off `npm install` in the `server/` directory; once it
finishes I'll run `npm test` and report results. I cannot run the
Android or iOS sides — those need their respective host OSes (or CI).

If the question was about the **Flutter VS Code extension specifically**:
it is not applicable to this codebase. The native Swift / Kotlin work in
`ios/` and `android/` will stay invisible to that plugin. The Expo RN
shell at `mobile/` is a separate small artifact (login screen + guest
button) and is also not Flutter — it's React Native.
