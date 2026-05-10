# Card — watchOS

Standalone watchOS XcodeGen project for development. The shipping watch app
must be embedded inside the iOS `.ipa`; see [`../STORE-PACKAGING.md`](../STORE-PACKAGING.md).

## Build

```bash
brew install xcodegen
cd watchos
xcodegen generate
open CardWatch.xcodeproj
```

Targets:

- **CardWatch** — the watch app (`WindowGroup` + Wear feed + voice composer).
- **CardComplication** — WidgetKit complication ("Card – Quick capture").
  Supports `.accessoryCircular`, `.accessoryInline`, `.accessoryRectangular`.
  Tapping it deep-links to the composer via `card://composer`.

The composer relies on watchOS's built-in dictation (TextField) which is the
voice path. `SFSpeechRecognizer` and the `Speech` framework are linked but
the system dictation handles the common case.
