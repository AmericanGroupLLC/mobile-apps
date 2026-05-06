# Pocket 🪶 — Five Native Utilities, Four Platforms

[![CI](https://github.com/AmericanGroupLLC/Pocket/actions/workflows/ci.yml/badge.svg)](https://github.com/AmericanGroupLLC/Pocket/actions/workflows/ci.yml)
[![iOS](https://github.com/AmericanGroupLLC/Pocket/actions/workflows/ios.yml/badge.svg)](https://github.com/AmericanGroupLLC/Pocket/actions/workflows/ios.yml)
[![Android](https://github.com/AmericanGroupLLC/Pocket/actions/workflows/android.yml/badge.svg)](https://github.com/AmericanGroupLLC/Pocket/actions/workflows/android.yml)
[![Marketing site](https://github.com/AmericanGroupLLC/Pocket/actions/workflows/marketing.yml/badge.svg)](https://github.com/AmericanGroupLLC/Pocket/actions/workflows/marketing.yml)
[![codecov](https://codecov.io/gh/AmericanGroupLLC/Pocket/branch/main/graph/badge.svg)](https://codecov.io/gh/AmericanGroupLLC/Pocket)

📖 **Docs**: [QUICKSTART](./QUICKSTART.md) · [DESIGN](./DESIGN.md) · [TESTING](./TESTING.md) · [RELEASING](./RELEASING.md) · [PRODUCTION](./PRODUCTION.md) · [STORE-PACKAGING](./STORE-PACKAGING.md) · [SENTRY](./SENTRY.md) · [OBSERVABILITY](./OBSERVABILITY.md) · [TOOLS-FEATURES](./TOOLS-FEATURES.md) · [PRIVACY](./PRIVACY.md)

---

> *Five tools that disappear into the OS. Clock · Calculator · Measure · Compass · Level — one app, four native UIs, zero account, no tracking by default.*

---

## The five tools

1. **Clock** — alarms, world clock, stopwatch, timer, bedtime. Real OS-scheduled alarms.
2. **Calculator** — basic + scientific (rotate to landscape on iPhone).
3. **Measure** — ARKit on iOS, ARCore on Android, on-screen ruler fallback.
4. **Compass** — magnetic + true heading, lat/lon, accuracy ring.
5. **Level** — flat-surface bullseye + tilted-surface bubble.

## Platforms

| Platform | Folder | Stack | Bundle ID |
|---|---|---|---|
| 📱 **iPhone** | [`ios/`](./ios/) | Swift + SwiftUI + ARKit (iOS 17+) | `com.americangroupllc.pocket` |
| ⌚ **Apple Watch** | [`watchos/`](./watchos/) | Swift + SwiftUI + WidgetKit (watchOS 10+) | `com.americangroupllc.pocket` (`.complication` for widget) |
| 🤖 **Android phone** | [`android/app/`](./android/app/) | Kotlin + Compose + Hilt + Room + ARCore (API 24+) | `com.americangroupllc.pocket` |
| ⌚ **Wear OS** | [`android/wear/`](./android/wear/) | Kotlin + Wear Compose + Tile + Complication (API 30+) | `com.americangroupllc.pocketwear` |

> After renaming the GitHub repo to `Pocket`, update `index.html` canonical + OG URLs and `sitemap.xml`. The marketing site will continue to be served from `/ClockApp/` until the repo rename.

Plus the public-facing **marketing site** (`index.html` / `styles.css` / `script.js`) at the repo root.

---

## Tool × Platform matrix

|  | Clock | Calculator | Measure | Compass | Level |
|---|:---:|:---:|:---:|:---:|:---:|
| iPhone | ✅ | ✅ basic + scientific | ✅ ARKit | ✅ + lat/lon | ✅ flat + tilted |
| Apple Watch | ✅ | ✅ basic | — | ✅ heading-only | ✅ flat |
| Android phone | ✅ | ✅ basic + scientific | ✅ ARCore | ✅ + lat/lon | ✅ flat + tilted |
| Wear OS | ✅ (no on-device alarms) | ✅ basic | — | ✅ heading-only | ✅ flat |

> Wear OS skips on-device alarms by design — phone alarms surface on the watch via the standard companion bridge. Measure is phone-only (no AR on watches).

Per-tool capabilities, sensor stacks, and data flows: [`TOOLS-FEATURES.md`](./TOOLS-FEATURES.md).

---

## Architecture at a glance

```
Pocket/
├── shared/PocketCore/   Swift Package (iOS + watchOS): Clock + Calculator +
│                        Compass + Level domain logic + Analytics/Crash stubs.
├── ios/                 SwiftUI iPhone app (XcodeGen) — 5 tools.
├── watchos/             SwiftUI Apple Watch app (XcodeGen) — 4 tools +
│                        WidgetKit complication.
└── android/             Multi-module Gradle project:
    ├── core/   :core    Kotlin library: same 5-tool domain logic,
    │                    obs stubs, mirrored tests.
    ├── app/    :app     Phone Compose app + Hilt + Room + AlarmManager +
    │                    BootReceiver + ARCore (Measure) + sensor wrappers.
    └── wear/   :wear    Wear Compose app + Tile + Complication services.
```

Each platform uses its idiomatic UI framework and language. Apple platforms share a Swift Package (`PocketCore`); Android phone + wear share a Gradle module (`:core`).

---

## 🔭 Observability (free tier, off-by-default)

| Concern | Tool | Free tier | Wired in |
|---|---|---|---|
| Crashes / APM | **Sentry** | 5K errors/mo | iOS · watchOS · Android · Wear |
| Product analytics | **PostHog** | 1M events/mo (OSS, EU) | iOS · Android |

**Privacy contract**: every SDK is **off by default**. Users opt in via Settings → Privacy. Wrappers strip user identifiers and never send tool inputs (no calculator history, no headings, no AR measurements, no alarm names). Real install steps in [`OBSERVABILITY.md`](./OBSERVABILITY.md) and [`SENTRY.md`](./SENTRY.md).

---

## 🚀 Run It

### iOS (iPhone)

```bash
brew install xcodegen
cd ios && xcodegen generate && open Pocket.xcodeproj
```

Pick an iPhone 15 simulator + ▶️. See [`ios/README.md`](./ios/README.md) and [`ios/SIGNING.md`](./ios/SIGNING.md).

### watchOS (Apple Watch)

```bash
brew install xcodegen
cd watchos && xcodegen generate && open PocketWatch.xcodeproj
```

### Android (phone)

```bash
cd android
gradle wrapper --gradle-version 8.10   # one-time
./gradlew :app:installDebug
```

### Wear OS

```bash
cd android
./gradlew :wear:installDebug
```

### One-line: run every test on the current OS

```bash
./scripts/test-all.sh
```

---

## Roadmap (post-v1)

- [ ] Phone ↔ Watch sync (alarms, calculator history, level calibration)
- [ ] Apple WidgetKit lock-screen widgets + Android Glance widgets
- [ ] Custom alarm sound packs
- [ ] Optional iCloud / Google Drive backup of settings
- [ ] CarPlay & Android Auto next-alarm card
- [ ] Multi-segment AR Measure (area, volume) — explicitly deferred from v1

---

## License

MIT — see [LICENSE](./LICENSE).
