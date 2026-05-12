# MyHealth — Design & Architecture

> Complete architectural reference for MyHealth across **iOS · watchOS · Android phone · Wear OS · Web (Expo) · Express backend**.

This document is for engineers and designers joining the project. For end-user
docs see [`README.md`](./README.md). For sanity-test walkthroughs see
[`TESTING.md`](./TESTING.md). For release / deploy procedure see
[`RELEASING.md`](./RELEASING.md).

---

## 1. Vision

> **Your personal fitness OS, on every device, with no email required.**

MyHealth is a privacy-first, local-first fitness + health platform. Anyone can
launch the app and start using it in 60 seconds — no account, no email, no
"create your profile in the cloud" wall. Cloud sync is **opt-in** and only
turns on if the user explicitly signs in.

**Core promise:** every personal data point (meals, workouts, mood, vitals,
medicines, biological-age inputs) lives **on the user's device** by default.
Nothing leaves unless they opt in. AI inference (workout planner, meal-photo
classifier, label OCR, biological-age engine) runs on-device only.

---

## 2. Platform Map

```
                            ┌──────────────────────────────────────┐
                            │  Public docs + reference content      │
                            │  health.gov MyHealthfinder · OpenFDA  │
                            │  Open Food Facts · USDA FDC           │
                            └─────────────┬────────────────────────┘
                                          │  (no auth required)
                                          ▼
┌────────────────────────┐    ┌───────────────────────────────────┐    ┌────────────────────┐
│  iOS app (Swift)       │    │  Android app (Kotlin + Compose)   │    │  Expo (RN)         │
│  + watchOS companion   │◄───►   + Wear OS companion              │◄───►  Web · Android · iOS│
│  CoreData + CloudKit   │    │  Room + DataStore + Health Connect│    │  AsyncStorage      │
│  HealthKit + WorkoutKit│    │  CameraX + ML Kit + WorkManager   │    │                    │
└──────────┬─────────────┘    └───────────────┬───────────────────┘    └─────────┬──────────┘
           │                                  │                                  │
           │            (optional sync — only when user signs in)                │
           └──────────────┬───────────────────┴──────────────────────────────────┘
                          ▼
                ┌───────────────────────┐
                │  Express + SQLite     │
                │  (port 4000)          │
                │  Auth · Metrics ·     │
                │  Meals · Insights ·   │
                │  Social · Medicine    │
                └───────────────────────┘
```

| Surface | Tech | Local store | Online dependencies (optional) |
|---|---|---|---|
| **iOS app** | Swift + SwiftUI 5 | Core Data + iCloud | Express backend (sign-in only) |
| **watchOS app** | Swift + SwiftUI | Shared CoreData + WCSession | iOS app (paired) |
| **Android app** | Kotlin 2.0 + Compose + Material 3 | Room + DataStore | Express backend (sign-in only) |
| **Wear OS app** | Kotlin + Wear Compose | SharedPreferences | Phone app (paired) |
| **Web/Expo** | React Native (Expo) | AsyncStorage | Express backend |
| **Backend** | Node.js + Express + better-sqlite3 + JWT | SQLite file | OpenFDA · MyHealthfinder · Open Food Facts |

---

## 3. Five-Layer Domain Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 5 — SOCIAL & GAMIFICATION                                │
│  Friends · Challenges · Leaderboards · Badges · Streaks         │
│  SharePlay shared workouts · MSMessage activity cards           │
└─────────────────────────────────────────────────────────────────┘
                          ▲
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 4 — CLOUD + SURFACES                                     │
│  CloudKit (Apple) · Live Activities · Widgets · Mirroring       │
│  Compose Tile + Complication (Wear) · WorkManager               │
└─────────────────────────────────────────────────────────────────┘
                          ▲
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 3 — ON-DEVICE AI                                         │
│  AdaptivePlanner · PersonalFineTuner · BiologicalAgeEngine      │
│  MealPhotoRecognizer (Vision · ML Kit) · NutritionLabelOCR      │
└─────────────────────────────────────────────────────────────────┘
                          ▲
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 2 — PLATFORM SDK CORE                                    │
│  HealthKit + WorkoutKit (Apple) · Health Connect (Android)      │
│  CoreData · Room · DataStore · UserNotifications · AlarmManager │
└─────────────────────────────────────────────────────────────────┘
                          ▲
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 1 — RAW SENSING                                          │
│  Watch live HR/HRV · GPS · Workout sessions · Steps · SpO₂      │
│  Camera (barcode + meal photo + nutrition label OCR)            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Feature Catalogue

### 4.1 Onboarding & profile (every platform)
- 4-page first-launch flow: Welcome → Profile setup (name, DOB, sex, height, weight, units) → Goal (lose/maintain/build/endurance/general) → Done.
- Profile persisted to a single `ProfileEntity` row (Core Data on iOS, Room on Android).
- Editable any time via Settings → Profile.

### 4.2 Guest Mode (everywhere)
- iOS / watchOS / Web: `AuthStore.continueAsGuest()` flips `isAuthenticated = true` and `isGuest = true` without contacting the backend.
- Android: `SettingsRepository.isGuest = true` by default — no login screen at all.
- `APIClient.send(...)` short-circuits authenticated routes when `isGuest`, returning local stub responses so the existing UI keeps working.
- Public-API routes (MyHealthfinder, OpenFDA, Open Food Facts) still go to the network so guests still benefit.
- "Sign in for cloud sync" remains a one-tap upgrade in Settings.

### 4.3 Training (Apple-side rich, Android-side ported)
- **Anatomy picker** — front/back body silhouette (iOS) or region tabs (Watch / Android), drilling into muscle → exercise list → exercise detail.
- **Exercise library** — 30+ strength lifts, 3 cardio modalities, 10 stretches with steps + form tips. Bundled in Swift `ExerciseLibrary.swift` and Kotlin `Exercises.kt` (1:1 data parity).
- **Pre-built programs** — Push/Pull/Legs, Upper/Lower, Full Body 3×, Beginner Strength.
- **Workout logger** — sets / reps / weight, persisted to CloudKit-synced `ExerciseLogEntity`. Surfaces personal records.
- **Rest timer** with circular countdown (iOS).
- **Custom workout builder** — drag-reorderable exercise list, saved to CloudKit.

### 4.4 Diary, nutrition & activities
- **Food diary** — daily macro rings + 14-day history + custom-meal builder.
- **Snap Meal (iOS)** — Vision / ML Kit on-device food classification → Open Food Facts macro lookup.
- **Read Label (iOS / Android)** — Vision / ML Kit text recognition → kcal/protein/carbs/fat regex extraction.
- **Barcode scanner** — VisionKit / ML Kit barcode → Open Food Facts.
- **Activities** — non-workout movement: walking, gardening, cycling around town. Add / Edit / Delete.

### 4.5 Sleep, recovery, mood
- HealthKit / Health Connect sleep stages (REM/Deep/Core/Awake).
- Recovery score 0–100 from sleep + HRV + RHR.
- 5-emoji mood logger.
- 2-axis HKStateOfMind logger (iOS 17+).
- Wind Down sheet with breath/mindful session.

### 4.6 Vitals (full HealthKit / Health Connect coverage)
- **Cardiovascular** — HR, RHR, HRV, SpO₂, VO₂ Max, ECG count, irregular rhythm, respiratory rate.
- **Body composition** — weight, BMI, body fat %, lean mass.
- **Sensor / manual** — blood pressure, blood glucose, body temp.
- **Activity** — steps, distance, active + basal calories, exercise minutes, floors.
- **Sleep** — total + REM/Deep, wrist temp delta.
- **Environmental** — noise (dB), UV, handwashing, walking steadiness.
- Honest disclaimers in UI for non-sensorable items (body water %, hydration sensor, snoring, continuous BP).

### 4.7 Biological Age engine
- On-device, no model file, pure Swift / pure Kotlin port.
- Inputs: chronological age, sex, RHR, HRV, VO₂Max, sleep, BMI, body fat %, BP, weekly exercise min, daily steps, smoker / heavy-alcohol flags.
- Output: chronological vs biological age + per-factor ± year breakdown + confidence (scales with how many signals are present).
- Verdict line ("Younger than your age ✨" / "Right on track" / etc.).

### 4.8 Medicine reminders
- iOS: `UNUserNotificationCenter` with notification category `MEDICINE_REMINDER` and two actions (Take / Snooze 10 min).
- Android: `AlarmManager` (`setRepeating`) + `BroadcastReceiver` with the same Take / Snooze actions; `BootReceiver` re-arms after reboot.
- Persisted dose log + 14-day adherence streak + archive.
- Cron-like schedule (times of day × weekdays) stored as JSON inside the entity for easy cross-platform export.
- Optional OpenFDA drug-info lookup when adding a new medicine.

### 4.9 Health articles
- Bundled `HealthArticleSeed` (works offline / guest mode) — 6 starter articles.
- Live MyHealthfinder topics from `/api/health/topics` (no auth required).
- OpenFDA drug-label search via `/api/medicine/lookup` (no auth required).

### 4.10 Watch / Wear OS
- Vertically-paged tabs: Quick Log → Live Workout → Run → **Anatomy** → Water → Weight → Mood → History → Settings.
- Apple Watch: HKWorkoutSession, GPS routes, Workout Mirroring sender, Live Activity, complications.
- Wear OS: Health Services for live HR + GPS, Tile + Complication for Readiness.

### 4.11 Cross-platform portability
- Single canonical schema at [`shared/schemas/myhealth.schema.json`](./shared/schemas/myhealth.schema.json).
- iOS `PortabilityService.exportEverything()` writes a date-stamped JSON file to share via AirDrop / Files.
- Android side will mirror this via `data/portability/PortabilityService.kt` (export TODO).
- Erase-all-on-device action wipes every entity and resets onboarding.

---

## 5. Data Flow

### 5.1 Adding a meal (iOS, guest mode)

```
User taps "+" in Diary
        │
        ▼
NutritionView → FoodSearchView (Open Food Facts query, no auth)
        │
        ▼
SelectFood → CloudStore.addMeal(...)
        │
        ▼
NSManagedObjectContext.save() → CoreData → (iCloud sync if account)
        │
        ▼
HomeDashboardView observes today's meals → ring updates
```

### 5.2 Medicine reminder firing (iOS)

```
Cold start → MedicineReminderService.bootstrap() registers category
            │
            └─ FitFusionApp .task → resyncAll() reschedules every active medicine
                                                              │
                                                              ▼
9:00 AM today                                                 │
            │                                                 │
            ▼                                                 │
UNCalendarNotificationTrigger fires ←─────────────────────────┘
            │
            ▼
Banner shows with Take / Snooze 10 min actions
            │
            ▼
User taps Take → MedicineReminderService.handleAction("MED_TAKE", info)
            │
            ▼
CloudStore.logDose(medicineId, takenAt: now)
            │
            ▼
MedicineDetailView observes → adherence streak ticks up
```

### 5.3 Biological-age estimation (any platform)

```
VitalsView surfaces the snapshot ← VitalsService.refresh()
                                          │
                                          ▼
                           Read every HealthKit type into
                           a single VitalsSnapshot struct
                                          │
                                          ▼
User taps "Biological Age" → BiologicalAgeView
                                          │
                                          ▼
BiologicalAgeEngine.estimate(inputs)
                                          │
                                          ▼
Per-factor delta-years list + total bio age
                                          │
                                          ▼
Side-by-side gauge + sortable factor breakdown rendered on-device
```

---

## 6. Tech Stack Summary

| Concern | iOS / watchOS | Android / Wear | Web (Expo) | Backend |
|---|---|---|---|---|
| UI | SwiftUI 5 | Jetpack Compose + Material 3 | React Native | – |
| Local store | Core Data + CloudKit | Room | AsyncStorage | SQLite (better-sqlite3) |
| Settings | UserDefaults | DataStore | AsyncStorage | env vars |
| Health platform | HealthKit + WorkoutKit | Health Connect + Health Services | – | – |
| Live HR / workouts | HKWorkoutSession + WCSession | Health Services + ExerciseClient | – | – |
| Notifications | UNUserNotificationCenter | NotificationManager + AlarmManager | – | – |
| Background work | BGTaskScheduler | WorkManager | – | – |
| Vision / ML | Vision + Core ML | ML Kit + TensorFlow Lite | – | – |
| Camera | VisionKit | CameraX | – | – |
| HTTP | URLSession | Ktor | fetch | – |
| Auth | JWT (optional) | JWT (optional) | JWT (optional) | bcryptjs + jsonwebtoken |
| Tests | XCTest | JUnit + Truth + Robolectric + Compose UI | Jest | Jest + supertest |
| Build | XcodeGen | Gradle 8 + Kotlin 2.0 | Expo CLI | npm |

---

## 7. Repository Map

```
HealthApp/
├── README.md                       ← User-facing overview
├── DESIGN.md                       ← This document
├── TESTING.md                      ← Sanity-test checklist
├── RELEASING.md                    ← Release procedure + Play Store
├── index.html, styles.css, script.js   ← Marketing site
├── shared/
│   ├── FitFusionCore/              ← Swift Package, iOS + watchOS
│   └── schemas/
│       └── myhealth.schema.json    ← Canonical cross-platform JSON
├── ios/
│   ├── FitFusion/                  ← Main iOS app
│   ├── MyHealthLiveActivity/       ← Lock-screen Live Activity ext.
│   ├── MyHealthWidget/             ← Home/Lock widget ext.
│   ├── MyHealthMessages/           ← iMessage app ext.
│   └── project.yml                 ← XcodeGen
├── watch/
│   ├── HealthAppWatch/             ← watchOS app
│   └── FitFusionComplication/
├── android/
│   ├── settings.gradle.kts         ← Multi-module Gradle root
│   ├── core/                       ← Shared Kotlin: Models, Exercises, BioAge
│   ├── app/                        ← Phone app (Compose + Hilt + Room)
│   └── wear/                       ← Wear OS app (Wear Compose)
├── mobile/                         ← Expo (Android + iOS + Web)
├── server/                         ← Express + SQLite + JWT
└── .github/workflows/              ← CI / Release pipelines
```

---

## 8. Privacy posture

- All AI inference is on-device (Core ML, Vision, ML Kit, BiologicalAgeEngine).
- Guest Mode never sends personal data to any server. Public APIs (MyHealthfinder, OpenFDA, Open Food Facts) accept anonymous queries with no PII.
- Bundle ID `com.fitfusion.*` and CloudKit container `iCloud.com.fitfusion` are intentionally retained so existing CloudKit data survives the rebrand.
- HealthKit / Health Connect respect platform-level user permission gates.
- Backend uses bcrypt-hashed passwords + JWT; tokens never leave AsyncStorage / UserDefaults / DataStore on the client.
- Erase-all-data action wipes every entity from the local DB and resets onboarding.

---

## 9. Care+ tab restructure (v1.5.0 — Week 1 of 8)

> **Status:** Week 1 of the Care+ 8-week MVP build. Documented end-to-end
> in [`PRIVACY-CARE.md`](./PRIVACY-CARE.md) and the planning file at
> `.llms/plans/careplus_week1_native.plan.md`. Numbered to fit alongside
> sections 1–8 above.

### 9.1 Why

The original 5-tab consumer fitness app (Home / Train / Diary / Sleep /
More) has been restructured into the **four Care+ tabs** so the product
can carry both consumer-fitness and clinical-adjacent surfaces without
one layer drowning out the other:

```
   ┌────────┬────────┬────────┬─────────┐
   │  Care  │  Diet  │  Train │ Workout │
   └────────┴────────┴────────┴─────────┘
       │       │       │        │
       │       │       │        └── existing run / strength logger / sleep
       │       │       └── existing programs + the new standup timer
       │       └── existing food diary + the new vendor browse
       └── new MyChart connect, insurance OCR, doctor finder, care plan
```

Former More-tab destinations (Vitals, Anatomy, Articles, Profile,
Settings, Medicines, Activities) are now reachable via the **global
header avatar** (Profile sheet) and **bell** (News drawer with three
inner tabs: Urgent · For You · Wellness). No content was removed —
only re-homed.

### 9.2 Compliance / PHI plumbing

The new clinical surfaces (MyChart, insurance card, doctor favorites,
RPE log) carry HIPAA-grade PHI. To keep section 8 honest, week 1
establishes:

- **Tokens** in iOS Keychain (`shared/.../Security/KeychainStore.swift`)
  / Android EncryptedSharedPreferences
  (`data/secure/SecureTokenStore.kt`). One-time JWT migration evicts the
  legacy `UserDefaults["token"]` slot at first launch.
- **PHI rows** in a separate persistent store: iOS `PHIStore` Core Data
  stack with `NSFileProtectionComplete`; Android `MyHealthPhiDatabase`
  Room database backed by SQLCipher
  (`data/secure/PhiDatabase.kt::PhiDatabaseProvider`).
- **Audit log** for every backend PHI route — `server/middleware/auditLog.js`
  writes one row per request to `audit_log`. Mounted ahead of the new
  `/api/fhir`, `/api/vendor`, `/api/doctors`, `/api/insurance` routers.
- **Full policy** in [`PRIVACY-CARE.md`](./PRIVACY-CARE.md), including
  the BAA-status table for Epic / Ribbon Health / hosting / vendor
  partners (some still TBD — the doc tracks the gating).

### 9.3 SMART-on-FHIR (MyChart)

Real OAuth2 PKCE flow against Epic's public sandbox:
- Shared Swift module: `shared/.../FHIR/{FHIROAuthClient,FHIRClient,EpicSandboxConfig}.swift`.
- iOS `Services/FHIROAuthSession.swift` — `ASWebAuthenticationSession`.
- Android `fhir/{FhirOAuthClient,FhirRepository,EpicSandboxConfig}.kt` —
  AppAuth + Custom Tabs + Ktor.
- Backend `routes/fhir.js` — audit-logged FHIR proxy.

Production credentials wait on App Orchard approval; the URL/scope set
already documents the production swap path (single-file change).

### 9.4 Design tokens

`shared/.../DesignSystem/Theme.swift` exposes `CarePlusPalette`
(per-tab accents + status colors), `CarePlusType`, `CarePlusSpacing`,
`CarePlusRadius`. Mirrored on Android in `ui/theme/{Color,Typography,Shape}.kt`.
SF Symbols ↔ Material Icons mapping documented inline so designs sized
in Figma render at the same pixel size on both platforms.
