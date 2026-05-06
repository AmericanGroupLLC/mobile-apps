# OFFLINE-AI-FEATURES.md — v1.0 feature inventory

## Core LLM

- [x] llama.cpp runtime via Swift bindings (iOS) + JNI (Android).
- [x] Default bundled model: **Qwen2.5-1.5B-Instruct-Q4_K_M.gguf** (~1.0 GB).
- [x] First-launch download with `URLSession` background (iOS) /
      `WorkManager` foreground service (Android), Wi-Fi-only,
      resume-on-reconnect, SHA-256 verified.
- [x] `BuddyAICore.LlamaRunner` (Swift) / `LlamaService` (Kotlin)
      single API: `generate(messages, options) -> AsyncStream<Token>`.
- [x] Pluggable LLM backend (Phase 2 of roadmap can swap in MLC LLM or
      Apple Foundation Models without touching features).

## Multilingual (5 languages, 1 model)

- [x] **English (en)**, **Hindi (hi)**, **Mandarin (zh)**, **French (fr)**,
      **Spanish (es)** chat.
- [x] Per-chat language picker.
- [x] System-prompt prefix flips with the picker.
- [x] `LanguageDetector` auto-flips when the user types in a different
      script.

## Live translator

- [x] Source → Target picker (any pair of 5).
- [x] Strict translation system prompt — no commentary, no quotes.
- [x] Golden 50-sentence-per-pair regression suite (gated behind
      `RUN_TRANSLATION_GOLDEN=1`).

## Smart-reply keyboard ("auto-responding keypad")

- [x] iOS Keyboard Extension target (`OfflineAIBuddyKeyboard`).
- [x] Android `InputMethodService` (`BuddyInputMethodService`).
- [x] App Group / ContentProvider IPC with the main app for inference.
- [x] 3-suggestion candidate strip.
- [x] Fallback "Open Offline AI Buddy" tap target when the host app
      isn't running (iOS extensions can't launch the host app
      programmatically).

## Voice

- [x] Push-to-talk STT (locale-aware, on-device where supported).
- [x] Per-message TTS playback (locale-aware).
- [x] Premium voices unlocked by Pro tier (uses platform "enhanced"
      voices the user has installed via system Settings).

## Prompt-templated experiences (all served by the same LLM)

- [x] **Chat** — open-ended assistant.
- [x] **Roast Mode** — funny, light, never mean. Disabled in Kid-safe.
- [x] **Daily Challenge** — one prompt per calendar day, deterministic
      cache.
- [x] **Party Question Generator** — 5 ice-breakers per tap, audience
      preset (work/friends/first-date/family).
- [x] **Game Coach** — pick game, get coaching on next move.
- [x] **Translate** — see "Live translator" above.

## Profiles + kid-safe

- [x] Two profiles per install: Adult (default) + Kid-Safe.
- [x] PIN-locked switch back to Adult.
- [x] Kid-safe filters every assistant token through `ContentPolicy`.
- [x] Roast disabled in Kid-safe.

## Onboarding

- [x] Consent screen explicitly lists the 3 limitations (download size,
      reasoning ceiling, generation speed on older phones).
- [x] Profile setup → name + Adult/Kid + PIN if Kid.
- [x] Model download with progress bar + Wi-Fi gate.
- [x] Microphone + Speech permissions deferred to first-use, NOT at
      launch.

## Settings

- [x] Profile manager (switch / add / delete with PIN).
- [x] Default language.
- [x] Voice settings (TTS speed + premium voice toggle).
- [x] Connectivity preference (Wi-Fi-only model downloads — default ON).
- [x] Theme (system / light / dark).
- [x] Erase all chats / Delete model / Reset device ID.
- [x] Premium / Subscribe / Restore Purchases (RevenueCat).
- [x] Telemetry: nothing by default; opt-in slot for v1.1.

## Monetisation (all 4 tiers wired)

- [x] **Free**: 10 chats/day, ad-supported.
- [x] **Ad-unlock**: cached AdMob interstitial → +5 chats per ad.
- [x] **Subscription**: $4.99/mo via RevenueCat
      (`oab_pro_monthly`).
- [x] **One-time lifetime**: $19.99 via RevenueCat
      (`oab_pro_lifetime`).
- [x] `EntitlementService` flattens to one `proUnlocked: Bool`.

## Telemetry

- [x] Stub interfaces (`AnalyticsService`, `CrashReportingService`) —
      no transports attached.
- [ ] Real Sentry / PostHog wiring (v1.1).

## NOT in v1 (explicitly)

- [ ] iPad-native layout, Apple Watch, Wear OS.
- [ ] Cloud fallback / hybrid mode.
- [ ] Image generation / vision.
- [ ] Custom fine-tuning / LoRA loading.
- [ ] Model marketplace.
- [ ] Background continuous listening / wake-word.
- [ ] Telemetry SDKs (Sentry / PostHog).
- [ ] End-to-end-encrypted chat sync between devices.
- [ ] APNs / FCM push.
