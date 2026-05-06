# Offline AI Buddy

> **Your phone-only AI. Works without internet.**

Offline AI Buddy is a phone-only on-device LLM app. After a one-time
~1 GB model download on first launch, **everything runs offline** — chat,
voice, roasts, daily challenges, party-question generator, game coach,
kid-safe mode, multilingual translator, and a system-keyboard with smart
replies inside any chat app.

| | iPhone | Android |
|---|---|---|
| Chat (multilingual: en · hi · zh · fr · es) | ✅ | ✅ |
| Voice push-to-talk + read-aloud | ✅ | ✅ |
| Live translator (any pair of 5 languages) | ✅ | ✅ |
| Roast Mode | ✅ | ✅ |
| Daily Challenge | ✅ | ✅ |
| Party Question Generator | ✅ | ✅ |
| Game Coach | ✅ | ✅ |
| System smart-reply keyboard | ✅ Keyboard Ext | ✅ InputMethodService |
| Kid-safe profile (PIN-locked) | ✅ | ✅ |
| RevenueCat subscription + AdMob ad-unlock + lifetime IAP | ✅ | ✅ |

## Stack

- **Apple**: Swift / SwiftUI, iOS 17, XcodeGen, Keyboard Extension target.
- **Android**: Kotlin / Jetpack Compose, multi-module Gradle (`:core` + `:app`),
  Hilt, DataStore, WorkManager, NDK + JNI for llama.cpp.
- **LLM runtime**: [`llama.cpp`](https://github.com/ggerganov/llama.cpp)
  via Swift bindings (iOS) + JNI (Android). Default model:
  **Qwen2.5-1.5B-Instruct-Q4_K_M.gguf** (~1.0 GB).
- **Backend**: **None.** All inference on-device. No accounts, no servers,
  no analytics by default.
- **Shared logic**: `BuddyAICore` Swift Package (Apple) and `:core` JVM
  Kotlin module (Android). Same models, mirrored case-for-case tests.

## Repo layout

```
shared/BuddyAICore # Apple-side shared models + domain helpers + tests
ios/               # iPhone app + Keyboard Extension
android/           # :core JVM + :app phone (with IME)
vendor/llama.cpp   # llama.cpp submodule (pinned commit)
.github/workflows  # 6 workflows: ci, ios, android, marketing, pre-release-tests, release
scripts/           # local dev helpers (test-all, fetch-models, bench-llama, …)
distribution/      # release whatsnew text per locale (en, hi, zh, fr, es)
```

See [`DESIGN.md`](DESIGN.md) for full architecture,
[`MODELS.md`](MODELS.md) for the GGUF catalog + SHA-256 + hardware floor,
[`KEYBOARD.md`](KEYBOARD.md) for the IME / Keyboard-Extension architecture,
[`SAFETY.md`](SAFETY.md) for kid-safe + content-policy spec, and
[`OFFLINE-AI-FEATURES.md`](OFFLINE-AI-FEATURES.md) for the v1 feature
inventory.

## Get started

```sh
# iOS Simulator
./scripts/run-ios-sim.sh

# Android emulator
./scripts/run-android-emulator.sh

# Pre-fetch the default GGUF for local dev (skips first-launch flow)
./scripts/fetch-models.sh

# Run every test suite
./scripts/test-all.sh

# Benchmark tokens/sec on the host device
./scripts/bench-llama.sh
```

## License

MIT — see [LICENSE](LICENSE).
