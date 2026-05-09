# Android — Offline AI Buddy

Multi-module Gradle build:

- `:core` — pure-Kotlin/JVM mirror of `BuddyAICore`. Test task is
  `:core:test` (NOT `:core:testDebugUnitTest`).
- `:app` — Compose phone app + JNI llama.cpp bridge + Buddy IME.

## Local run

```sh
./scripts/run-android-emulator.sh
```

## NDK build

`:app` invokes CMake to build `liboffline_ai_buddy.so` from
`vendor/llama.cpp` (submodule). When the submodule is missing,
`CMakeLists.txt` falls back to a stub variant that lets the Kotlin
external functions still link — the LlamaService then routes through
its built-in canned-echo fallback.

## Module map

```
android/
├── settings.gradle.kts            includes :core, :app
├── build.gradle.kts               root plugins
├── gradle.properties
├── core/
│   ├── build.gradle.kts           pure-Kotlin/JVM
│   └── src/main/java/.../core/    models + domain + storage + monetization + observability
└── app/
    ├── build.gradle.kts           Hilt + Compose + WorkManager + RevenueCat + AdMob + NDK
    ├── src/main/AndroidManifest.xml
    ├── src/main/cpp/              llama.cpp JNI
    ├── src/main/res/xml/method.xml IME metadata
    └── src/main/java/.../offlineaibuddy/
        ├── OfflineAIBuddyApplication.kt
        ├── MainActivity.kt
        ├── di/AppModule.kt
        ├── ui/RootNav.kt
        ├── chat/, roast/, dailychallenge/, partyquestions/, gamecoach/, translate/
        ├── home/, profile/, settings/, onboarding/
        ├── llm/                   LlamaJni, LlamaService, ModelDownloadWorker
        ├── voice/                 AndroidVoice (TTS + STT)
        ├── monetization/          RevenueCat + AdMob impls
        └── keyboard/              BuddyInputMethodService + InferenceContentProvider
```

## Tests

```sh
./gradlew :core:test :app:testDebugUnitTest    # unit tests
./gradlew :app:connectedDebugAndroidTest        # Compose UI smoke (emulator)
```
