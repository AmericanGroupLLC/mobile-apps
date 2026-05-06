# Card — iOS

XcodeGen-driven Xcode project. Source of truth is `project.yml`; the
`Card.xcodeproj` is generated and is in `.gitignore`.

## Build

```bash
brew install xcodegen
cd ios
xcodegen generate
open Card.xcodeproj
```

Targets:

- **Card** — the iPhone app.
- **CardShareExtension** — Share-sheet extension that writes to the App Group.
- **CardTests** — view-model glue tests (XCTest).
- **CardUITests** — XCUITest smoke (composer → save → row appears).

## App Group

Both the main app and the Share Extension declare:

```
group.com.americangroupllc.card
```

This must be enabled in your Apple Developer account under Identifiers → App
Groups before the Share Extension can write to the same `CardStore` the main
app reads from.

## See also

- [`SIGNING.md`](SIGNING.md) — code-signing notes.
- [`../STORE-PACKAGING.md`](../STORE-PACKAGING.md) — the watch app must be
  embedded into the iOS `.ipa` for App Store submission.
