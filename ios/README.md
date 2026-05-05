# Clock — iOS (iPhone)

SwiftUI app targeting iOS 17+.

## Open in Xcode

The Swift sources are checkpointed here; the Xcode project file (`.xcodeproj`) is intentionally not committed because it is best generated locally.

1. Open Xcode → **File → New → Project → iOS → App**.
2. Product Name: `ClockApp`, Interface: **SwiftUI**, Language: **Swift**, Bundle ID: `com.americangroupllc.clockapp`.
3. After the empty project is created, replace the generated Swift files (and `Info.plist`) with the files in this folder (`ClockApp/`).
4. Select an iPhone simulator and **Run** (`⌘R`).

## Files

- `ClockApp/ClockAppApp.swift` — `@main` entry point
- `ClockApp/ContentView.swift` — Tab container (Clock / Alarm / Stopwatch / Timer)
- `ClockApp/ClockView.swift` — Digital + analog clock
- `ClockApp/AlarmView.swift` — Alarm list + add sheet (in-memory)
- `ClockApp/StopwatchView.swift` — Stopwatch with laps
- `ClockApp/TimerView.swift` — Countdown timer
