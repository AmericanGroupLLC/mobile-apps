# MyHealth watchOS Companion ⛔

A SwiftUI watchOS app that's the **live coaching + tracking + GPS** half of MyHealth — the iPhone is the planning + AI hub, the wrist is where the workout actually happens. Real GPS routes via `CLLocationManager` + `HKWorkoutRouteBuilder`, always-on display during workouts, and live mirroring of the workout to the iPhone via `HKWorkoutSession.startMirroringToCompanionDevice()` (iOS 17 / watchOS 10).

## ✨ Tabs

| Tab | What it does |
|---|---|
| 🏠 **Quick Log** | 4 big buttons: +250 ml water · +1k steps · mood ↑ · +1 hr sleep |
| 🏋️ **Live Workout** | Start `HKWorkoutSession`, real-time HR + calories + elapsed, Pause/End |
| 🏃 **Run** | Start a run · live distance via `CMPedometer` · live pace · GPS route |
| 🧠 **Anatomy** | Tap a body region → muscle list → exercises → form tips → Quick Log a set with the Digital Crown (CloudKit-synced PRs) |
| 💧 **Water** | Custom amount via Digital Crown (50–1500 ml) — also writes to HealthKit |
| ⚖️ **Weight** | Custom weight via Digital Crown (30–250 kg) — writes to HealthKit |
| 😄 **Mood** | 5-emoji picker (Awful → Great), maps to 1–5 scale |
| 📜 **History** | Recent metric entries with icons + timestamps |
| ⚙️ **Settings** | Connect HealthKit · Edit API URL · view profile · log out |

Every successful log triggers a **haptic** (`.success`).

## 🔥 Complication: Readiness on the Watch Face

A separate WidgetKit extension target — `FitFusionComplication` — surfaces today's **Readiness %** on any watch face. Supports:
- `accessoryCircular` (gauge)
- `accessoryRectangular` (score + suggestion)
- `accessoryInline`
- `accessoryCorner`

The score is read from the **App Group** (`group.com.fitfusion`) shared `UserDefaults` — written by the iOS `ReadinessEngine` whenever the iPhone refreshes the dashboard.

## 🩺 HealthKit Auto-Sync

On first launch (after sign-in) the app requests HealthKit permission for:

- **Read:** steps · HR · HRV (SDNN) · resting HR · body mass · active energy · dietary water · distance · sleep analysis · respiratory rate · mindful sessions
- **Write:** water · weight · mindful sessions · workouts (via `HKLiveWorkoutBuilder`)

Observer queries with **background delivery** push every new sample to the FitFusion backend at `POST /api/profile/metrics`, mapped to types: `steps`, `heart_rate`, `weight`, `water`, `active_energy`, `sleep_hrs`, `hrv_sdnn`, `resting_hr`. These feed the iOS readiness score and weekly insights.

## 🎙 Siri & Shortcuts (App Intents)

- **"Hey Siri, log 250 milliliters of water in MyHealth"**
- **"Hey Siri, log my weight in MyHealth"**
- **"Hey Siri, log mood in MyHealth"**
- **"Hey Siri, sync MyHealth"**

(iOS app adds: Start Workout, Start Run, Log Meal.)

## 🏗 Architecture

```
watch/
├── project.yml                       ← XcodeGen (now with FitFusionCore SwiftPM dep + complication target)
├── HealthAppWatch/
│   ├── HealthAppWatchApp.swift       (@main; imports FitFusionCore)
│   ├── RootView.swift                (auth gate)
│   ├── Info.plist                    (allows local-network HTTP for dev)
│   ├── HealthAppWatch.entitlements   (HealthKit · CloudKit · App Group · Siri)
│   ├── Services/
│   │   ├── HealthKitManager.swift    (extended with HRV + RHR sync)
│   │   ├── WorkoutController.swift   (HKWorkoutSession + HKLiveWorkoutBuilder)
│   │   └── AppIntents.swift          (Log Water/Weight/Mood/Sync)
│   └── Views/
│       ├── LoginView.swift, RegisterView.swift
│       ├── MainTabsView.swift        (vertical TabView, 8 panes)
│       ├── LiveWorkoutView.swift     (NEW — strength/HIIT)
│       ├── RunSessionView.swift      (NEW — outdoor run)
│       ├── QuickLogView.swift, WaterLogView.swift, WeightLogView.swift
│       ├── MoodLogView.swift, HistoryView.swift, SettingsView.swift
└── FitFusionComplication/            ← NEW WidgetKit extension target
    ├── FitFusionComplicationBundle.swift
    ├── ReadinessWidget.swift
    ├── ReadinessProvider.swift
    ├── Info.plist
    └── FitFusionComplication.entitlements
```

### FitFusionCore migration

`Models.swift`, `APIClient.swift`, and `AuthStore.swift` previously lived under `HealthAppWatch/`. They moved to the new shared Swift Package at `../shared/FitFusionCore`. The watch app and the iOS app both depend on it, so there's zero code duplication. All watch source files now `import FitFusionCore` for `User`, `Profile`, `Metric`, `APIClient`, `AuthStore`, etc.

## 🛠 Build & Run

> Requires **macOS** with **Xcode 15+** (watchOS 10 SDK).

```bash
brew install xcodegen
cd watch
xcodegen generate
open HealthAppWatch.xcodeproj
```

Xcode: pick the **HealthAppWatch** scheme + an **Apple Watch Simulator** (Series 10, watchOS 11), then ▶️.

To install the complication on a watch face: long-press the face → Edit → Complications → pick FitFusion → Readiness.

## 🌐 API URL

- **Simulator + backend on same Mac:** `http://localhost:4000` (default)
- **Real Apple Watch:** Open **Settings** tab in the app and enter your computer's LAN IP, e.g. `http://192.168.1.42:4000`. Info.plist permits arbitrary local-network HTTP for dev.

## 🛣 Roadmap

- WorkoutKit `WorkoutPlan` consumption (display today's iPhone-scheduled plan inline)
- Smart Stack widgets for nutrition + sleep
- SharePlay shared workout participation from the wrist (currently iPhone-initiated)
