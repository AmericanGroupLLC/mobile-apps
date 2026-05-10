# QUICKSTART

## Prereqs

| | macOS | Linux / Windows |
|---|---|---|
| iOS | Xcode 15+, `brew install xcodegen` | n/a |
| Android | JDK 17, Android SDK 34, NDK 26+ (`ANDROID_HOME` + `ANDROID_NDK_HOME` set) | JDK 17, Android SDK 34, NDK 26+ |
| llama.cpp submodule | none — pulled in by `git submodule update --init` | same |
| Marketing site | none — open `index.html` directly | none |

## 60-second iOS spin-up (macOS)

```sh
git clone --recursive git@github.com:AmericanGroupLLC/Offline-AI-Buddy.git
cd Offline-AI-Buddy
./scripts/fetch-models.sh         # ~5–8 minutes on home Wi-Fi (~1 GB)
brew install xcodegen
./scripts/run-ios-sim.sh
```

This generates the `ios/OfflineAIBuddy.xcodeproj`, builds the Debug app,
boots iPhone 15 Simulator, installs it, and launches it. The model is
side-loaded into the simulator's documents directory so onboarding
skips the download step in dev builds.

## 60-second Android spin-up

```sh
cd Offline-AI-Buddy
./scripts/fetch-models.sh
./scripts/run-android-emulator.sh
```

Requires `ANDROID_HOME`, `ANDROID_NDK_HOME`, and at least one created
AVD (default `Pixel_6_API_34`; override with `AVD_NAME=...`).

## Cloning without the submodule (CI / quick-look)

```sh
git clone git@github.com:AmericanGroupLLC/Offline-AI-Buddy.git
cd Offline-AI-Buddy
git submodule update --init --recursive   # pulls vendor/llama.cpp
```

Until the submodule is pulled, neither the iOS Swift Package nor the
Android NDK build will compile.

## Dev workflow

```sh
# Edit shared logic in shared/BuddyAICore/Sources/...
# Or shared logic mirror in android/core/src/main/...

# Run every test suite locally (skips iOS on non-macOS)
./scripts/test-all.sh

# Just BuddyAICore
cd shared/BuddyAICore && swift test

# Just Android :core
cd android && ./gradlew :core:test

# Just Android :app unit
cd android && ./gradlew :app:testDebugUnitTest

# Tokens/sec benchmark
./scripts/bench-llama.sh

# Marketing site preview
python3 -m http.server   # then http://localhost:8000
```

## Common gotchas

- **First-launch download**: production builds download ~1 GB on first
  launch over Wi-Fi. Local dev: pre-fetch with `./scripts/fetch-models.sh`
  to skip the flow.
- **iOS keyboard extension memory cap**: ~70 MB. The keyboard CANNOT
  load the LLM directly; it talks to the main app via App Group. See
  `KEYBOARD.md`.
- **Android NDK**: build requires NDK 26+. Set `ANDROID_NDK_HOME` or the
  Gradle build will skip the JNI compile and the app will crash at
  runtime when the LLM service starts.
- **`:core` is JVM-only**: use `./gradlew :core:test`, NOT
  `:core:testDebugUnitTest`.
- **Submodule**: `vendor/llama.cpp` is a git submodule. Don't forget
  `--recursive` on first clone, and `git submodule update --init` if you
  forgot.
- **Voice STT requires permission**: prompted on first push-to-talk use,
  not at launch.
