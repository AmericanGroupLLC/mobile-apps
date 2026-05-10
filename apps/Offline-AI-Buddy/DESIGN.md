# Offline AI Buddy — Design

## Pitch

Offline AI Buddy is a **phone-only on-device LLM hub**. After a one-time
~1 GB model download on first launch, every feature runs locally — chat,
voice, roasts, daily challenges, party questions, game coaching,
multilingual translation, and a system keyboard that suggests AI smart
replies inside any chat app. v1 ships **one** quantised LLM
(Qwen2.5-1.5B-Instruct-Q4_K_M) covering English + Hindi + Mandarin +
French + Spanish.

## Brand

- **App name**: Offline AI Buddy
- **Tagline**: *Your phone-only AI. Works without internet.*
- **Palette**: midnight purple (`#1A0B2E`) + electric teal accent (`#5EEAD4`).
- **Bundle prefix**: `com.americangroupllc.offlineaibuddy`.
- **Apple Group**: `group.com.americangroupllc.offlineaibuddy`.

## Repo map

```
shared/BuddyAICore/        Swift Package: models, keystone domain helpers,
                           LlamaRunner actor, ModelDownloader/Store, voice
                           wrappers, monetization protocols, tests.
ios/                       SwiftUI iPhone app + OfflineAIBuddyKeyboard
                           Keyboard Extension. XcodeGen-generated.
android/                   Multi-module Gradle build:
                             :core    pure-Kotlin/JVM mirror of BuddyAICore.
                             :app     Compose phone app + JNI llama.cpp bridge
                                      + BuddyInputMethodService.
vendor/llama.cpp           Submodule pinned to a specific commit.
.github/workflows/         6 CI workflows. No backend.
scripts/                   Local helpers (test-all, run-*-emulator, bump-version,
                           release-dry-run, fetch-models, bench-llama).
distribution/whatsnew/     Per-locale Play Store whatsnew text (en/hi/zh/fr/es).
index.html, styles.css,    Marketing one-pager.
script.js, robots.txt,
sitemap.xml
```

## Layered architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│ UI                  iOS SwiftUI                Android Compose            │
│                     ──────────                 ──────────────             │
│                     OnboardingFlow             OnboardingScreen           │
│                     ProfileSwitcher            ProfileSwitcherScreen      │
│                     ChatScreen                 ChatScreen                 │
│                     RoastScreen                RoastScreen                │
│                     DailyChallenge / Party /   ditto                      │
│                     GameCoach / Translate                                 │
│                     SettingsScreen             SettingsScreen             │
│                     OfflineAIBuddyKeyboard ↕   BuddyInputMethodService ↕  │
│                     (Keyboard Extension)       (InputMethodService)       │
├──────────────────────────────────────────────────────────────────────────┤
│ App services        LlamaService               LlamaService               │
│                     VoiceService               VoiceSynth/Recog           │
│                     EntitlementBootstrap       EntitlementService         │
│                     KeyboardBridge ↔           KeyboardBridge ↔           │
│                       (App Group + Darwin)       (ContentProvider)        │
│                     QuotaService               QuotaService               │
├──────────────────────────────────────────────────────────────────────────┤
│ Shared domain       BuddyAICore (Swift)        :core (Kotlin/JVM)         │
│ (mirrored 1:1)      ─────────────────          ──────────────────         │
│                     Models                     Models                     │
│                     PromptTemplates            PromptTemplates            │
│                     ContentPolicy              ContentPolicy              │
│                     QuotaTracker               QuotaTracker               │
│                     LanguageDetector           LanguageDetector           │
│                     TranslateOrchestrator      TranslateOrchestrator      │
│                     ProfilesStore              ProfilesStore              │
│                     ChatHistoryStore           ChatHistoryStore           │
│                     QuotaStore                 QuotaStore                 │
├──────────────────────────────────────────────────────────────────────────┤
│ LLM / Voice runtime LlamaRunner (actor) ↔      LlamaJni → JNI → .so       │
│                     llama.cpp (SPM C target)   liboffline_ai_buddy.so     │
│                     AVSpeechSynthesizer        TextToSpeech                │
│                     SFSpeechRecognizer         SpeechRecognizer            │
└──────────────────────────────────────────────────────────────────────────┘
```

The shared-domain layer is pure: no platform APIs, fully unit-tested.
Every keystone helper has an XCTest **and** a JUnit twin so behaviour
cannot drift between the two implementations. (Same pattern as Card,
Drift, BuddyPlay.)

## Per-platform stack

| | iPhone | Android |
|---|---|---|
| Language | Swift 5.9 | Kotlin 1.9 |
| UI framework | SwiftUI | Jetpack Compose |
| Min OS | iOS 17 | API 26 (Android 8) |
| Project generator | XcodeGen (`ios/project.yml`) | Gradle (`build.gradle.kts`) |
| DI | manual env objects | Hilt |
| Storage | `UserDefaults` + JSON-on-disk | DataStore + JSON-on-disk |
| LLM bridge | Swift target wrapping `llama.cpp` C code | NDK CMake build → `liboffline_ai_buddy.so` + JNI |
| TTS | `AVSpeechSynthesizer` | `TextToSpeech` |
| STT | `SFSpeechRecognizer` (on-device) | `SpeechRecognizer` (`EXTRA_PREFER_OFFLINE`) |
| Keyboard | Keyboard Extension + App Group IPC | `InputMethodService` + ContentProvider IPC |
| Subscription | RevenueCat SPM | RevenueCat Maven |
| Ads | Google-Mobile-Ads-SDK SPM | Google Mobile Ads SDK Maven |
| Build automation | `xcodebuild` via scripts/CI | `./gradlew` via scripts/CI |

## Telemetry

**None on by default.** No Sentry, no PostHog, no analytics SDKs are
attached in v1. `canImport`-gated stubs (`AnalyticsService`,
`CrashReportingService`) are preserved so v1.1 can opt in trivially
behind a Settings opt-in toggle.

## Backend

**None.** All state is local. Three tiny JSON files in the app's documents
directory (`profiles.json`, `chats/<profileId>.json`, `quota.json`) plus
the ~1 GB GGUF model file.

## Domain model

| Type | Notes |
|---|---|
| `Profile` | id, name, kind (`adult`/`kidSafe`), pinHash?, createdAt. |
| `Language` | enum: `en`, `hi`, `zh`, `fr`, `es`. Extensible. |
| `ChatSession` | id, profileId, language, kind, messages, startedAt. |
| `ChatMessage` | id, role, text, ts. |
| `ModelManifest` | name, version, url, sizeBytes, sha256, contextSize, minDeviceRAM. |
| `EntitlementState` | proUnlocked, source (`free`/`subscription`/`lifetime`), expiresAt?. |
| `QuotaState` | profileId, day, chatsUsed, adUnlocks. |

## Why phone-only? No iPad / no Watch / no Wear?

iPad layout would mean parallel SwiftUI variants for every screen. Watches
can't host a 1 GB model and a thin-client watch app would need network
back to the phone, contradicting the offline pitch. Phone-only stays in
v1; revisit watch in v2 only on demand.

## Why no cloud fallback?

The whole product promise is **offline**. A "fallback to GPT-4 when LLM
isn't loaded" feature would erode trust: users would never know if they
were paying for cloud calls or not. Strict offline.

## Why ship only one model?

A 1.5B-parameter Q4 GGUF is the sweet spot for 2025 mid-range phones:
~3.5 GB peak RAM, 8–15 tokens/sec on iPhone 14 / Pixel 7. Adding a
"model marketplace" multiplies download size + support burden + App
Store review risk. v2 may add an opt-in catalogue.
