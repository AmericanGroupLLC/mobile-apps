# IMPLEMENTATION-AUDIT.md — MyHealth (Round-4 Phase-7a)

**Date:** 2026-05-08
**Repo:** `AmericanGroupLLC/HealthApp` (MyHealth)
**Source-of-truth for promised features:** [`MYHEALTH-FEATURES.md`](./MYHEALTH-FEATURES.md), synthesized from [`README.md`](./README.md), [`DESIGN.md`](./DESIGN.md), [`WORKOUT-MEDIA.md`](./WORKOUT-MEDIA.md).

---

## 1. Promised features vs. implementation

Each row = one promised feature area from `MYHEALTH-FEATURES.md`. Status:
**OK** = present in source. **GAP** = promised but not (fully) wired; see §2.

| Area | Promised | Cited by | Status | Evidence |
|---|---|---|---|---|
| Cross-platform JSON schema | `shared/schemas/myhealth.schema.json` | DESIGN.md §4.11 | OK | `Z:\home\spatchava\AmericanGroupLLC\HealthApp\shared\schemas\myhealth.schema.json` exists |
| iOS app | Swift + SwiftUI + HealthKit + CoreData/CloudKit | README.md §Apple-side architecture | OK | `Z:\home\spatchava\AmericanGroupLLC\HealthApp\ios\FitFusion\` |
| watchOS app — 9 vertical tabs incl. Anatomy | Swift + WCSession | README.md §Now runs on 5 platforms | OK | `Z:\home\spatchava\AmericanGroupLLC\HealthApp\watch\HealthAppWatch\` |
| Android phone — full bottom-nav port | Kotlin 2.0 + Compose + Room + Hilt | README.md §Now runs on 5 platforms | OK | `Z:\home\spatchava\AmericanGroupLLC\HealthApp\android\app\src\main\java\com\myhealth\app\` |
| Wear OS — 9 vertical pages incl. Anatomy | Wear Compose + Health Services + Tile + Complication | README.md §Now runs on 5 platforms | PARTIAL | Tile registered but renders placeholder — see §2 finding F2 |
| Web / Expo (Login + Guest button) | React Native | README.md §Now runs on 5 platforms | OK | `Z:\home\spatchava\AmericanGroupLLC\HealthApp\mobile\` |
| Marketing site | HTML/CSS/JS, GitHub Pages | README.md §Project Structure | OK | `Z:\home\spatchava\AmericanGroupLLC\HealthApp\index.html` |
| Guest Mode (every platform) | `AuthStore.continueAsGuest()` / `SettingsRepository.isGuest = true` | DESIGN.md §4.2 | OK | `shared/FitFusionCore/.../AuthStore.swift`, Android `SettingsRepository` |
| Onboarding 4-page flow | Welcome → Profile → Goal → Done | DESIGN.md §4.1 | OK | iOS `OnboardingView`, Android `OnboardingScreen` |
| HealthKit full read/write | `iOSHealthKitManager` | README.md §6 HealthKit Sync | OK | `ios/FitFusion/Services/iOSHealthKitManager.swift` |
| Health Connect | Android Health Connect + Health Services | DESIGN.md §6 | OK | `android/app/build.gradle.kts:103` (`connect-client:1.1.0-alpha07`) |
| Workout library + WorkoutKit Send-to-Watch | Swift `ExerciseLibrary` | README.md §1 Workout Library | OK | `shared/FitFusionCore/.../Exercises/` |
| Anatomy picker | Front/back silhouette / region tabs | DESIGN.md §4.3 | OK | iOS `Anatomy/`, Wear `Pages.kt` |
| Run Tracker — live pace + maps | CMPedometer + MapKit + Swift Charts | README.md §2 Run Tracker | OK | iOS `Run/` |
| HKWorkoutSession live workout | HKLiveWorkoutBuilder, HR zones | README.md §5 | OK | `watch/HealthAppWatch/` |
| Food diary + macro rings | iOS + Android Room | README.md §Phase 1-6 | OK | iOS `Nutrition/`, Android `food` package |
| Snap Meal (iOS) | Vision/ML Kit on-device food classification | DESIGN.md §4.4 | OK | iOS `Nutrition/SnapMealView.swift` |
| Read Label (iOS / Android) | Vision / ML Kit text recognition | DESIGN.md §4.4 | OK | ML Kit text-recognition dep at `android/app/build.gradle.kts:114` |
| Barcode scanner | VisionKit / ML Kit barcode → Open Food Facts | README.md §3 | OK | ML Kit barcode dep `android/app/build.gradle.kts:113` |
| Activities (non-workout) | walking, gardening, cleaning — add/edit/delete | README.md §Phase 1-6 | OK | iOS + Android `activities` packages |
| Sleep stages + recovery score | HealthKit / Health Connect + 0–100 score | DESIGN.md §4.5 | OK | iOS `Sleep/`, `RecoveryService` |
| Mood logger (5-emoji + HKStateOfMind) | iOS 17+ | DESIGN.md §4.5 | OK | iOS `Mood/` |
| Vitals — full HK / HC coverage | DESIGN.md §4.6 catalogue | DESIGN.md §4.6 | OK | iOS `VitalsService`, Android `vitals` |
| Biological-age engine | Pure Swift / pure Kotlin port, on-device | DESIGN.md §4.7 | OK | iOS `BiologicalAgeEngine.swift`, `android/core/.../bioage/` |
| Medicine reminders (iOS) | UNUserNotificationCenter MEDICINE_REMINDER + Take/Snooze | DESIGN.md §4.8 | OK | iOS `MedicineReminderService` |
| Medicine reminders (Android) | AlarmManager + BootReceiver + dose log + 14-day streak | DESIGN.md §4.8 | OK | Android `medicine` package |
| Health articles bundled + live | `HealthArticleSeed` + MyHealthfinder + OpenFDA | DESIGN.md §4.9 | OK | iOS + Android article packages |
| Watch tile + complication for Readiness | Compose Tile + Complication (Wear) | DESIGN.md §4.10 | PARTIAL | See finding F2 |
| Workout GIFs (GitHub Pages) | `assets/exercises/<id>.gif`, lazy-load, fallback | WORKOUT-MEDIA.md §4 | OK | `ExerciseMedia` Swift + Kotlin |
| Condition-aware exercise filter | `ExerciseLibrary.recommended(for:)` | WORKOUT-MEDIA.md §3 | OK | iOS `ExerciseLibrary.swift`, Kotlin `Exercises.kt` |
| Diet suggestions (DASH / Mediterranean / etc.) | Static map per condition | WORKOUT-MEDIA.md §5 | OK | iOS `DietSuggestionsService.swift` |
| Doctor-disclaimer banner on every condition screen | iOS + Android | WORKOUT-MEDIA.md §8 | OK | `HealthProfileView`, `DietSuggestionsView` |
| HealthConditions store (iOS) | enum + ObservableObject | WORKOUT-MEDIA.md §6 | OK | `shared/FitFusionCore/.../Health/HealthConditions.swift` |
| HealthConditions store (Android core) | enum + medical map | WORKOUT-MEDIA.md §7 | OK | `android/core/src/main/java/com/myhealth/core/health/HealthConditions.kt` |
| HealthConditions Settings toggle (Android phone) | "wire same way as crash-reports toggle" | WORKOUT-MEDIA.md §7 | **GAP** | See finding F3 |
| `PortabilityService` export (iOS) | JSON file via AirDrop / Files | DESIGN.md §4.11 | OK | iOS `PortabilityService.swift` |
| `PortabilityService` export (Android) | `data/portability/PortabilityService.kt` | DESIGN.md §4.11 | **GAP** | See finding F4 |
| Erase-all-on-device | Wipes every entity, resets onboarding | DESIGN.md §4.11, §8 | OK | iOS Settings + Android Settings:94 |
| Cloud-sync sign-in (Android Settings) | "one-tap upgrade in Settings" | DESIGN.md §4.2 | **GAP** | See finding F1 |
| Backend API — auth, profile, metrics, nutrition, insights | Express + SQLite + JWT | README.md §API Reference | OK | `server/routes/{auth,profile,health,nutrition,insights}.js` |
| Public-API routes (MyHealthfinder, OpenFDA, Open Food Facts) | No auth | README.md §Data Sources | OK | `server/routes/health.js` |
| Sentry crash reporting (5K errors/mo, opt-in) | iOS · watchOS · Android · Wear · Expo · backend | README.md §Observability | OK | `android/app/build.gradle.kts:141` |
| PostHog analytics (1M events/mo, opt-in, EU region) | iOS · Android · Expo · backend | README.md §Observability | OK | `android/app/build.gradle.kts:144` |
| Privacy contract — strip `event.user`, no health data sent | Every wrapper | README.md §Observability | OK | wrappers in iOS `Telemetry/`, Android `telemetry/` |
| iOS Live Activity ext | `MyHealthLiveActivity/` | DESIGN.md §7 | OK | `ios/MyHealthLiveActivity/` |
| iOS WidgetKit ext | `MyHealthWidget/` | DESIGN.md §7 | OK | `ios/MyHealthWidget/` |
| iOS iMessage app ext | `MyHealthMessages/` | DESIGN.md §7 | OK | `ios/MyHealthMessages/` |
| Android release signing | Implicit Play-Store requirement | RELEASING.md / SIGNING.md | **GAP** | See finding F5 |

---

## 2. Bug / TODO / placeholder findings (file:line)

### F1 — Cloud-sync sign-in is a TODO label, not wired (Android Settings)

**Severity:** P1
**File:** `Z:\home\spatchava\AmericanGroupLLC\HealthApp\android\app\src\main\java\com\myhealth\app\ui\settings\SettingsScreen.kt:90`

```kotlin
Text("Sign in for cloud sync (opens login screen — TODO)",
    color = MaterialTheme.colorScheme.primary, fontSize = 13.sp)
```

The text reads as a hyperlink-style call-to-action (`MaterialTheme.colorScheme.primary`) but has no `Modifier.clickable { … }` and no navigation hook. iOS has a working `LoginView()` sheet (`ios/FitFusion/Views/More/SettingsView.swift:27`); Android does not. DESIGN.md §4.2 promises "one-tap upgrade in Settings" — currently zero-tap (dead label).

### F2 — Wear OS `ReadinessTileService` is a hard-coded placeholder

**Severity:** P1
**File:** `Z:\home\spatchava\AmericanGroupLLC\HealthApp\android\wear\src\main\java\com\myhealth\wear\tiles\ReadinessTileService.kt`

Doc-comment (lines 18–19):
> *Minimal Readiness tile. Real value comes from the paired phone via shared storage; for now we display a placeholder so the tile registers cleanly.*

`readReadinessScore(ctx)` (lines 53–56) returns `prefs.getInt("readiness", 70)` — nothing on the phone-side ever writes that key, so every wearer sees a constant `Readiness 70`. Promised in README.md ("Tile + Complication for readiness") and DESIGN.md §4.10 ("Wear OS: … Tile + Complication for Readiness").

### F3 — `HealthConditions` Settings toggle missing in Android phone app

**Severity:** P1
**Promised by:** `Z:\home\spatchava\AmericanGroupLLC\HealthApp\WORKOUT-MEDIA.md` §7 — *"(Settings screen toggle) | TODO — wire same way as crash-reports toggle"*
**Where it should live:** `Z:\home\spatchava\AmericanGroupLLC\HealthApp\android\app\src\main\java\com\myhealth\app\ui\settings\SettingsScreen.kt`

Current `SettingsScreen.kt` exposes Account/Guest, Imperial units, Sentry crash reports, PostHog analytics, cloud-sync row (broken — see F1), Export, Erase. **No row exposes the `HealthConditions` opt-in store.** The Kotlin enum exists (`android/core/src/main/java/com/myhealth/core/health/HealthConditions.kt`) but nothing in `android/app/src/main/java/...` lets the user populate it, so Android users get the unfiltered exercise library and can never benefit from condition-aware filtering or diet suggestions. iOS wires this via `HealthProfileView.swift`.

### F4 — Android `PortabilityService.kt` export not implemented

**Severity:** P2
**Promised by:** DESIGN.md §4.11 — *"Android side will mirror this via `data/portability/PortabilityService.kt` (export TODO)."*
**Expected path:** `Z:\home\spatchava\AmericanGroupLLC\HealthApp\android\app\src\main\java\com\myhealth\app\data\portability\PortabilityService.kt`

The "Export my data (JSON)" label exists at `SettingsScreen.kt:92` but, like F1, has no click handler and no service backing. Cross-platform portability promise (move profile between iOS and Android) is one-way only.

### F5 — `signingConfigs.release` missing from Android phone `build.gradle.kts`

**Severity:** P0
**File:** `Z:\home\spatchava\AmericanGroupLLC\HealthApp\android\app\build.gradle.kts`
**Confirmed:** No `signingConfigs { … }` block anywhere in the file. The `release` build type (lines 51–54) sets only `isMinifyEnabled = false` + `proguardFiles(...)` — there is no `signingConfig = signingConfigs.findByName("release")`.

Compare with `Z:\home\spatchava\AmericanGroupLLC\BuddyPlay\android\app\build.gradle.kts`:
- Line 3: `import java.util.Properties`
- Lines 33–45: full `signingConfigs { create("release") { … } }` block reading from `keystore.properties`
- Line 50: `signingConfig = signingConfigs.findByName("release")` inside the release build type

Without this, `./gradlew assembleRelease` will fall back to the debug keystore, producing an APK that **cannot be uploaded to Google Play** (Play rejects debug-signed artifacts and rejects key changes once a track is published).

### F6 — Wear OS muscle-detail navigation stub

**Severity:** P2
**File:** `Z:\home\spatchava\AmericanGroupLLC\HealthApp\android\wear\src\main\java\com\myhealth\wear\screens\Pages.kt:42`

```kotlin
onClick = { /* navigate to muscle detail (TODO) */ },
```

Anatomy page on Wear OS shows muscle thumbnails but tapping them is a no-op. README and DESIGN both promise "Anatomy" as a first-class Wear page identical to the watchOS one.

---

## 3. Severity legend

| Severity | Definition | Examples |
|---|---|---|
| **P0** | Ships-blocking. Cannot release to a store, cannot run, or causes data loss / security risk. | F5 (no release signing config) |
| **P1** | Promised customer-facing capability is broken or missing on at least one shipped surface. | F1 (cloud-sync dead label), F2 (placeholder tile), F3 (missing Settings toggle) |
| **P2** | Promised but only partial; degrades UX but a workaround exists or another platform compensates. | F4 (Android PortabilityService), F6 (Wear nav stub) |
| **P3** | Cosmetic / documentation / nice-to-have. | (none in this audit) |

---

## 4. Summary counts

| Metric | Count |
|---|---|
| Promised feature rows audited | **47** |
| Rows = OK | **41** |
| Rows = PARTIAL | **2** (Wear OS surfaces, Watch tile/complication — both rolled into F2) |
| Rows = GAP | **4** (F1, F3, F4, F5) |
| **Total findings (F1–F6)** | **6** |
| P0 findings | **1** (F5) |
| P1 findings | **3** (F1, F2, F3) |
| P2 findings | **2** (F4, F6) |
| P3 findings | **0** |

**Recommended order to fix:** F5 → F1 → F3 → F2 → F4 → F6.
