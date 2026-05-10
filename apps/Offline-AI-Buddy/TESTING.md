# TESTING.md

## Shape of the test suite

| Layer | Where | Framework | Runs in CI |
|---|---|---|---|
| Apple shared logic | `shared/BuddyAICore/Tests/BuddyAICoreTests/` | XCTest | `ci.yml`, `ios.yml`, `pre-release-tests.yml` |
| iOS UI smoke | `ios/OfflineAIBuddyUITests/` | XCUITest | `ios.yml`, `pre-release-tests.yml` |
| iOS app unit | `ios/OfflineAIBuddyTests/` | XCTest | `ios.yml`, `pre-release-tests.yml` |
| Android shared logic | `android/core/src/test/...` | JUnit 4 + Truth | `ci.yml`, `pre-release-tests.yml` |
| Android app unit | `android/app/src/test/...` | JUnit 4 + Truth | `ci.yml`, `pre-release-tests.yml` |
| Android UI smoke | `android/app/src/androidTest/...` | Compose UI testing | `android.yml`, `pre-release-tests.yml` |

## The keystone tests (the project's safety net)

Every keystone helper has an XCTest **and** a JUnit twin. They test the
same contract on both runtimes so behaviour cannot drift.

| Helper | XCTest | JUnit | What it asserts |
|---|---|---|---|
| `PromptTemplates` | `PromptTemplatesTests` | `PromptTemplatesKtTest` | Stable golden output per `(kind, language)`. ~25 cases. Round-trip stable across runs. |
| `ContentPolicy` | `ContentPolicyTests` | `ContentPolicyKtTest` | 30 cases of safe-vs-blocked text per language; idempotent across rolling buffer; round-trip. |
| `QuotaTracker` | `QuotaTrackerTests` | `QuotaTrackerKtTest` | 10 chats exhausts free; ad-watch grants +5; midnight rollover resets; pro entitlement bypasses. |
| `LanguageDetector` | `LanguageDetectorTests` | `LanguageDetectorKtTest` | ~50 sentences per language correctly detected; mixed-language returns dominant. |
| `TranslateOrchestrator` | `TranslateOrchestratorTests` | `TranslateOrchestratorKtTest` | Golden 50-sentence-per-pair (5×4=20 pairs) regression suite. Gated behind `RUN_TRANSLATION_GOLDEN=1` env var (slow). |
| `ProfilesStore` | `ProfilesStoreTests` | `ProfilesStoreKtTest` | PIN hash round-trip; PIN-locked profile switch refused without PIN; corrupt JSON falls back to empty. |
| `ModelStore` | `ModelStoreTests` | `ModelStoreKtTest` | SHA-256 verification; corruption triggers re-download; "delete model" wipes correctly. |
| `LlamaRunner` smoke | `LlamaRunnerSmokeTests` | `LlamaJniSmokeKtTest` | 5-token generation. Gated behind `RUN_LLAMA_SMOKE=1` (needs the ~1 GB model on disk). |

These eight files MUST compile + test green on both Swift and Kotlin
before any UI work for the corresponding feature ships.

## Running locally

```sh
# Everything (auto-skips suites the host can't run)
./scripts/test-all.sh

# Just BuddyAICore
cd shared/BuddyAICore && swift test
# or with coverage on iPhone Sim
xcodebuild test -scheme BuddyAICore-Package \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -enableCodeCoverage YES CODE_SIGNING_ALLOWED=NO

# Just Android :core
cd android && ./gradlew :core:test

# Just Android :app unit
cd android && ./gradlew :app:testDebugUnitTest

# Compose UI smoke (requires emulator + adb)
cd android && ./gradlew :app:connectedDebugAndroidTest

# Just XCUITest smoke
cd ios && xcodegen generate
xcodebuild test -project OfflineAIBuddy.xcodeproj -scheme OfflineAIBuddy \
  -sdk iphonesimulator -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

## Manual checklist (pre-release)

| Scenario | Steps | Pass criterion |
|---|---|---|
| First-launch download | Fresh install → Consent → Profile → Model download progresses to 100% on Wi-Fi → SHA-256 matches → chat works in airplane mode. | Download completes, hash verified, chat responds offline. |
| Multilingual chat | Switch language picker to Hindi → ask "नमस्ते, कैसे हो?" → response in Hindi. Repeat zh / fr / es. | Reply is in target language. |
| Live translation | Translate screen → English → Hindi → "Hello, how are you?" → Hindi output. | Output is the translation only, no commentary. |
| Voice push-to-talk | Hold mic → speak → STT renders text → AI streams → tap play → TTS speaks reply. | All four steps complete in the same locale. |
| iOS keyboard smart-reply | Enable Buddy Keyboard in iOS Settings → open Messages → type "running late" → 3 suggestions in candidate strip → tap one → inserted. | 3 chips visible, tap inserts, no crash. |
| Android keyboard smart-reply | Enable Buddy Keyboard → open WhatsApp → type "running late" → 3 suggestions in IME strip. | Same. |
| Kid-safe profile | Switch to Kid → ask flagged Q (e.g. about violence) → response refused or filtered. Switch back → PIN prompt. | Refusal text + PIN gate. |
| Quota + ad unlock | Send 10 chats → 11th blocked → "watch ad for +5" shown → cached ad plays → +5 chats granted. | Counter visible, refill works. |
| Subscription paywall | Tap Premium → paywall → sandbox subscribe → entitlement updates → ads disappear → quota becomes unlimited. | Entitlement persists across restart. |
| One-time purchase | Tap "Offline AI Pro Lifetime" → sandbox purchase → entitlement persists across restarts and reinstall (with same Apple/Google ID). | Entitlement restored after reinstall. |

## Coverage targets

- `BuddyAICore` (Swift): 80%+ on the keystone helpers.
- `:core` (Kotlin): 80%+ on the keystone helpers.
- App layers: best-effort; mostly thin glue.

Coverage is uploaded by CI to Codecov; the report is informational, not a
blocker.
