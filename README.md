# MyHealth 🔥 — Your Personal Fitness OS

[![CI](https://github.com/AmericanGroupLLC/HealthApp/actions/workflows/ci.yml/badge.svg)](https://github.com/AmericanGroupLLC/HealthApp/actions/workflows/ci.yml)
[![Backend](https://github.com/AmericanGroupLLC/HealthApp/actions/workflows/backend.yml/badge.svg)](https://github.com/AmericanGroupLLC/HealthApp/actions/workflows/backend.yml)
[![iOS](https://github.com/AmericanGroupLLC/HealthApp/actions/workflows/ios.yml/badge.svg)](https://github.com/AmericanGroupLLC/HealthApp/actions/workflows/ios.yml)
[![Android](https://github.com/AmericanGroupLLC/HealthApp/actions/workflows/android.yml/badge.svg)](https://github.com/AmericanGroupLLC/HealthApp/actions/workflows/android.yml)
[![Expo](https://github.com/AmericanGroupLLC/HealthApp/actions/workflows/expo.yml/badge.svg)](https://github.com/AmericanGroupLLC/HealthApp/actions/workflows/expo.yml)
[![Marketing site](https://github.com/AmericanGroupLLC/HealthApp/actions/workflows/marketing.yml/badge.svg)](https://github.com/AmericanGroupLLC/HealthApp/actions/workflows/marketing.yml)
[![codecov](https://codecov.io/gh/AmericanGroupLLC/HealthApp/branch/main/graph/badge.svg)](https://codecov.io/gh/AmericanGroupLLC/HealthApp)

📖 **Docs**: [QUICKSTART.md](./QUICKSTART.md) (5-min setup per platform) · [DESIGN.md](./DESIGN.md) (architecture · features · data flow) · [TESTING.md](./TESTING.md) (sanity-test checklist · CI · simulator/emulator) · [RELEASING.md](./RELEASING.md) (releases · GitHub binaries · Play Store · App Store) · [PRODUCTION.md](./PRODUCTION.md) (production readiness · store deployment · gaps) · [STORE-PACKAGING.md](./STORE-PACKAGING.md) (watch-app bundling reality check) · [SENTRY.md](./SENTRY.md) (crash reporting · privacy · setup) · [OBSERVABILITY.md](./OBSERVABILITY.md) (full stack: Sentry + PostHog + Grafana free tier) · [WORKOUT-MEDIA.md](./WORKOUT-MEDIA.md) (workout GIFs · condition-aware filtering · diet suggestions · doctor disclaimer)

---

## 🔭 Observability & analytics (all free tier, all opt-in)

| Concern | Tool | Free tier | Where it's wired |
|---|---|---|---|
| Crashes + APM + logs | **Sentry** | 5K errors/mo | iOS · watchOS · Android · Wear · Expo · backend |
| Product analytics + feature flags + replays | **PostHog** | 1M events/mo (OSS, EU region) | iOS · Android · Expo · backend |
| Server metrics (optional) | Grafana Cloud Free | 10K series, 50 GB logs | docs only |
| Uptime monitoring (optional) | UptimeRobot | 50 monitors | docs only |

**Privacy contract**: every SDK is **off by default**. Users opt in via Settings → Privacy. Every wrapper strips `event.user` and never sends health data, meal contents, medicine names, photos, or screen recordings. Self-hostable if you outgrow the free tier. Mixpanel / Amplitude can be swapped in 1-line per platform.

Full setup + alternatives matrix: [`OBSERVABILITY.md`](./OBSERVABILITY.md).

---

---

> *Not just another workout app — a unified iPhone + Apple Watch + Android + Wear OS operating system for your body. Powered by on-device AI and end-to-end native.*

MyHealth combines **training, cardio, nutrition, sleep, mindfulness, on-device AI coaching, real-time workout mirroring, medicine reminders, biological-age estimation, and social challenges** into one cohesive experience built around a 5-layer architecture.

**Now runs on 5 platforms — all with optional no-account "Guest Mode":**

| Platform | Tech | Status |
|---|---|---|
| 📱 **iOS** (iPhone) | Swift + SwiftUI + HealthKit + CoreData/CloudKit | Full feature set |
| ⌚ **watchOS** (Apple Watch) | Swift + SwiftUI + HKWorkoutSession + WCSession | 9 vertical tabs incl. Anatomy |
| 🤖 **Android** (phone) | Kotlin 2.0 + Compose + Room + Health Connect + ML Kit + Hilt | Phase 4 — full bottom-nav port |
| ⌚ **Wear OS** (Android Watch) | Kotlin + Wear Compose + Health Services + Tile + Complication | Phase 5 — 9 vertical pages incl. Anatomy |
| 🌐 **Web / Expo** (Android + iOS + Web) | React Native (Expo) | Login + Guest button |

Plus the public-facing **marketing website** (`index.html` + `styles.css` + `script.js`) at the root.

---

## 🆕 Phase 1 – 6 — Guest Mode + Android + Wear OS + new domains

This iteration added:

- **Guest Mode globally** (iOS + watchOS share `AuthStore.continueAsGuest()`; Expo Login has a "Continue as Guest" button; Android `SettingsRepository.isGuest = true` by default). Any user can launch the app and start using it **without an email**. Existing JWT login path is preserved.
- **Onboarding flow** — 4-page Welcome → Profile setup → Goal → Done; gated by `UserDefaults.didOnboard` on iOS and `DataStore` on Android.
- **Medicine reminders** with `UNUserNotificationCenter` (iOS) and `AlarmManager` + WorkManager (Android). Take / Snooze 10 min actions, persisted dose log, 14-day adherence streak, archive.
- **Food diary** (iOS + Android Room) — daily macro rings + 14-day history + custom-meal builder.
- **Activities** (non-workout movement: walking, gardening, cleaning) with full add/edit/delete.
- **Health articles** — bundled offline-readable `HealthArticleSeed` + live MyHealthfinder topics + OpenFDA drug-info lookup.
- **Cross-platform JSON schema** at [`shared/schemas/myhealth.schema.json`](./shared/schemas/myhealth.schema.json) — both Apple Core Data and Android Room entities map 1:1; export/import via `PortabilityService` so users can move profiles between iOS and Android.
- **Android phone app** under [`android/`](./android/) — native Kotlin + Compose + Material 3 dynamic theming + 5 localizations.
- **Wear OS app** under [`android/wear/`](./android/wear/) — vertically-paged tabs, Tile + Complication for readiness, Health Services for live HR.
- **`/api/medicine/lookup`** — public no-auth route for OpenFDA drug labels.

---

## 🧭 Apple-side architecture

```
┌────────────────────┐     ┌─────────────────────┐     ┌──────────────────────┐
│ 📱 iOS app (ios/)   │ ⇄  │ ⌚ watchOS app       │ ⇄  │ ☁️  CloudKit          │
│ SwiftUI · 5+1 tabs  │     │ (watch/) SwiftUI    │     │ iCloud.com.fitfusion │
│ Home · Train · Diary│     │ Live workout · Run  │     │ Plans · Meals · Mood │
│ Sleep · More        │     │ Anatomy · Crown log │     └──────────────────────┘
└─────────┬──────────┘     └──────────┬──────────┘
          │                            │
          │  shared/FitFusionCore      │
          │  (Models · APIClient ·     │
          │   AuthStore (+ Guest) ·    │
          │   CloudStore (15 entities))│
          ▼                            ▼
   ┌──────────────────────────────────────────────┐
   │ 🩺 HealthKit  +  🏋️ WorkoutKit (Apple SDKs)   │
   │ HRV · sleep stages · workouts · macros · etc.│
   └──────────────────────────────────────────────┘

   ┌──────────────────────────────────────────────┐
   │ 🌐 Express + SQLite backend (server/)         │
   │ Auth · Profile · Metrics · Insights ·        │
   │ Nutrition · Live public health data          │
   └──────────────────────────────────────────────┘
                       ▲
                       │ REST (cross-platform)
                       │
   ┌───────────────────┴──────────────────────────┐
   │ 📱 Expo React Native app (mobile/)            │
   │ Android / iOS / Web fallback                 │
   └──────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
FitFusion/
├── index.html                    ← Marketing website (rebranded to FitFusion)
├── styles.css
├── script.js
├── server/                       ← Node.js + Express backend
│   ├── server.js, db.js
│   ├── middleware/auth.js
│   ├── routes/{auth,profile,health,nutrition,insights}.js
│   └── package.json
├── shared/
│   └── FitFusionCore/            ← Shared Swift Package (iOS + watchOS)
│       ├── Package.swift
│       └── Sources/FitFusionCore/
│           ├── Models.swift
│           ├── APIClient.swift
│           ├── AuthStore.swift
│           ├── CloudStore.swift
│           ├── WatchConnectivity/Bridge.swift
│           └── FitFusionModel.xcdatamodeld
├── ios/                          ← Native SwiftUI iOS app (NEW)
│   ├── project.yml               (XcodeGen)
│   └── FitFusion/
│       ├── FitFusionApp.swift, RootView.swift
│       ├── Info.plist, FitFusion.entitlements
│       ├── Views/{Auth,Home,Train,Run,Nutrition,Sleep}/
│       └── Services/{iOSHealthKitManager, ReadinessEngine,
│                    RecoveryService, NutritionService,
│                    WorkoutScheduler, AppIntents}.swift
├── watch/                        ← SwiftUI watchOS app
│   ├── project.yml
│   ├── HealthAppWatch/           (uses FitFusionCore)
│   └── FitFusionComplication/    (Readiness on watch face — NEW)
└── mobile/                       ← Expo React Native (cross-platform)
    └── ...
```

---

## ✨ MVP Features

### 1. Workout Library  🏋️
Browse strength · cardio · yoga · mobility · beginner / advanced — tap any workout and "Send to Watch" via WorkoutKit; it appears in the native Watch Workout app.

### 2. Run Tracker  🏃
Live pace + distance on the Watch (CMPedometer); route maps + pace/elevation charts on the iPhone (MapKit + Swift Charts).

### 3. Food & Calorie Logging  🥗
Barcode scanning (VisionKit `DataScannerViewController`) → Open Food Facts lookup → macros written to HealthKit as an `HKCorrelation` and synced via CloudKit + the Express backend.

### 4. Sleep & Recovery  💤
Last-night sleep stages chart, 7-day HRV trend, 0–100 recovery score with traffic-light zones, and a Wind Down sheet with a guided breath / mindful session.

### 5. Apple Watch Live Workout Controls  ⌚
`HKWorkoutSession` + `HKLiveWorkoutBuilder` with always-on display, HR zones, calories, elapsed time. Run mode adds live pace.

### 6. HealthKit Sync  🩺
The iOS app's `iOSHealthKitManager` requests authorization for the full read set (steps, HR, HRV, RHR, sleep stages, dietary energy/protein/carbs/fat, water, mindful, workouts) and write set (water, body mass, dietary correlations, mindful sessions, workouts). The watchOS app's `HealthKitManager` mirrors this and writes back to HealthKit on every wrist log.

---

## 🚀 Run It

### 1. Backend

```bash
cd server
cp .env.example .env       # set JWT_SECRET to something random
npm install
npm run dev                 # → http://localhost:4000
```

Test:
```bash
curl http://localhost:4000/api/health-check
```

### 2. iOS app

```bash
brew install xcodegen
cd ios
xcodegen generate
open FitFusion.xcodeproj
```

Pick an iPhone simulator (iOS 17+) and hit ▶️.

### 3. watchOS app

```bash
cd watch
xcodegen generate
open HealthAppWatch.xcodeproj
```

Pick an Apple Watch simulator and hit ▶️. See [`watch/README.md`](watch/README.md).

### 4. Mobile (Expo, cross-platform)

```bash
cd mobile
npm install
npm start
```

---

## 🔌 API Reference

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET  | `/api/health-check` | – | Liveness check |
| POST | `/api/auth/register` | – | Create account |
| POST | `/api/auth/login` | – | Get JWT |
| GET  | `/api/profile` | ✅ | User + profile + BMI |
| PUT  | `/api/profile` | ✅ | Upsert profile fields |
| POST | `/api/profile/metrics` | ✅ | Log a metric |
| GET  | `/api/profile/metrics?type=weight` | ✅ | List metrics |
| POST | `/api/nutrition/meal` | ✅ | Log a meal (kcal + macros) |
| GET  | `/api/nutrition/today` | ✅ | Today's meals + totals |
| GET  | `/api/insights/readiness` | ✅ | 0–100 readiness score |
| GET  | `/api/insights/weekly` | ✅ | 7-day per-metric aggregates |
| GET  | `/api/health/topics?keyword=sleep` | – | Live MyHealthfinder topics |
| GET  | `/api/health/topic/:id` | – | Full topic content |
| GET  | `/api/health/drug?name=ibuprofen` | – | Open FDA drug labels |

---

## 🌐 Data Sources (free, no API key)

- **MyHealthfinder** — health.gov
- **Open FDA** — open.fda.gov
- **Open Food Facts** — world.openfoodfacts.org

---

## 🔒 Privacy posture (on-device AI)

All model inputs and outputs stay on the device. The Core ML `AdaptivePlanner` runs locally with `MLPredictionOptions(usesCPUOnly: false)`; nightly `MLUpdateTask` fine-tuning runs locally via `BGTaskScheduler` with the user's recent (HRV, sleep, planned vs actual workout, perceived exertion) tuples. The Vision meal-photo classifier and nutrition-label OCR also run locally. Only the chosen `WorkoutTemplate` ID is ever sent to the backend (just as today).

## 📦 Bundle IDs (preserved)

Despite the rebrand, bundle IDs (`com.fitfusion.ios`, `com.fitfusion.watch`, `com.fitfusion.watch.complication`), the App Group (`group.com.fitfusion`), and the CloudKit container (`iCloud.com.fitfusion`) **remain unchanged** so already-synced CloudKit data survives. Only display names, marketing copy, and Siri phrase wording change.

---

## 🛣 Roadmap (post-MyHealth-v1)

- SensorKit deep-context (requires separate Apple entitlement approval)
- Apple Game Center leaderboards (`LeaderboardClient` flag, off by default)
- Apple Vision Pro spatial coach view
- Offline workout playback (downloaded media)
