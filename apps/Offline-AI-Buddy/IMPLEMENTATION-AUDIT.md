# IMPLEMENTATION-AUDIT.md

**Audit date:** 2026-05-08
**Repo:** Offline-AI-Buddy (v1.0 inventory)
**Scope:** Verify each feature promised in `OFFLINE-AI-FEATURES.md` (supplemented by `README.md`, `DESIGN.md`, `MODELS.md`, `SAFETY.md`, `KEYBOARD.md`) against actual source under `android/`, `ios/`, `shared/`, and `desktop/`.

---

## Severity legend

| Severity | Meaning |
| -------- | ------- |
| **P0** | Ship-blocker — false advertising, crash on launch, store-rejection certainty, or core promise unimplemented. |
| **P1** | High — visible to users at runtime, store-policy risk, or security/privacy concern. Must be fixed before public release. |
| **P2** | Medium — partial implementation, dev-only stub still wired in production path, or visible gap behind a flag. Should be fixed before GA. |
| **P3** | Low — placeholder asset, dev-mode comment, or "v1.1" deferral that is documented and doesn't affect v1 ship. |

---

## Promised features → Implementation citations

Citations use `path:line` form. **GAP** marks a promise with no production-quality implementation.

### Core LLM

| # | Feature (from `OFFLINE-AI-FEATURES.md`) | Status | Citation |
|---|---|---|---|
| 1 | llama.cpp runtime via Swift bindings (iOS) | Partial — Swift wrapper exists but binds `StubLlamaBackend`, not real `llama.cpp` | `shared/BuddyAICore/Sources/BuddyAICore/LLM/LlamaRunner.swift:97` (`StubLlamaBackend`); `ios/OfflineAIBuddy/App/OfflineAIBuddyApp.swift:37` (uses stub in production composition root) |
| 2 | llama.cpp runtime via JNI (Android) | Partial — JNI surface present, real impl falls back to stub when `vendor/llama.cpp` submodule is missing | `android/app/src/main/java/com/americangroupllc/offlineaibuddy/llm/LlamaJni.kt:5`; `android/app/src/main/cpp/CMakeLists.txt:17`; `android/app/src/main/cpp/llama_jni_stub.cpp:1` |
| 3 | Default bundled model **Qwen2.5-1.5B-Instruct-Q4_K_M** | Manifested | `shared/BuddyAICore/Sources/BuddyAICore/Models/ModelManifest.swift:36` |
| 4 | First-launch download (URLSession iOS / WorkManager Android), Wi-Fi-only, resume, SHA-256 verified | Implemented; SHA-256 left blank in default manifest (dev fallthrough) | `shared/BuddyAICore/Sources/BuddyAICore/LLM/ModelDownloader.swift:69`; `android/app/src/main/java/com/americangroupllc/offlineaibuddy/llm/ModelDownloadWorker.kt`; `shared/BuddyAICore/Sources/BuddyAICore/Models/ModelManifest.swift:44` (empty sha256) |
| 5 | Single API `generate(messages, options) -> AsyncStream<Token>` | Implemented | `shared/BuddyAICore/Sources/BuddyAICore/LLM/LlamaRunner.swift`; `android/app/src/main/java/com/americangroupllc/offlineaibuddy/llm/LlamaService.kt` |
| 6 | Pluggable LLM backend | Implemented (protocol + Stub backend) | `shared/BuddyAICore/Sources/BuddyAICore/LLM/LlamaRunner.swift:97` |

### Multilingual

| # | Feature | Status | Citation |
|---|---|---|---|
| 7 | en/hi/zh/fr/es chat | Implemented (model + manifest) | `shared/BuddyAICore/Sources/BuddyAICore/Models/Language.swift` |
| 8 | Per-chat language picker | Implemented | `ios/OfflineAIBuddy/Features/Chat/ChatScreen.swift`; `android/app/src/main/java/com/americangroupllc/offlineaibuddy/chat/ChatScreen.kt` |
| 9 | System-prompt prefix flips with picker | Implemented | `shared/BuddyAICore/Sources/BuddyAICore/Domain/PromptTemplates.swift` |
| 10 | `LanguageDetector` auto-flips on script change | Implemented | `shared/BuddyAICore/Sources/BuddyAICore/Domain/LanguageDetector.swift` |

### Live translator

| # | Feature | Status | Citation |
|---|---|---|---|
| 11 | Source→Target picker (any pair of 5) | Implemented | `ios/OfflineAIBuddy/Features/Translate/TranslateScreen.swift`; `android/app/src/main/java/com/americangroupllc/offlineaibuddy/translate/TranslateScreen.kt` |
| 12 | Strict translation system prompt | Implemented | `shared/BuddyAICore/Sources/BuddyAICore/Domain/TranslateOrchestrator.swift` |
| 13 | Golden 50-sentence regression suite | Implemented (gated by `RUN_TRANSLATION_GOLDEN=1`) | `shared/BuddyAICore/Tests/BuddyAICoreTests/GoldenTranslationTests.swift` |

### Smart-reply keyboard

| # | Feature | Status | Citation |
|---|---|---|---|
| 14 | iOS Keyboard Extension target | Implemented | `ios/OfflineAIBuddyKeyboard/KeyboardViewController.swift`; `ios/OfflineAIBuddyKeyboard/Info.plist` |
| 15 | Android `InputMethodService` | Implemented | `android/app/src/main/java/com/americangroupllc/offlineaibuddy/keyboard/BuddyInputMethodService.kt`; `android/app/src/main/AndroidManifest.xml:72` |
| 16 | App Group / ContentProvider IPC | Implemented (signature-permission-protected) | `android/app/src/main/java/com/americangroupllc/offlineaibuddy/keyboard/InferenceContentProvider.kt`; `android/app/src/main/AndroidManifest.xml:88`; `ios/OfflineAIBuddyKeyboard/KeyboardBridge.swift` |
| 17 | 3-suggestion candidate strip | Implemented | `ios/OfflineAIBuddyKeyboard/KeyboardViewController.swift`; `android/app/src/main/java/com/americangroupllc/offlineaibuddy/keyboard/BuddyInputMethodService.kt` |
| 18 | Fallback "Open Offline AI Buddy" tap target | Implemented (custom URL scheme) | `android/app/src/main/AndroidManifest.xml:62` (scheme `offlineaibuddy`); `ios/OfflineAIBuddyKeyboard/KeyboardViewController.swift` |

### Voice

| # | Feature | Status | Citation |
|---|---|---|---|
| 19 | Push-to-talk STT (locale-aware) | Implemented | `shared/BuddyAICore/Sources/BuddyAICore/Voice/VoiceRecognizer.swift`; `android/app/src/main/java/com/americangroupllc/offlineaibuddy/voice/AndroidVoice.kt` |
| 20 | Per-message TTS playback | Implemented | `shared/BuddyAICore/Sources/BuddyAICore/Voice/VoiceSynthesizer.swift` |
| 21 | Premium voices unlocked by Pro | Implemented | `shared/BuddyAICore/Sources/BuddyAICore/Voice/VoiceSynthesizer.swift`; `shared/BuddyAICore/Sources/BuddyAICore/Monetization/EntitlementService.swift` |

### Prompt-templated experiences

| # | Feature | Status | Citation |
|---|---|---|---|
| 22 | Chat | Implemented | `ios/OfflineAIBuddy/Features/Chat/ChatScreen.swift`; `android/.../chat/ChatScreen.kt` |
| 23 | Roast Mode (disabled in Kid-safe) | Implemented | `ios/OfflineAIBuddy/Features/Roast/RoastScreen.swift`; `android/.../roast/RoastScreen.kt` |
| 24 | Daily Challenge | Implemented | `ios/OfflineAIBuddy/Features/DailyChallenge/DailyChallengeScreen.swift`; `android/.../dailychallenge/DailyChallengeScreen.kt` |
| 25 | Party Question Generator | Implemented | `ios/OfflineAIBuddy/Features/PartyQuestions/PartyQuestionsScreen.swift`; `android/.../partyquestions/PartyQuestionsScreen.kt` |
| 26 | Game Coach | Implemented | `ios/OfflineAIBuddy/Features/GameCoach/GameCoachScreen.swift`; `android/.../gamecoach/GameCoachScreen.kt` |
| 27 | Translate (see row 11) | Implemented | (above) |

### Profiles + Kid-safe

| # | Feature | Status | Citation |
|---|---|---|---|
| 28 | Adult + Kid-Safe profiles | Implemented | `shared/BuddyAICore/Sources/BuddyAICore/Models/Profile.swift`; `shared/BuddyAICore/Sources/BuddyAICore/Storage/ProfilesStore.swift` |
| 29 | PIN-locked switch back to Adult | Implemented | `ios/OfflineAIBuddy/Features/Profile/PinPromptView.swift`; `android/app/src/main/java/com/americangroupllc/offlineaibuddy/profile/PinPromptScreen.kt` |
| 30 | Kid-safe filters every assistant token via `ContentPolicy` | Implemented | `shared/BuddyAICore/Sources/BuddyAICore/Domain/ContentPolicy.swift` |
| 31 | Roast disabled in Kid-safe | Implemented | (cross-ref row 23) |

### Onboarding

| # | Feature | Status | Citation |
|---|---|---|---|
| 32 | Consent screen lists 3 limitations | iOS implemented; **Android GAP** — screen exists but unreachable | iOS: `ios/OfflineAIBuddy/Features/Onboarding/ConsentScreen.swift`. Android consent body is present at `android/app/src/main/java/com/americangroupllc/offlineaibuddy/onboarding/Onboarding.kt:12-25` but the entry point `OnboardingScreen()` at `Onboarding.kt:53-58` is a one-line `Text("Onboarding")` placeholder, and `RootNav.kt:63` hard-codes `startDestination = "home"` — see Bug #1 (P0) |
| 33 | Profile setup → name + Adult/Kid + PIN if Kid | iOS implemented; Android present but unwired (Bug #1) | iOS: `ios/OfflineAIBuddy/Features/Onboarding/ProfileSetupScreen.swift`. Android: `Onboarding.kt:28-34` |
| 34 | Model download with progress bar + Wi-Fi gate | iOS implemented; Android Compose screen unwired (Worker itself works) | iOS: `ios/OfflineAIBuddy/Features/Onboarding/ModelDownloadScreen.swift`. Android UI: `Onboarding.kt:37-43`; Worker: `android/app/src/main/java/com/americangroupllc/offlineaibuddy/llm/ModelDownloadWorker.kt` |
| 35 | Mic + Speech permissions deferred to first-use | Implemented | `android/app/src/main/AndroidManifest.xml:5-7` (comment + manifest entry, runtime requested at voice-button tap); iOS: `ios/OfflineAIBuddy/Features/Voice/VoiceButtons.swift` |

### Settings

| # | Feature | Status | Citation |
|---|---|---|---|
| 36 | Profile manager | Implemented | `ios/OfflineAIBuddy/Features/Profile/ProfileSwitcherView.swift`; `android/.../profile/ProfileSwitcherScreen.kt` |
| 37 | Default language | Implemented | `ios/OfflineAIBuddy/Features/Settings/SettingsScreen.swift`; `android/.../settings/SettingsScreen.kt` |
| 38 | Voice settings (TTS speed + premium voice toggle) | Implemented | (same files as 37) |
| 39 | Wi-Fi-only model downloads (default ON) | Implemented | `android/.../llm/ModelDownloadWorker.kt`; `shared/BuddyAICore/Sources/BuddyAICore/LLM/ModelDownloader.swift` |
| 40 | Theme (system/light/dark) | Implemented | (same Settings files as 37) |
| 41 | Erase all chats / Delete model / Reset device ID | Implemented | (same Settings files as 37) |
| 42 | Premium / Subscribe / Restore Purchases (RevenueCat) | Implemented | `ios/OfflineAIBuddy/Features/Settings/SubscriptionScreen.swift`; `android/.../settings/SubscriptionScreen.kt`; `shared/BuddyAICore/Sources/BuddyAICore/Monetization/EntitlementService.swift` |
| 43 | Telemetry: nothing by default; opt-in slot for v1.1 | Implemented (stub interfaces only) | `shared/BuddyAICore/Sources/BuddyAICore/Observability/AnalyticsService.swift`; `CrashReportingService.swift` |

### Monetisation

| # | Feature | Status | Citation |
|---|---|---|---|
| 44 | Free tier — 10 chats/day | Implemented | `shared/BuddyAICore/Sources/BuddyAICore/Domain/QuotaTracker.swift` |
| 45 | Ad-unlock — AdMob interstitial → +5 chats | Implemented | `shared/BuddyAICore/Sources/BuddyAICore/Monetization/AdGate.swift`; `android/app/src/main/java/com/americangroupllc/offlineaibuddy/monetization/Monetization.kt` |
| 46 | Subscription `oab_pro_monthly` ($4.99/mo) | Implemented (RevenueCat product id wired) | `shared/BuddyAICore/Sources/BuddyAICore/Monetization/EntitlementService.swift` |
| 47 | Lifetime `oab_pro_lifetime` ($19.99) | Implemented | (same file) |
| 48 | `EntitlementService` flattens to one `proUnlocked: Bool` | Implemented | (same file) |

### Telemetry / NOT-in-v1 — sanity checked, intentionally absent.

---

## Bug list

Source-tree scan for `TODO|FIXME|XXX|HACK|stub|placeholder` in `*.kt`/`*.swift`/`*.js`/`*.ts`. Asset-only matches (icons/storyboards) and pure test artefacts excluded from severity table.

| # | Severity | File:Line | Description |
|---|---|---|---|
| 1 | **P0** | `android/app/src/main/java/com/americangroupllc/offlineaibuddy/ui/RootNav.kt:63` + `android/app/src/main/java/com/americangroupllc/offlineaibuddy/onboarding/Onboarding.kt:53-58` | **Android Onboarding flow is unwired.** `RootNav` hard-codes `startDestination = "home"`; `OnboardingScreen()` is a single `Text("Onboarding")` placeholder with the comment *"Simple linear flow placeholder. RootNav uses HomeScreen as start destination; the full onboarding lives behind first-launch detection in v1.1 via DataStore."* The individual `ConsentScreen`, `ProfileSetupScreen`, `ModelDownloadScreen`, and `PermissionsScreen` Composables exist (lines 12, 28, 37, 46) but are never composed into a flow nor reached from any nav graph. The `OFFLINE-AI-FEATURES.md` Onboarding section (rows 32–35 above) and `DESIGN.md`/`README.md` advertise a consent → profile → download → permissions flow on first launch. **This is false advertising of consent flow** — Android users skip straight to `HomeScreen` with no consent gate, which is also a Play Store data-safety concern given the 1 GB Wi-Fi download promise. |
| 2 | **P1** | `android/app/src/main/AndroidManifest.xml:49-51` | **AdMob `APPLICATION_ID` is Google's test sample ID** (`ca-app-pub-3940256099942544~3347511713`). The inline comment acknowledges *"replace with the real AdMob app id (or wire via manifestPlaceholders driven by the `ADMOB_APP_ID_ANDROID` env var) before store submission."* As long as no real ads are served at runtime, Play Store will not reject; however, if the app ever shows an ad with this ID in production it will be rejected and risks AdMob policy strikes. The Free + Ad-unlock tiers (rows 45–47 above) are wired and *do* attempt to load interstitials, so this is one missing manifest substitution away from a runtime policy problem. |
| 3 | **P2** | `ios/OfflineAIBuddy/App/OfflineAIBuddyApp.swift:37` | iOS production composition root instantiates `LlamaRunner(backend: StubLlamaBackend(), …)`. The stub returns the literal string `"(stub) you said: <last>"` (`shared/BuddyAICore/Sources/BuddyAICore/LLM/LlamaRunner.swift:123`). No code path swaps in a real `llama.cpp`-backed `LlamaBackend` for release builds. Promised feature row 1 is therefore not satisfied at runtime on iOS. |
| 4 | **P2** | `android/app/src/main/java/com/americangroupllc/offlineaibuddy/llm/LlamaService.kt:67-68` | Android `LlamaService.generate` falls back to a stub stream (`"(stub) you said: " + userInput`) when JNI reports unloaded. The native side (`android/app/src/main/cpp/CMakeLists.txt:17-20`) compiles `llama_jni_stub.cpp` whenever `vendor/llama.cpp` is absent. CI/dev use is fine, but release builds need a guard that fails fast (or refuses to ship) if the stub variant is linked. Currently a release APK with no submodule will silently ship the stub. |
| 5 | **P2** | `android/app/src/main/cpp/llama_jni.cpp:40` | Even the "real" JNI translation unit returns `"(jni-stub) "` placeholder text — the C++ side is also incomplete and not yet bound to llama.cpp APIs. Reinforces Bug #4. |
| 6 | **P2** | `shared/BuddyAICore/Sources/BuddyAICore/Models/ModelManifest.swift:44` | `ModelManifest.defaultV1.sha256 = ""`. `ModelDownloader` "falls open when sha256 is empty (dev mode)" (`shared/BuddyAICore/Sources/BuddyAICore/LLM/ModelDownloader.swift:69`). Promised feature row 4 (SHA-256 verified) is bypassed for the default manifest until `MODELS.md` is updated post-first-build. Ship-blocker for any signed release. |
| 7 | **P3** | `android/app/src/main/res/drawable/ic_launcher_foreground.xml:3-4` | Launcher icon foreground is documented as a placeholder ("*Still a placeholder; replace*"). Cosmetic; not a store reject by itself but should be replaced before submission. |
| 8 | **P3** | `android/app/src/androidTest/java/com/americangroupllc/offlineaibuddy/OfflineAIBuddySmokeTest.kt:10` | "*Minimal smoke test placeholder.*" Documented intentional v1 scope. |
| 9 | **P3** | `ios/README.md:40-42` + `android/README.md:19` | READMEs describe the stub backend / stub native variant as the dev default. Documentation only; cross-links to Bugs #3–#5. |

Other matches found by the scan but not classified as bugs (ordinary code semantics):

- `android/.../chat/ChatScreen.kt:51` — `placeholder = { Text("Message…") }` is a TextField hint, not a stub.
- `shared/.../Domain/PromptTemplates.swift:17` and `android/core/.../PromptTemplatesKtTest.kt:41` — "placeholder" refers to `{{key}}` template substitution, intentional API surface.
- `ios/.../Resources/LaunchScreen.storyboard:22` — Interface Builder placeholder element, not a code stub.

---

## Summary counts

- **Promised features audited:** 48
- **Implementation gaps (unimplemented or unwired on at least one platform):** 4
  - Onboarding row 32 (Android, P0)
  - Onboarding row 33 (Android, P0 — same root cause)
  - Onboarding row 34 (Android UI, P0 — same root cause)
  - Core LLM rows 1+2 backed by stub backends in production composition roots (P2/P2)
- **Bugs catalogued:** 9
- **Severity distribution:**
  - **P0:** 1 (Bug #1 — Android onboarding unwired; covers feature rows 32–34)
  - **P1:** 1 (Bug #2 — AdMob test app ID in manifest)
  - **P2:** 4 (Bugs #3, #4, #5, #6 — stub LLM backends on iOS + Android; empty default SHA-256)
  - **P3:** 3 (Bugs #7, #8, #9 — placeholder icon, smoke-test placeholder, dev-mode README notes)

**Net assessment:** Feature-complete on the surface (45 of 48 rows have working code), but two ship-blocking issues remain: (1) Android first-launch onboarding/consent flow is not reachable, and (2) both platforms still bind a stub LLM backend in their production composition roots. Either alone prevents a v1.0 store submission.
