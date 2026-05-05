# ClockApp — A Cross-Platform Clock (iOS, watchOS, Android, Wear OS)

A Clock app inspired by the iPhone's stock Clock app, scaffolded as **four native projects** for maximum platform fidelity.

| Platform        | Folder       | Stack                              |
| --------------- | ------------ | ---------------------------------- |
| iPhone          | `ios/`       | Swift + SwiftUI (iOS 17+)          |
| Apple Watch     | `watchos/`   | Swift + SwiftUI (watchOS 10+)      |
| Android phone   | `android/`   | Kotlin + Jetpack Compose (API 24+) |
| Android watch   | `wearos/`    | Kotlin + Wear Compose (API 30+)    |

## Features (per platform)

|                | Clock | Alarm | Stopwatch | Timer |
| -------------- | :---: | :---: | :-------: | :---: |
| iOS (iPhone)   |  ✅   |  ✅   |    ✅     |  ✅   |
| watchOS        |  ✅   |  —    |    ✅     |  ✅   |
| Android phone  |  ✅   |  ✅   |    ✅     |  ✅   |
| Wear OS        |  ✅   |  —    |    ✅     |  ✅   |

> Alarms are intentionally simplified (in-memory, no system scheduling). Wiring system alarms is a follow-up — see "Roadmap" below.

## Architecture at a glance

```
ClockApp/
├── ios/        SwiftUI – TabView with Clock / Alarm / Stopwatch / Timer
├── watchos/    SwiftUI – Page-style TabView with Clock / Stopwatch / Timer
├── android/    Compose Material 3 – NavigationBar with 4 tabs
└── wearos/     Wear Compose Material – HorizontalPager with 3 screens
```

Each platform uses its idiomatic UI framework, language, and package manager — no shared codebase. This keeps every app feeling truly native and lets each evolve independently.

If/when shared logic (e.g. timezones, alarm storage) becomes valuable, candidates to consider later:

- **Kotlin Multiplatform Mobile (KMM)** for shared business logic across Android + iOS.
- **A small Swift package** that both `ios/` and `watchos/` link.

## Build & run

### iOS (iPhone)

See [`ios/README.md`](ios/README.md). TL;DR — open Xcode, create a new SwiftUI app named `ClockApp`, drop in the source files, run on an iPhone simulator.

### watchOS (Apple Watch)

See [`watchos/README.md`](watchos/README.md). TL;DR — Xcode → new watchOS App, drop in the source files, run on an Apple Watch simulator.

### Android (phone)

See [`android/README.md`](android/README.md). TL;DR —

```bash
cd android
gradle wrapper --gradle-version 8.7      # one-time, if no gradlew yet
./gradlew assembleDebug
```

Then open the `android/` folder in Android Studio and Run.

### Wear OS (Android Watch)

See [`wearos/README.md`](wearos/README.md). TL;DR —

```bash
cd wearos
gradle wrapper --gradle-version 8.7      # one-time
./gradlew assembleDebug
```

Then open the `wearos/` folder in Android Studio and Run on a Wear OS emulator.

## Roadmap

- [ ] Real alarm scheduling (iOS `UNUserNotificationCenter`, Android `AlarmManager`).
- [ ] World clock with multiple timezones.
- [ ] Bedtime/Sleep schedule.
- [ ] Watch complications (watchOS `WidgetKit`, Wear OS `Tiles`/`Complications`).
- [ ] Phone ↔ Watch sync (WatchConnectivity, Wear Data Layer).
- [ ] Persistent storage (SwiftData / Room).
- [ ] CI: GitHub Actions (Xcode build for iOS/watchOS, Gradle build for Android/Wear).

## License

MIT — see [LICENSE](LICENSE).
