# Clock — iOS (iPhone)

SwiftUI app targeting iOS 17+.

## Open in Xcode

The Swift sources are checkpointed here; the Xcode project file (`.xcodeproj`) is intentionally not committed because it is best generated locally.

1. Open Xcode → **File → New → Project → iOS → App**.
2. Product Name: `Pocket`, Interface: **SwiftUI**, Language: **Swift**, Bundle ID: `com.americangroupllc.pocket`.
3. After the empty project is created, replace the generated Swift files (and `Info.plist`) with the files in this folder (`Pocket/`).
4. Select an iPhone simulator and **Run** (`⌘R`).

## Files

- `Pocket/PocketApp.swift` — `@main` entry point
- `Pocket/ContentView.swift` — Tab container (Clock / Alarm / Stopwatch / Timer)
- `Pocket/ClockView.swift` — Digital + analog clock
- `Pocket/AlarmView.swift` — Alarm list + add sheet (in-memory)
- `Pocket/StopwatchView.swift` — Stopwatch with laps
- `Pocket/TimerView.swift` — Countdown timer
