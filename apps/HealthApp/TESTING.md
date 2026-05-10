# MyHealth — Sanity Testing Guide

This is the end-to-end checklist a tester walks through to verify each
feature is working. Now covers **5 platforms** (iOS · watchOS · Android phone ·
Wear OS · Web/Expo) and **Guest Mode**.

---

## 0. Prerequisites

| Surface | Needs |
|---|---|
| Marketing site | A web browser |
| Backend | Node.js ≥ 18 |
| Expo (mobile) | Node + the [Expo Go](https://expo.dev/client) app on your phone (iOS or Android) |
| iOS / watchOS native | macOS · Xcode 15+ · `xcodegen` (`brew install xcodegen`) · iCloud account signed in on the simulator/device · Apple Developer team ID (free or paid) |
| Real-device-only features | A real iPhone (iOS 17+) and ideally a paired Apple Watch (watchOS 10+) |

---

## 1. Backend (any OS)

```bash
cd server
cp .env.example .env
# edit .env to set JWT_SECRET to a random 32-char string
npm install
npm run dev          # → ✅ MyHealth API listening on http://localhost:4000
```

In a second terminal:

```bash
cd server
npm run smoke        # auto-registers a test user, exercises every route
```

Expected output: ~10 ✅ lines and `10 / 10 passed.`

Or run the Jest suite:

```bash
npm test
```

### Manual curl spot-checks

```bash
curl http://localhost:4000/api/health-check
# {"ok":true,"service":"MyHealth API","time":"..."}

curl -X POST http://localhost:4000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"t@t.com","password":"password123"}'
# {"user":{...},"token":"..."}

# (use returned token below)
TOKEN=...
curl -H "Authorization: Bearer $TOKEN" http://localhost:4000/api/profile
```

---

## 2. Marketing site (any OS, no install)

Just open `index.html` in any browser.

| Section | Verify |
|---|---|
| Hero | Title bar reads "MyHealth · Your Personal Fitness OS" |
| Navbar | Logo says "MyHealth"; gradient buttons render |
| Unified Vision | "One MyHealth, Two Devices" heading |
| Pillars | 3 cards (Physical / Mental / Emotional) |
| Top Apps | Filter tabs (All / Fitness / Running / Diet / Mental / Tracking) toggle the grid |
| iPhone vs Watch | Comparison table renders |
| Footer | Links to WHO + CDC open in new tab; copyright reads MyHealth |

---

## 3. Expo cross-platform app (mobile or web)

```bash
cd mobile
npm install
npm start
```

- Press `w` for web, `i` for iOS sim, `a` for Android emulator, or scan the
  QR with **Expo Go** on a physical phone.
- Should land on the Login screen.
- Register → Profile → Log a metric → see it in History.

---

## 4. iOS native app — simulator (Mac required)

```bash
cd ios
xcodegen generate
open FitFusion.xcodeproj
```

In Xcode:
1. Select scheme **FitFusion** + an iPhone simulator (e.g. iPhone 15 Pro).
2. ▶️ Run.

### Sanity matrix

| Tab / surface | Steps | Expected |
|---|---|---|
| Login | Register a new account | Lands on Home tab |
| **Home** | Tap **How are you?** card | 2-axis State of Mind picker opens |
| Home | Tap **Today's Suggested Workout** | Routes to Workout Detail with confidence + rationale |
| **Train hub** | 6 tiles render | Anatomy / Library / Programs / Stretching / Custom / Send to Watch |
| Train → **Anatomy** | Tap a chest region on the front silhouette | Filtered list shows Bench Press, Push-up, etc. |
| Anatomy | Toggle **Back** in segmented picker | Lats, traps, lower back regions render |
| Train → **Library** | Search "deadlift" | Deadlift row appears |
| Library | Filter chips | Equipment / Level / Stretches toggle filter results |
| Train → **Programs** | Open Push/Pull/Legs → Push A | Shows 6 exercises linked to detail pages |
| Train → **Stretching** | List | 10 stretches render |
| Train → **Custom** | Add 3 exercises → Save | Saved entry appears below |
| Exercise detail | Tap **Log a Set** | Logger opens; defaults to last session shape if any |
| Logger | Add 3 sets → Save | Returns to detail; PR badge updates if a new PR |
| Logger | Tap **Start rest timer** | Circular countdown sheet animates |
| **Run** | Tap a past run | RunDetailView; map renders if route exists |
| **Eat** | Snap Meal | Picker opens; classifier returns empty list (no `.mlmodel`) — fallback works |
| Eat | Read Label | OCR opens; pick photo of nutrition label → form fills with kcal/protein/etc. |
| Eat | Search | Open Food Facts text search returns hits |
| **Sleep** | Open Wind Down | Breath circle animates; "Saved a 5-minute mindful session" after 5 min |
| Sleep | Tap **Log State of Mind** chip in Wind Down | StateOfMindLogger opens |
| **Social** | Add Friend | Friend appears in list |
| Social | Create Challenge | Active Challenges section renders new entry |
| Logout | Tap top-left logout icon | Returns to Login |

### Known simulator limitations

- **HealthKit reads** return zeros unless you seed the simulator's Health app via macOS.
- **Cameras** unavailable → Snap Meal / Read Label / Barcode are no-ops; use the
  PhotosPicker library path with a saved nutrition-label image to test OCR.
- **Workout Mirroring** + **Live Activity** + **SharePlay** require real devices.

---

## 5. watchOS app — simulator (Mac required)

```bash
cd watch
xcodegen generate
open HealthAppWatch.xcodeproj
```

Pick **HealthAppWatch** + an Apple Watch simulator (Series 10, watchOS 11), ▶️.

### Sanity matrix (vertical-paged tabs)

| Pane | Steps | Expected |
|---|---|---|
| Login | Sign in with the same account | Lands on Quick Log |
| **Quick Log** | Tap +250 ml | Haptic, "✓ Logged 250 ml" toast |
| **Live Workout** | Start | Timer starts; HR shows 0 in sim (real device only) |
| **Run** | Start | Distance starts incrementing (sim won't move; pedometer fallback used) |
| **Anatomy** ← new | Tap **Upper Body** | List of upper-body muscles |
| Anatomy | Tap **Chest** | Filtered exercise list (Bench, Push-up, etc.) |
| Anatomy | Tap **Bench Press** | Detail with steps + form tips + Quick Log button |
| Anatomy | Tap **Quick Log** → set reps/weight via Digital Crown → Save | Haptic, sheet auto-dismisses, log persisted to CloudKit |
| **Water / Weight** | Crown to value → Save | Haptic, posted to backend + HealthKit |
| **Mood** | Tap an emoji | Haptic, posted as both `mood` and `state_of_mind_valence` metrics |
| **History** | Pull list | Recent metrics with icons + timestamps |
| **Settings** | Edit API URL | Saves to UserDefaults; restart picks up the new base URL |

---

## 6. Real-device-only features

You need **at least one paired iPhone + Apple Watch** running iOS 17+ / watchOS 10+
and signed-in iCloud account.

### Workout Mirroring (the moat)
1. Start a workout on the watch (Live Workout pane).
2. Within ~2 seconds the iPhone should auto-present `MirroredWorkoutView`
   (full-screen orange/pink/purple gradient with HR + calories + elapsed).
3. End the workout on the watch → iPhone sheet dismisses.

### Live Activity
1. Same scenario as above.
2. Lock the iPhone → Lock Screen shows the workout banner with HR + elapsed.
3. On a Dynamic Island device → press-and-hold for the expanded variant.

### Widgets
1. Long-press an empty Lock Screen / Home Screen spot → Add Widget.
2. Pick MyHealth → choose Readiness, Today's Plan, or Macro Rings.
3. Widget should populate within one refresh cycle (~1 minute) with values
   from the App Group (`group.com.fitfusion`).

### GPS run
1. Watch → Run → Start.
2. Walk outside ≥1 km.
3. End run → on iPhone, RunDetailView shows polyline + 1+ split.

### State of Mind ↔ Apple Health
1. iPhone → Home → How are you? → drag dot → Save.
2. Open the system Health app → Browse → State of Mind → entry appears.

### CloudKit sync
1. Log a workout set on iPhone.
2. Within ~30s, the same exercise on the watch shows the new set in "Last session".

### SharePlay shared workout
1. FaceTime a friend running MyHealth.
2. Open Train → Send to Watch → tap a workout.
3. The shared SharePlay banner appears in FaceTime; both devices schedule the same
   `WorkoutTemplate`.

### iMessage Activity Card
1. After a workout ends, iPhone → Messages → MyHealth iMessage app → tap card.
2. Card inserts into compose field.

---

## 7. Automated tests

| Suite | How to run | What it covers |
|---|---|---|
| Backend (Jest) | `cd server && npm test` | Auth, profile, metrics, social CRUD |
| FitFusionCore (XCTest) | `cd shared/FitFusionCore && swift test` *(macOS)* | ExerciseLibrary, Programs, NutritionLabelOCR, AdaptivePlanner heuristic, Codable round-trips |

---

## 8. Known caveats — read before reporting bugs

- Bundle IDs are intentionally `com.fitfusion.*` even though the display name is
  MyHealth (preserves CloudKit data; see root README).
- `AdaptivePlanner.mlmodel` and `FoodClassifier.mlmodel` are **not** bundled;
  the heuristic / no-op fallbacks are intentional. See
  [`ios/FitFusion/Models/README.md`](ios/FitFusion/Models/README.md).
- App icons fall back to Springboard placeholders until you drop a 1024×1024
  PNG into `Assets.xcassets/AppIcon.appiconset/`. See the README in that folder.
- `DEVELOPMENT_TEAM` is empty in `project.yml`s — see [`ios/SIGNING.md`](ios/SIGNING.md).

---

## 9. Issue template

When something fails, please report:

```
Surface: iOS / Watch / Backend / Marketing / Expo
Device: iPhone 15 Pro Sim, iOS 17.5
Steps:
  1. Open Train tab
  2. Tap Anatomy
  3. ...
Expected: chest exercises listed
Actual: blank screen
Console:
  <copy-paste any Xcode console errors>
```

---

## 10. Guest Mode (no-account / local-only)

### iOS
1. Reset the simulator (Device -> Erase All Content and Settings).
2. Build & run -> Login screen shows three actions: Sign In / Create an account / **Continue as Guest**.
3. Tap **Continue as Guest** -> 4-page Onboarding (Welcome -> Profile -> Goal -> Done).
4. Land on Home with no auth prompts. Open More -> Settings -> see Guest mode label.
5. Add a meal in Diary -> quit + relaunch -> meal still there (CoreData persisted).
6. From Settings tap **Sign in for cloud sync** -> Login sheet -> register -> app keeps the local data.

### Android
1. Wipe the emulator -> fresh install.
2. Launch -> 4-page Onboarding (no login screen).
3. Bottom-nav: Home / Train / Diary / Sleep / More.
4. Add a medicine via FAB -> reminder fires at the chosen time.
5. Open More -> Settings -> Guest mode label.

### Web (Expo)
1. cd mobile && npm start.
2. Login screen -> Continue as Guest -> lands on the app's home tab.

---

## 11. Android phone app

cd android
./gradlew :app:assembleDebug
./gradlew :app:installDebug   # on a connected emulator/device

| Surface | Steps | Expected |
|---|---|---|
| Onboarding | First launch | 4-page flow -> Home |
| Home | Tap Vitals tile | Vitals screen renders |
| Vitals | Tap Biological Age card | Sliders update bio age in real time |
| Anatomy | More -> Anatomy -> tap a region tab | Muscle list scrolls |
| Medicine | More -> Medicines -> FAB -> fill name + dosage + 09:00 -> Save | Notification fires at 09:00 with Take / Snooze |
| Articles | More -> Health articles -> tap article | Detail body renders |
| Diary | More navigation -> Diary tab | Empty list (or recent meals if seeded) |
| Settings | More -> Settings | Imperial toggle persists across relaunches |

### Tests

./gradlew :core:testDebugUnitTest
./gradlew :app:testDebugUnitTest
./gradlew :app:connectedDebugAndroidTest

---

## 12. Wear OS app

cd android
./gradlew :wear:installDebug   # on a Wear OS emulator (Wear 4 / API 33+)

| Pane (swipe up to advance) | Verify |
|---|---|
| Quick Log | Renders header + subtitle |
| Live Workout | Renders, ready to wire HealthServicesGateway |
| Run | Same |
| Anatomy | ScalingLazyColumn lists every MuscleGroup with exercise count |
| Water / Weight / Mood / History / Settings | Render placeholder text |

Watch face -> long-press -> add MyHealth Readiness complication.
A ReadinessTileService is also registered (visible in the Tiles carousel).

---

## 13. Automated CI

Every push triggers GitHub Actions defined under .github/workflows/.

| Workflow | Trigger | What it runs |
|---|---|---|
| ci.yml | push + PR | Backend Jest+smoke / Android core+app unit tests / iOS Swift Package tests + sim build / Watch sim build / marketing lint |
| android.yml | push to main + workflow_dispatch | Android instrumented tests on a real emulator (KVM-backed) |
| ios.yml | push touching ios/ watch/ shared/ | iOS + watchOS sim builds (no signing) |
| backend.yml | push touching server/ | Jest + 13/13 smoke run |
| marketing.yml | push touching index.html/styles.css/script.js | Deploys static site to GitHub Pages |
| release.yml | push of v* tag | Build everything, attach to GitHub Release, optional Play Store upload |

## 14. Local one-shot test runner

./scripts/test-all.sh runs every suite available on the current OS:

- Backend  : Jest + smoke
- Android  : core + app unit tests (skipped if Gradle not installed)
- iOS+Watch: Swift Package tests + iOS sim build (skipped if not on macOS)
- Marketing: html-hint best-effort

## 15. Local simulator / emulator launchers

| Script | Requires | What it does |
|---|---|---|
| ./scripts/run-ios-sim.sh | macOS + Xcode + xcodegen | Boots iPhone 15 sim, builds, installs, launches MyHealth.app |
| ./scripts/run-android-emulator.sh | ANDROID_HOME + a Pixel AVD | Boots phone emulator, installs, launches com.myhealth.app |
| ./scripts/run-wear-emulator.sh | ANDROID_HOME + Wear AVD | Boots Wear emulator, installs, launches com.myhealth.wear |

## 16. Release dry-run

./scripts/release-dry-run.sh v1.2.0 builds every artefact locally without
pushing anything (mirrors what release.yml does on a tag push). Outputs land
in distribution/staging-v1.2.0/.

## 17. Direct Google Play upload

Yes - the release.yml workflow uploads the AAB to Play Console automatically
when secrets are set (PLAY_STORE_SERVICE_ACCOUNT_JSON +
PLAY_STORE_PACKAGE_NAME). See RELEASING.md for the full setup.

---

## 18. CI test strategy for FitFusionCore (audit summary)

The shared Swift Package contains iOS-only / watchOS-only frameworks by
design. Comprehensive audit of imports inside
`shared/FitFusionCore/Sources/FitFusionCore/`:

| File | Imports | macOS-host compatible? |
|---|---|---|
| AuthStore.swift / Models.swift / APIClient.swift | Foundation, SwiftUI | yes |
| HealthArticleSeed.swift | Foundation | yes |
| CloudStore.swift / FriendsStore.swift / ChallengesStore.swift | Foundation, CoreData, CloudKit, Combine | yes (macOS 13+) |
| BiologicalAgeEngine / BadgesEngine / StreaksEngine / Exercise / WorkoutProgram / LeaderboardClient / AdaptivePlanner | Foundation [+ CoreML] | yes |
| **WatchConnectivity/Bridge.swift** | Foundation, **WatchConnectivity** | NO (already gated with #if canImport) |
| PersonalFineTuner.swift | Foundation, CoreML, **BackgroundTasks** | partial (gated with #if os(iOS)) |
| **MealPhotoRecognizer.swift** | Foundation, **UIKit**, Vision, CoreML | NO |
| **NutritionLabelOCR.swift** | Foundation, **UIKit**, Vision | NO |

Because UIKit + WatchConnectivity cannot link on the macOS host, `swift test`
on a macos-14 runner cannot test the package end-to-end. Two options exist:

A. Test on the iOS Simulator via xcodebuild. **(Chosen.)**
B. Split FitFusionCore into a pure-Swift sub-module + an iOS-specific module.

The CI workflows now run:

`xcodebuild test -scheme FitFusionCore-Package -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'`

This natively builds the package against an iOS SDK (UIKit/WatchConnectivity
both link) and runs the test target on the iPhone simulator. macOS host tests
were dropped from Package.swift and the workflows.

## 19. Known CI caveats

* Codecov upload steps emit a warning when `CODECOV_TOKEN` is unset on a
  private repo — they are non-fatal (`fail_ci_if_error: false`).
* Marketing Pages deploy is gated on the configure-pages step succeeding;
  one-time enable at Settings -> Pages -> Source: GitHub Actions.
* release.yml Play Store upload is gated on `PLAY_STORE_SERVICE_ACCOUNT_JSON`
  secret presence; safe to commit before secrets exist.
