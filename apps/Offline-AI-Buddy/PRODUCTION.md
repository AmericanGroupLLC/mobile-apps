# PRODUCTION.md

How Offline AI Buddy v1 behaves in the wild.

## §1 — No backend

There is no server. There are no accounts. There is no analytics
pipeline by default. v1 is fully offline after the first-launch model
download.

Implications:
- We have no remote-config kill switch. Bugfixes ship as a normal app
  update on the App Store / Play Store.
- We have no telemetry on crashes or feature use unless the user opts
  in (v1.1 will land that toggle behind `canImport`-gated stubs).
- The model download URL is the *only* network endpoint the app touches.
  Document it in `MODELS.md` so it can be re-pointed if the CDN
  rotates.

## §2 — Storage

Files in the app's documents directory:

| Path | iOS | Android | Size |
|---|---|---|---|
| `profiles.json` | `Documents/offlineaibuddy/profiles.json` | `filesDir/offlineaibuddy/profiles.json` | <1 KB |
| `chats/<profileId>.json` | `Documents/offlineaibuddy/chats/...` | same | grows with chat history (capped at 200 messages per profile) |
| `quota.json` | `Documents/offlineaibuddy/quota.json` | same | <1 KB |
| `models/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf` | `Documents/offlineaibuddy/models/...` | same | ~1.0 GB |

We do not encrypt the JSON files; an attacker with file-system access
has access to your phone anyway. PIN hashes use PBKDF2 (100k rounds,
random salt). Chat content is plain text — opt-in encryption is on the
v1.2 roadmap.

## §3 — Permissions

| Permission | iOS | Android | Why |
|---|---|---|---|
| Microphone | `NSMicrophoneUsageDescription` | `RECORD_AUDIO` | Push-to-talk STT. Requested on first voice use, not at launch. |
| Speech recognition | `NSSpeechRecognitionUsageDescription` | (built into `SpeechRecognizer`) | STT. iOS only — Android uses platform STT without an explicit prompt. |
| Internet | (always-on for iOS apps) | `INTERNET` | Model download only. Once the GGUF is on disk, no further network use. |
| Network state | n/a | `ACCESS_NETWORK_STATE` | Wi-Fi-only download gate. |
| Foreground service | n/a | `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_DATA_SYNC` | Model download progress notification. |
| Notifications | not requested | `POST_NOTIFICATIONS` | Download progress notification only. |
| Bind input method | n/a | `BIND_INPUT_METHOD` | Declared by the IME service, not requested at runtime. |
| In-app billing | StoreKit (built-in) | `BILLING` | RevenueCat. |
| Camera | — | — | **Not requested.** |
| Bluetooth | — | — | **Not requested.** |
| Location | — | — | **Not requested.** |

## §4 — Crash + perf

No SDK in v1. The app size is dominated by the GGUF (~1 GB) downloaded
on first launch — the binary itself stays under 50 MB. Console.app /
logcat are the only crash signals until v1.1 attaches Sentry behind an
opt-in.

## §5 — Battery & data

- **Battery**: the LLM is a heavy workload. ~10–15% per hour of active
  chat on iPhone 14 / Pixel 7. Background = idle, no drain.
- **Data**: ~1 GB on first launch (Wi-Fi only by default). Zero cellular
  use after that.

## §6 — Monetisation (all 4 tiers wired in v1)

| Tier | Limit | Price | Implementation |
|---|---|---|---|
| Free | 10 chats/day, ad-supported | $0 | `QuotaTracker` enforces; AdMob banner not shown but interstitial available for ad-unlock. |
| Ad-unlock | +5 chats per cached AdMob interstitial watched | $0 | `AdMobAdGate.watchAd()` → `QuotaTracker.adWatched()`. |
| Subscription | unlimited + premium voices + no ads | $4.99/mo | RevenueCat product `oab_pro_monthly`. Entitlement `pro_unlocked`. |
| One-time | unlimited + premium voices + no ads, never expires | $19.99 lifetime | RevenueCat product `oab_pro_lifetime`. Same entitlement `pro_unlocked`. |

`EntitlementService` flattens all four into a single `proUnlocked: Bool`
that the rest of the app reads.

## §7 — App size budget

| Surface | Target | Notes |
|---|---|---|
| iOS .ipa (binary) | < 50 MB | Plus ~1 GB GGUF downloaded on first launch. |
| Android .aab (download) | < 50 MB | Plus ~1 GB GGUF. |
| GGUF model | ~1.0 GB | Qwen2.5-1.5B-Instruct-Q4_K_M. |

## §8 — Cross-platform parity

| Surface | iOS | Android | Parity gap |
|---|---|---|---|
| Chat / Roast / Daily / Party / GameCoach / Translate | ✅ | ✅ | None. |
| Voice STT/TTS | ✅ on-device | ✅ on-device (where supported) | Android pre-13 may fall back to network STT — surfaced to user. |
| Smart-reply keyboard | Keyboard Extension | InputMethodService | iOS keyboard cannot launch the host app; renders a tap target as fallback. Documented in `KEYBOARD.md` §5. |
| RevenueCat / AdMob | ✅ | ✅ | None. |

## §9 — Watch tier

Phone-only in v1. A 1.5B-parameter LLM cannot fit in a watch's RAM
(<1 GB on most watches), and even a thin-client watch UI would need
network back to the phone, contradicting the offline pitch.

## §10 — Push / background

No APNs, no FCM in v1. `POST_NOTIFICATIONS` on Android is requested
ONLY for the model-download progress notification (foreground service
sticky notification).
