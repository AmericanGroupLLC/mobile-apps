# MyHealth — Wear OS

Wear Compose port of the watchOS app. Vertically-paged tabs mirror the
iPhone-paired Apple Watch experience.

## Stack

- Kotlin + Wear Compose Material + Wear Compose Foundation
- Health Services API (live HR / GPS workouts via `HealthServicesGateway`)
- One Tile (`ReadinessTileService`) and one Complication
  (`ReadinessComplicationService`) — both backed by a `SharedPreferences` value
  the phone app updates so the watch face can show your latest readiness.
- Standalone-capable: `com.google.android.wearable.standalone = true`

## Pages (top to bottom)

1. Quick Log
2. Live Workout
3. Run (GPS route via Health Services)
4. **Anatomy** — body-region picker drilling into the shared `core` module's
   `ExerciseLibrary`
5. Water
6. Weight
7. Mood
8. History
9. Settings

## Build

```bash
cd android
./gradlew :wear:installDebug   # install on a Wear OS emulator / device
```
