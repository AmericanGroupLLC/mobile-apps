# MyHealth — Android (phone)

Native Kotlin + Jetpack Compose port of the iOS app. **No login required by
default**: launch the app, finish the 4-page onboarding, and you're using it.

## Stack

- Kotlin 2.0 + Jetpack Compose + Material 3 (dynamic colour on Android 12+)
- Compose Navigation with bottom tabs (Home · Train · Diary · Sleep · More)
- Hilt + KSP for DI
- Room for local persistence (mirrors iOS Core Data 1:1, see `shared/schemas/`)
- DataStore for settings + Guest-mode flag
- WorkManager + AlarmManager for medicine reminders (Take / Snooze 10 min)
- Health Connect SDK for vitals reads
- CameraX + ML Kit (image labeling, barcode, OCR) for meal photo + nutrition labels
- Ktor for HTTP (Open Food Facts / OpenFDA / MyHealthfinder — same backends as iOS)
- 5 starter languages: English, Spanish, French, German, Hindi

## Build

```bash
cd android
./gradlew :app:assembleDebug
./gradlew :app:installDebug   # on connected emulator/device
```

## Project layout

```
android/
├── settings.gradle.kts
├── build.gradle.kts                 ← root
├── gradle.properties
├── gradle/wrapper/
├── core/                            ← shared Kotlin module
│   └── src/main/java/com/myhealth/core/
│       ├── models/Models.kt         ← Profile, Meal, Activity, Medicine, …
│       ├── exercises/Exercises.kt   ← ExerciseLibrary + WorkoutPrograms
│       └── intelligence/BiologicalAgeEngine.kt
└── app/                             ← phone app
    └── src/main/
        ├── AndroidManifest.xml
        ├── java/com/myhealth/app/
        │   ├── MyHealthApp.kt       ← Hilt entry
        │   ├── MainActivity.kt
        │   ├── di/DataModule.kt
        │   ├── data/
        │   │   ├── prefs/SettingsRepository.kt
        │   │   └── room/            ← Entities, DAOs, MyHealthDatabase
        │   ├── health/HealthConnectGateway.kt
        │   ├── notifications/       ← Medicine scheduler + receivers
        │   ├── vision/MealVision.kt ← ML Kit classifier + OCR
        │   └── ui/
        │       ├── MyHealthRoot.kt
        │       ├── theme/Theme.kt
        │       ├── onboarding/      ← 4-page first-launch flow
        │       ├── home/, train/, diary/, sleep/, more/
        │       ├── medicine/, anatomy/, articles/
        │       ├── vitals/, activity/, profile/, settings/
        └── res/
            ├── values/strings.xml
            └── values-{es,fr,de,hi}/strings.xml
```

## Guest mode

`SettingsRepository.isGuest` defaults to `true`. Sign-in is opt-in from
Settings (cloud sync via the existing Express backend; not built into this
phase).

## Tests

```bash
./gradlew :app:testDebugUnitTest :core:testDebugUnitTest
./gradlew :app:connectedDebugAndroidTest
```

(Add JUnit/Truth/Robolectric tests under `app/src/test/` and instrumented
Compose tests under `app/src/androidTest/` as the test suite grows.)
