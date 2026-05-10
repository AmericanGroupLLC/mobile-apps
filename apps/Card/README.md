# Card

> **Nothing you write gets forgotten or ignored.**
>
> One feed. Every entry is a Card. Tap once to convert any Card into a Note,
> Task, or Reminder. No folders. No categories. No search to fall back on.
> Sub-three-seconds from thought to stored, on every device you own.

[![CI](https://github.com/AmericanGroupLLC/Card/actions/workflows/ci.yml/badge.svg)](https://github.com/AmericanGroupLLC/Card/actions/workflows/ci.yml)
[![iOS](https://github.com/AmericanGroupLLC/Card/actions/workflows/ios.yml/badge.svg)](https://github.com/AmericanGroupLLC/Card/actions/workflows/ios.yml)
[![Android](https://github.com/AmericanGroupLLC/Card/actions/workflows/android.yml/badge.svg)](https://github.com/AmericanGroupLLC/Card/actions/workflows/android.yml)
[![Marketing](https://github.com/AmericanGroupLLC/Card/actions/workflows/marketing.yml/badge.svg)](https://github.com/AmericanGroupLLC/Card/actions/workflows/marketing.yml)
[![codecov](https://codecov.io/gh/AmericanGroupLLC/Card/branch/main/graph/badge.svg)](https://codecov.io/gh/AmericanGroupLLC/Card)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Card is a single open-source app that runs on iPhone, Apple Watch, Android, and
Wear OS. The product surface is a single feed and a single composer — that's it.
Anything you type, dictate, or share into Card becomes a Card. From there a
single tap converts it into:

- A **Note** (default, no further behaviour)
- A **Task** (gains a checkbox; sort to the bottom when done)
- A **Reminder** (gains a date picker; fires through the OS notification stack)

The point of Card is that the loop from "I just had a thought" to "it's safely
stored" is **sub-three-seconds**, regardless of which device you're holding.

---

## The four-platform matrix

| Surface              | iPhone                | Apple Watch         | Android              | Wear OS             |
|----------------------|-----------------------|---------------------|----------------------|---------------------|
| Feed                 | ✅                    | ✅ digital crown    | ✅                   | ✅                  |
| Inline composer      | ✅                    | ✅ voice-first      | ✅                   | ✅ voice-first      |
| Convert → Task       | ✅                    | ✅                  | ✅                   | ✅                  |
| Reminders            | UNUserNotifications   | UNUserNotifications | AlarmManager         | AlarmManager        |
| Quick-capture surface | Share Extension       | Complication        | Quick Settings tile  | Tile + Complication |
| Storage              | JSON (App Group)      | JSON (shared)       | Room (SQLite)        | Room (SQLite)       |

The domain logic lives in a single shared core — `CardCore` (Swift Package) on
Apple, `:core` (Kotlin/JVM) on Android — with **mirrored case-for-case unit tests**.

---

## Repo map

```
.
├── shared/CardCore/           Swift Package (iOS 17+, watchOS 10+) — Card model,
│                              CardKindTransitions, ReminderScheduler, CardSorter,
│                              CardStore (App-Group-aware), Sentry/PostHog stubs
│
├── ios/                       XcodeGen project: Card app + CardShareExtension
├── watchos/                   XcodeGen project: CardWatch + Quick-capture
│                              complication
├── android/
│   ├── core/                  Pure Kotlin/JVM — same domain as CardCore
│   ├── app/                   Compose phone app + Quick Settings tile
│   └── wear/                  Wear Compose app + tile + complication
│
├── scripts/                   bump-version, test-all, release-dry-run, sim/emu
├── distribution/whatsnew/     Play / TestFlight release notes
├── .github/workflows/         6-workflow CI/CD (ci, ios, android, marketing,
│                              pre-release-tests, release)
└── (root: index.html, styles.css, script.js)   marketing site → GitHub Pages
```

See [`DESIGN.md`](DESIGN.md) for the layered architecture map and per-platform
sensor / storage / notification stack.

---

## Run it locally

| Platform        | Command                                                          |
|-----------------|------------------------------------------------------------------|
| iPhone (sim)    | `./scripts/run-ios-sim.sh` (macOS, requires `xcodegen`)          |
| Android (emu)   | `./scripts/run-android-emulator.sh` (set `ANDROID_HOME`)         |
| Wear OS (emu)   | `./scripts/run-wear-emulator.sh` (set `WEAR_AVD_NAME`)           |
| Run all tests   | `./scripts/test-all.sh`                                          |
| Release dry-run | `./scripts/release-dry-run.sh v0.1.0`                            |

See [`QUICKSTART.md`](QUICKSTART.md) for the fastest setup on each platform and
[`TESTING.md`](TESTING.md) for the manual test checklist (capture loop, reminder
fires, share extension, Quick Settings tile).

---

## What ships in v1

Brutally minimal — see [`CARD-FEATURES.md`](CARD-FEATURES.md):

- ✅ Single feed of Cards, newest-first, all on-device
- ✅ Inline composer at top
- ✅ One-tap convert: Note ↔ Task ↔ Reminder
- ✅ Real OS-scheduled reminders (UNUserNotifications / AlarmManager)
- ✅ Swipe-to-delete, long-press to edit
- ✅ Settings: 12/24-hour, theme, opt-in Sentry/PostHog, erase-all-data
- ✅ Four quick-capture surfaces:
  - iOS Share Extension (any selected text → Card, no app launch)
  - Apple Watch complication (Quick capture → voice composer)
  - Android Quick Settings tile (one tap → voice composer)
  - Wear OS tile (one tap → composer)

What's explicitly **not** in v1: tags, folders, search, cloud sync, AI features,
recurring reminders, sharing/collaboration, IAP scaffolding, home-screen widgets
beyond the surfaces above. See [`PRODUCTION.md`](PRODUCTION.md) for the full gap
audit and the v1.1 candidate list.

---

## License

MIT — see [`LICENSE`](LICENSE).
