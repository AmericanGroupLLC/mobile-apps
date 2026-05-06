# Drift

> **Meet people at your pace, in your orbit.**

A layered dating platform where people choose how they want to be discovered:
**Server**, **State**, **County**, or **ZIP**. Every chat opens with three reply
suggestions — Casual, Context, Playful — so nobody stalls in the blank textbox.
Verification before chat unlocks. Public-meetup framing instead of private
location sharing.

| | iPhone | Apple Watch | Android | Wear OS |
|---|---|---|---|---|
| Discover (4 layers) | ✅ | layer indicator | ✅ | layer indicator |
| Wave / Match | ✅ | wave-back tile | ✅ | wave-back tile |
| Smart-reply chat | ✅ | quick-reply | ✅ | quick-reply |
| Selfie verification | ✅ | — | ✅ | — |
| Voice-prompt 30s clip | ✅ | — | ✅ | — |
| Notifications | rich push | complication | FCM | tile |

## Stack

- **Apple**: Swift / SwiftUI, iOS 17, watchOS 10, XcodeGen.
- **Android**: Kotlin / Jetpack Compose, multi-module Gradle (`:core` + `:app`
  + `:wear`), Hilt, Room, DataStore.
- **Backend**: Supabase (Postgres + Auth + Storage + Realtime + Edge Functions).
  PostGIS for fuzzed-location centroid math; Row-Level Security on every
  table. Edge Functions in Deno/TypeScript.
- **Shared logic**: `DriftCore` Swift Package (Apple) and `:core` JVM Kotlin
  module (Android). Same models, mirrored case-for-case tests.

## Repo layout

```
backend/         # Supabase config, migrations, Edge Functions, seed
shared/DriftCore # Apple-side shared models + domain helpers + tests
ios/             # iPhone app + Notification Service Extension
watchos/         # Apple Watch app + WidgetKit complication
android/         # :core JVM + :app phone + :wear smartwatch
.github/workflows# 7 workflows: ci, ios, android, marketing, backend, pre-release-tests, release
scripts/         # local dev helpers (test-all, run-*-emulator, seed-supabase)
distribution/    # release whatsnew text per locale
```

See [`DESIGN.md`](DESIGN.md) for the full architecture, [`SAFETY.md`](SAFETY.md)
for verification + reporting + location-fuzzing math, and
[`DRIFT-FEATURES.md`](DRIFT-FEATURES.md) for the feature inventory.

## Get started

```sh
# Local backend (requires Supabase CLI)
./scripts/seed-supabase.sh

# iOS Simulator
./scripts/run-ios-sim.sh

# Android emulator
./scripts/run-android-emulator.sh

# Run every test suite
./scripts/test-all.sh
```

## License

MIT — see [LICENSE](LICENSE).
