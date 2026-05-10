# Drift — QUICKSTART

Local dev in one tab.

## Prereqs

- macOS 14+ for iOS / watchOS work; Linux/Windows works for Android + backend.
- Xcode 16 + the iOS 17 Simulator runtime.
- Android Studio Hedgehog or newer; Android SDK 34; Wear OS API 33 system image.
- JDK 17.
- [`xcodegen`](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`.
- [`supabase` CLI](https://supabase.com/docs/guides/cli) — `brew install supabase/tap/supabase`.
- [Deno](https://deno.land) ≥ 1.45 for Edge Function tests.
- (Optional) [`watchman`](https://facebook.github.io/watchman/) for fast script reruns.

## 1. Clone

```sh
git clone git@github.com:AmericanGroupLLC/DriftDate.git
cd DriftDate
```

## 2. Local backend

```sh
./scripts/seed-supabase.sh   # supabase db reset + seed 20 demo profiles
```

This boots a local Postgres + GoTrue + Realtime + Storage in Docker, runs
all three migrations, and inserts the demo profiles.

## 3. iOS Simulator

```sh
./scripts/run-ios-sim.sh   # generates Drift.xcodeproj via xcodegen, opens, runs
```

The first run prompts for Apple ID signing — use any free dev account. The
`SUPABASE_URL` and `SUPABASE_ANON_KEY` are read from
`Bundle.main.infoDictionary` and default to the local Supabase instance.

## 4. watchOS Simulator

```sh
cd watchos && xcodegen generate && open DriftWatch.xcodeproj
```

Pick the **DriftWatch** scheme and run on an Apple Watch Series 10 sim.

## 5. Android emulator

```sh
./scripts/run-android-emulator.sh   # boots pixel_6 API 33 emulator
cd android && ./gradlew :app:installDebug
```

## 6. Wear OS emulator

```sh
./scripts/run-wear-emulator.sh
cd android && ./gradlew :wear:installDebug
```

## 7. Run every test

```sh
./scripts/test-all.sh
```

Runs DriftCore Swift Package tests, `:core:test`, `:app:testDebugUnitTest`,
`:wear:testDebugUnitTest`, and Edge Function `deno test`.

## Useful one-liners

```sh
# Bump the marketing version in every project file
./scripts/bump-version.sh 1.0.1

# Dry-run a release without pushing a tag
./scripts/release-dry-run.sh

# Link the local CLI to a remote Supabase project
./scripts/link-supabase.sh <project-ref>
```
