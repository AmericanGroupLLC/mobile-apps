# Clock — watchOS (Apple Watch)

SwiftUI app for watchOS 10+. Page-style `TabView` with **Clock**, **Stopwatch**, **Timer**.

## Open in Xcode

1. Xcode → **File → New → Project → watchOS → App** (standalone, no companion required).
2. Product Name: `ClockWatchApp`, Bundle ID: `com.americangroupllc.clockapp.watchkitapp`, Interface **SwiftUI**.
3. Replace the generated Swift files (and `Info.plist`) with the files in this folder.
4. Choose an Apple Watch simulator and **Run**.

## Files

- `ClockWatchApp/ClockWatchApp.swift` — `@main` entry point
- `ClockWatchApp/ContentView.swift` — Page-style tab container
- `ClockWatchApp/ClockView.swift` — Digital clock
- `ClockWatchApp/StopwatchView.swift` — Stopwatch
- `ClockWatchApp/TimerView.swift` — Countdown timer

> Tip: this watch app can be paired with the iPhone target as a companion if desired by adding it to the same workspace and matching bundle IDs.
