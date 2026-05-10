# Clock — Android (phone)

Kotlin + Jetpack Compose, Material 3.

## Open in Android Studio

1. Android Studio (Iguana 2023.2.1+) → **File → Open** → select this `android/` folder.
2. Let Gradle sync. (`compileSdk 34`, Compose BOM 2024.06, Kotlin 2.0.)
3. Run on a phone emulator (API 24+).

## Generate Gradle wrapper (one-time)

If `gradlew` is missing, from this `android/` folder run:

```bash
gradle wrapper --gradle-version 8.7
```

(Requires Gradle 8.x installed locally, or run from within Android Studio's terminal which provides it.)

## Files

- `app/src/main/java/com/americangroupllc/pocket/MainActivity.kt`
- `app/src/main/java/com/americangroupllc/pocket/ClockTabs.kt`
- `app/src/main/java/com/americangroupllc/pocket/ClockScreen.kt`
- `app/src/main/java/com/americangroupllc/pocket/AlarmScreen.kt`
- `app/src/main/java/com/americangroupllc/pocket/StopwatchScreen.kt`
- `app/src/main/java/com/americangroupllc/pocket/TimerScreen.kt`
