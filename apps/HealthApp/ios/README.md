# MyHealth iOS App 📱

The iPhone half of MyHealth — your **planning + insight + on-device AI hub**. Browse the workout library, plan meals, scan barcodes, snap meal photos for Vision-powered recognition, scan nutrition labels with OCR, view sleep stages, see your readiness score, log a 2-axis State of Mind entry, schedule structured workouts that show up on your Apple Watch via WorkoutKit, and get an iPhone-side mirrored view of any in-progress wrist workout.

## 🔒 On-Device AI — privacy posture

All model inputs and outputs stay on the device:

- **`AdaptivePlanner`** — small bundled `AdaptivePlanner.mlmodel` (~1–3 MB) trained offline on synthetic + open fitness data; runs in the app process via Core ML.
- **`PersonalFineTuner`** — nightly `MLUpdateTask` fine-tunes the model on the user's recent (HRV, sleep, planned vs actual workout, perceived exertion) tuples; scheduled via `BGTaskScheduler` (`com.fitfusion.bg.fineTune`). The user's tuples never leave the phone.
- **`MealPhotoRecognizer`** — `VNCoreMLRequest` over a bundled `FoodClassifier.mlmodel`; the user picks the right candidate, then `NutritionService` (Open Food Facts) resolves canonical macros.
- **`NutritionLabelOCR`** — `VNRecognizeTextRequest` parses kcal/protein/carbs/fat tokens locally; falls back to barcode lookup when a UPC is detected.

Only the `WorkoutTemplate` ID the user accepts is ever sent to the backend.

## 🤝 Workout Mirroring (iOS 17 "the moat")

When a workout starts on the Apple Watch, `WorkoutMirrorReceiver` automatically picks up the mirrored `HKWorkoutSession` and presents `MirroredWorkoutView` as a sheet on the iPhone. Live HR / calories / elapsed / distance update each second; the same channel feeds the ActivityKit Live Activity on the Lock Screen / Dynamic Island.

## 📈 Layer 4 — Live Activity + WidgetKit extensions

- `MyHealthLiveActivity` (ActivityKit) — in-workout Lock Screen + Dynamic Island
- `MyHealthWidget` (WidgetKit) — Readiness, Today's Plan, Macro Rings on Lock Screen + Home Screen
- `MyHealthMessages` (Messages) — share an Activity Card after a finished workout

## ✨ Tabs

| Tab | What it does |
|---|---|
| 🏠 **Home** | Greeting · readiness score · Today's Suggested Workout (AI) · State of Mind card · today's calories/protein/steps · quick start |
| 🏋️ **Train** | Anatomy picker (tap a muscle → exercises) · Library (50+ exercises, search + filters) · Programs (PPL / Upper-Lower / Full Body / Beginner Strength) · Stretching · Custom Workout builder · "Send to Watch" templates |
| 🏃 **Run** | List of past runs from HealthKit · GPS route maps · pace charts |
| 🍽 **Eat** | Barcode scanner · Snap Meal (AI) · Read Label (OCR) · search · macro totals · HealthKit `HKCorrelation` |
| 💤 **Sleep** | Last-night stage chart · 0–100 recovery score · Wind Down breath/mindful session · State of Mind logger |
| 👥 **Social** | Friends · challenges · leaderboard · badges · streaks · SharePlay shared workouts |

### MuscleWiki-style training surfaces

- **Anatomy picker** — interactive front/back body silhouette; tap a muscle group to filter exercises that target it (equipment + difficulty filters).
- **Exercise library** — 30+ strength lifts, 3 cardio modalities, 10 stretches; each exercise has step-by-step instructions, form tips, muscle chips, equipment, difficulty.
- **Workout logger** — sets / reps / weight per exercise, persisted to CloudKit-synced `ExerciseLogEntity`. Pre-fills today's sets with last session's shape; surfaces the heaviest single rep as a **PR** badge on the exercise detail page.
- **Rest timer** — circular countdown sheet with restart / skip.
- **Pre-built programs** — Push/Pull/Legs · Upper/Lower · Full Body 3× · Beginner Strength (linear progression).
- **Stretching library** — Child's Pose, Pigeon, Couch Stretch, Doorway Pec, etc.
- **Custom workout builder** — drag-reorderable exercise list, saved to CloudKit.

## 🧠 Architecture

```
ios/
├── project.yml                            ← XcodeGen
└── FitFusion/
    ├── FitFusionApp.swift                 ← @main; injects AuthStore, iOSHealthKitManager, CloudStore, WatchBridge
    ├── RootView.swift                     ← auth gate
    ├── Info.plist, FitFusion.entitlements ← HealthKit · CloudKit · App Group · Siri
    ├── Views/
    │   ├── MainTabView.swift              (5 tabs)
    │   ├── Auth/{LoginView, RegisterView}.swift
    │   ├── Home/HomeDashboardView.swift
    │   ├── Train/{TrainView, WorkoutLibraryView, WorkoutDetailView, ScheduleToWatchSheet}.swift
    │   ├── Run/{RunTrackerView, RunListView, RunDetailView, RunMapView}.swift
    │   ├── Nutrition/{NutritionView, BarcodeScannerView, FoodSearchView, MealDetailView}.swift
    │   └── Sleep/{SleepRecoveryView, SleepStagesChart, RecoveryScoreView, WindDownSheet}.swift
    └── Services/
        ├── iOSHealthKitManager.swift      (full HealthKit read/write set)
        ├── ReadinessEngine.swift          (heuristic 0–100 scorer)
        ├── RecoveryService.swift          (HRV + RHR + sleep)
        ├── NutritionService.swift         (Open Food Facts client)
        ├── WorkoutScheduler.swift         (WorkoutKit wrapper)
        └── AppIntents.swift               (Siri: StartWorkout, StartRun, LogMeal)
```

The iOS app depends on the **shared** `FitFusionCore` Swift Package
(`../shared/FitFusionCore`) for `Models`, `APIClient`, `AuthStore`, `CloudStore`, and the
`WatchConnectivity` bridge — so it shares zero code by-copy with the watchOS app.

## 🛠 Build & Run

> macOS, Xcode 15+, iOS 17 SDK.

```bash
brew install xcodegen
cd ios
xcodegen generate
open FitFusion.xcodeproj
```

In Xcode: pick the **FitFusion** scheme + an **iPhone simulator** (e.g. iPhone 15 Pro, iOS 17.x), then ▶️.

### Capabilities to enable in Signing & Capabilities

These are already declared in `FitFusion.entitlements` but you may need to confirm in Xcode after first build:

- **HealthKit** (incl. Background Delivery)
- **iCloud** → CloudKit container `iCloud.com.fitfusion`
- **App Groups** → `group.com.fitfusion`
- **Siri**

## 🌐 API URL

The app uses `FitFusionCore.APIConfig.baseURL`, which reads `apiBaseURL` from `UserDefaults`. Defaults to `http://localhost:4000`. To change it on a real device, add a Settings UI or set the value via Xcode's launch arguments.

## 🍎 Simulator vs Device

| Feature | Simulator | Real device |
|---|---|---|
| HealthKit reads/writes | Limited (seed via Health app on Mac) | Full |
| Barcode scanning | No (use FoodSearchView text search instead) | Yes (DataScannerViewController) |
| Run tracking | No CoreLocation outdoors | Full |
| WorkoutKit "Send to Watch" | Requires paired Watch simulator | Full |
| CloudKit sync | Yes (signed-in iCloud account) | Yes |

## 🛣 Roadmap (post-MyHealth-v1)

- **SensorKit** deep-context (requires separate Apple entitlement approval; explicitly stretch in the v1 plan)
- **Apple Game Center** leaderboard publishing (off by default in `LeaderboardClient`; flip when ready in App Store Connect)
- Apple Vision Pro spatial coach view
- Weekly auto-generated training plan from `AdaptivePlanner` outputs
- Smart Stack widgets for nutrition + sleep
