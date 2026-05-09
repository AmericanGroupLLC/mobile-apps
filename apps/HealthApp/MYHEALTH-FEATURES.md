# MYHEALTH-FEATURES.md — v1.0 feature inventory

> Synthesized from [`README.md`](./README.md), [`DESIGN.md`](./DESIGN.md), and
> [`WORKOUT-MEDIA.md`](./WORKOUT-MEDIA.md). The customer-facing promise is
> "your personal fitness OS, on every device, with no email required."

---

## Cross-platform matrix

| Surface | Tech | Status |
|---|---|---|
| 📱 iOS (iPhone) | Swift + SwiftUI + HealthKit + CoreData/CloudKit | Full feature set |
| ⌚ watchOS (Apple Watch) | Swift + SwiftUI + HKWorkoutSession + WCSession | 9 vertical tabs incl. Anatomy |
| 🤖 Android (phone) | Kotlin 2.0 + Compose + Room + Health Connect + ML Kit + Hilt | Full bottom-nav port |
| ⌚ Wear OS | Kotlin + Wear Compose + Health Services + Tile + Complication | 9 vertical pages incl. Anatomy |
| 🌐 Expo (Android + iOS + Web) | React Native | Login + Guest button |
| 🌐 Marketing site | Static HTML/CSS/JS | GitHub Pages |

---

## Onboarding & accounts

- [x] 4-page first-launch flow: Welcome → Profile (name, DOB, sex, height, weight, units) → Goal → Done.
- [x] Goal picker: lose / maintain / build / endurance / general.
- [x] Onboarding gated by `UserDefaults.didOnboard` (iOS) / `DataStore` (Android).
- [x] **Guest Mode globally** — iOS / watchOS / Web `AuthStore.continueAsGuest()`; Android `SettingsRepository.isGuest = true` by default. Launch and use without an email.
- [x] Existing JWT login path preserved as a one-tap upgrade ("Sign in for cloud sync").
- [x] `APIClient.send(...)` short-circuits authenticated routes when guest, returning local stub responses.

## Health Tracking — Vitals (HealthKit / Health Connect)

- [x] **Cardiovascular** — HR, RHR, HRV, SpO₂, VO₂ Max, ECG count, irregular rhythm, respiratory rate.
- [x] **Body composition** — weight, BMI, body fat %, lean mass.
- [x] **Sensor / manual** — blood pressure, blood glucose, body temp.
- [x] **Activity** — steps, distance, active + basal calories, exercise minutes, floors.
- [x] **Sleep** — total + REM/Deep/Core/Awake stages, wrist temp delta.
- [x] **Environmental** — noise (dB), UV, handwashing, walking steadiness.
- [x] Honest disclaimers in UI for non-sensorable items (body water %, hydration sensor, snoring, continuous BP).

## Health Tracking — Sleep, recovery, mood

- [x] HealthKit / Health Connect sleep stages chart.
- [x] 0–100 recovery score from sleep + HRV + RHR with traffic-light zones.
- [x] 7-day HRV trend.
- [x] 5-emoji mood logger.
- [x] 2-axis HKStateOfMind logger (iOS 17+).
- [x] Wind Down sheet with guided breath / mindful session.

## Health Tracking — Biological-age engine

- [x] On-device, no model file — pure Swift / pure Kotlin port.
- [x] Inputs: chronological age, sex, RHR, HRV, VO₂Max, sleep, BMI, body fat %, BP, weekly exercise min, daily steps, smoker / heavy-alcohol flags.
- [x] Output: chronological vs biological age + per-factor ± year breakdown + confidence (scales with available signals).
- [x] Verdict line ("Younger than your age ✨" / "Right on track" / etc.).

## Workouts — Training

- [x] **Anatomy picker** — front/back body silhouette (iOS) or region tabs (Watch / Android), drilling into muscle → exercise list → exercise detail.
- [x] **Exercise library** — 30+ strength lifts, 3 cardio modalities, 10 stretches with steps + form tips. 1:1 parity between Swift `ExerciseLibrary.swift` and Kotlin `Exercises.kt`.
- [x] **Pre-built programs** — Push/Pull/Legs, Upper/Lower, Full Body 3×, Beginner Strength.
- [x] **Workout logger** — sets / reps / weight, persisted to `ExerciseLogEntity`. Surfaces personal records.
- [x] **Rest timer** with circular countdown (iOS).
- [x] **Custom workout builder** — drag-reorderable exercise list, saved to CloudKit.
- [x] **Send to Watch** via WorkoutKit — workout appears in the native Watch Workout app.
- [x] **Run Tracker** — live pace + distance on Watch (CMPedometer); route maps + pace/elevation charts on iPhone (MapKit + Swift Charts).

## Workouts — Media + condition-aware filtering

- [x] Exercise GIFs / images served from GitHub Pages (`assets/exercises/<id>.gif`), lazy-loaded, graceful SF Symbol / Material icon fallback on 404.
- [x] `EXERCISE_MEDIA_BASE_URL` build-time override for private CDN.
- [x] **Health-conditions store** (opt-in, on-device only, never sent to server, never logged via analytics) — Cardiovascular, Metabolic, Respiratory, Musculoskeletal, Pregnancy / Kidney / Liver / Anemia.
- [x] `ExerciseLibrary.recommended(for: userConditions)` filters out cautioned exercises and boosts beneficial ones (e.g. hides Back Squat / Deadlift for hypertension, promotes Cat-Cow / Hip Thrust for lower-back pain).
- [x] `DietSuggestionsService` static map per condition — pattern (DASH / Mediterranean / low-GI / low-sodium), foods to favor, foods to limit, daily targets, rationale.
- [x] **Doctor-disclaimer banner** on every condition-driven screen; 6-month re-confirm prompt via `lastDoctorReview`.

## Diary, nutrition & activities

- [x] **Food diary** — daily macro rings + 14-day history + custom-meal builder (iOS + Android Room).
- [x] **Snap Meal (iOS)** — Vision / ML Kit on-device food classification → Open Food Facts macro lookup.
- [x] **Read Label (iOS / Android)** — Vision / ML Kit text recognition → kcal / protein / carbs / fat regex extraction.
- [x] **Barcode scanner** — VisionKit / ML Kit barcode → Open Food Facts → macros written to HealthKit as `HKCorrelation`.
- [x] **Activities** — non-workout movement (walking, gardening, cycling, cleaning) with full add / edit / delete.

## Medicine reminders

- [x] iOS: `UNUserNotificationCenter` with notification category `MEDICINE_REMINDER`, Take / Snooze 10 min actions.
- [x] Android: `AlarmManager.setRepeating` + `BroadcastReceiver` with same actions; `BootReceiver` re-arms after reboot.
- [x] Persisted dose log + 14-day adherence streak + archive.
- [x] Cron-like schedule (times of day × weekdays) stored as JSON for cross-platform export.
- [x] Optional OpenFDA drug-info lookup via `/api/medicine/lookup` (no auth).

## Health articles

- [x] Bundled offline-readable `HealthArticleSeed` (works in guest mode) — 6 starter articles.
- [x] Live MyHealthfinder topics via `/api/health/topics` (no auth).
- [x] OpenFDA drug-label search via `/api/medicine/lookup` (no auth).

## Apple Watch surfaces

- [x] `HKWorkoutSession` + `HKLiveWorkoutBuilder` with always-on display, HR zones, calories, elapsed time.
- [x] Run mode adds live pace.
- [x] GPS routes.
- [x] Workout Mirroring sender.
- [x] Live Activity (lock-screen).
- [x] Watch complication for Readiness on watch face.
- [x] iMessage app extension (`MyHealthMessages`) for activity cards.
- [x] Vertically-paged tabs: Quick Log → Live Workout → Run → **Anatomy** → Water → Weight → Mood → History → Settings.

## Wear OS surfaces

- [x] Vertically-paged tabs (9 pages) mirroring the Apple Watch shape, incl. Anatomy.
- [x] Health Services for live HR + GPS via `ExerciseClient`.
- [x] **Tile** for Readiness.
- [x] **Complication** for Readiness.

## Cross-platform sync & portability

- [x] Single canonical schema at [`shared/schemas/myhealth.schema.json`](./shared/schemas/myhealth.schema.json) — Apple Core Data and Android Room entities map 1:1.
- [x] iOS `PortabilityService.exportEverything()` writes a date-stamped JSON file to share via AirDrop / Files.
- [x] CloudKit sync for iOS / watchOS (`iCloud.com.fitfusion`, 15 entities) when user is signed in.
- [x] Erase-all-on-device action wipes every entity and resets onboarding.
- [ ] Android `data/portability/PortabilityService.kt` export (deferred — see DESIGN.md §4.11).

## Backend API (Express + SQLite)

- [x] `GET /api/health-check` — liveness.
- [x] `POST /api/auth/register`, `POST /api/auth/login` — bcrypt + JWT.
- [x] `GET /api/profile`, `PUT /api/profile` — profile + BMI.
- [x] `POST /api/profile/metrics`, `GET /api/profile/metrics?type=…` — log + list.
- [x] `POST /api/nutrition/meal`, `GET /api/nutrition/today` — meals + totals.
- [x] `GET /api/insights/readiness`, `GET /api/insights/weekly`.
- [x] `GET /api/health/topics`, `GET /api/health/topic/:id` — MyHealthfinder (public).
- [x] `GET /api/health/drug?name=…` and `/api/medicine/lookup` — OpenFDA (public).

## Settings

- [x] Account / sign in / guest toggle.
- [x] Imperial vs metric units.
- [x] Theme (Material 3 dynamic on Android; system / light / dark).
- [x] 5 localizations on Android (`en`, `es`, `fr`, `de`, `hi`).
- [x] Crash reports — Sentry (off by default).
- [x] Anonymous usage analytics — PostHog (off by default).
- [x] Export my data (JSON).
- [x] Erase all on-device data.
- [ ] Android Settings toggle for Health-conditions store (deferred — see WORKOUT-MEDIA.md §7).
- [ ] Android Settings "Sign in for cloud sync" wiring (deferred).

## Telemetry & observability (all free tier, all opt-in)

- [x] **Sentry** — crashes + APM + logs (5K errors/mo): iOS · watchOS · Android · Wear · Expo · backend.
- [x] **PostHog** — product analytics + feature flags + replays (1M events/mo, OSS, EU region): iOS · Android · Expo · backend.
- [x] Privacy contract: every SDK off by default; wrappers strip `event.user`; no health data, meal contents, medicine names, photos, or screen recordings ever sent.
- [x] Grafana Cloud Free + UptimeRobot — server metrics + uptime (docs only).

## Privacy posture

- [x] All AI inference on-device (Core ML, Vision, ML Kit, BiologicalAgeEngine).
- [x] Nightly `MLUpdateTask` fine-tuning runs locally via `BGTaskScheduler`.
- [x] Guest Mode never sends personal data to any server.
- [x] Bundle ID `com.fitfusion.*` and CloudKit container `iCloud.com.fitfusion` retained so existing CloudKit data survives the rebrand.
- [x] HealthKit / Health Connect respect platform-level user permission gates.
- [x] Backend uses bcrypt-hashed passwords + JWT; tokens never leave AsyncStorage / UserDefaults / DataStore on the client.

## Distribution

- [x] iOS App Store (`distribution/app-store/`) — privacy nutrition labels, what's-new copy.
- [x] Google Play (`distribution/play-store/`) — Data safety form, what's-new copy.
- [x] Desktop wrapper (Electron) under `desktop/`.
- [x] Marketing site at root (`index.html`, `styles.css`, `script.js`) — auto-deployed by `marketing.yml`.

---

## NOT in v1 (explicitly)

- [ ] SensorKit deep-context (requires separate Apple entitlement approval).
- [ ] Apple Game Center leaderboards (`LeaderboardClient` flag, off by default).
- [ ] Apple Vision Pro spatial coach view.
- [ ] Offline workout playback (downloaded media).
- [ ] Insulin-dosing calculator, arrhythmia detection, ECG interpretation, calorie auto-meal-planner — all out of scope (FDA SaMD line).
- [ ] Android `PortabilityService` export.
- [ ] Android Settings toggle for Health-conditions opt-in.
- [ ] Wear OS Readiness tile real value (currently placeholder reading SharedPreferences).
- [ ] Release signing config for Android phone app (`signingConfigs.release`).
