# Clock — watchOS (Apple Watch)

SwiftUI app for watchOS 10+. Page-style `TabView` with **Clock**, **Stopwatch**, **Timer**.

## Open in Xcode

1. Xcode → **File → New → Project → watchOS → App** (standalone, no companion required).
2. Product Name: `PocketWatch`, Bundle ID: `com.americangroupllc.pocket.watchkitapp`, Interface **SwiftUI**.
3. Replace the generated Swift files (and `Info.plist`) with the files in this folder.
4. Choose an Apple Watch simulator and **Run**.

## Files

- `PocketWatch/PocketWatch.swift` — `@main` entry point
- `PocketWatch/ContentView.swift` — Page-style tab container
- `PocketWatch/ClockView.swift` — Digital clock
- `PocketWatch/StopwatchView.swift` — Stopwatch
- `PocketWatch/TimerView.swift` — Countdown timer

> Tip: this watch app can be paired with the iPhone target as a companion if desired by adding it to the same workspace and matching bundle IDs.
