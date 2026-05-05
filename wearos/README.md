# Clock — Wear OS (Android Watch)

Standalone Wear OS app using **Wear Compose Material** + horizontal pager (Clock / Stopwatch / Timer).

## Open in Android Studio

1. Android Studio → **File → Open** → select this `wearos/` folder.
2. Let Gradle sync (Compose BOM 2024.06, Wear Compose 1.3.x, Kotlin 2.0).
3. Run on a Wear OS emulator (API 30+).

## Generate Gradle wrapper (one-time)

```bash
gradle wrapper --gradle-version 8.7
```

## Files

- `app/src/main/java/com/americangroupllc/clockwear/MainActivity.kt`
- `app/src/main/java/com/americangroupllc/clockwear/ClockScreen.kt`
- `app/src/main/java/com/americangroupllc/clockwear/StopwatchScreen.kt`
- `app/src/main/java/com/americangroupllc/clockwear/TimerScreen.kt`

> The manifest declares `<uses-feature android:name="android.hardware.type.watch"/>` and `standalone=true` so the app can run without a paired phone.
