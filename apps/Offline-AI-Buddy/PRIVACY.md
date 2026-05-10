# PRIVACY.md

## TL;DR

**Offline AI Buddy does not send any data to us.** No accounts, no
servers, no analytics, no crash reports, no chat content ever leaves
your phone after the first-launch model download.

## What we collect

Nothing.

## What we download

Once, on first launch:

- One **language model file** (~1 GB GGUF format) over Wi-Fi from a
  fixed CDN URL, listed in `MODELS.md`. SHA-256 verified after download.

After that, the app never reaches the internet for chat / voice /
keyboard features.

## What we store on your phone

Files in the app's private documents directory:
- **`profiles.json`** — your profile name(s), profile kind
  (`adult`/`kidSafe`), and PBKDF2-hashed PIN if Kid-safe.
- **`chats/<profileId>.json`** — your chat history per profile (capped
  at 200 messages per profile).
- **`quota.json`** — daily chat-count tally for the free tier.
- **`models/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf`** — the ~1 GB language
  model.

Files live in the app's private documents directory. They are never
backed up to a server. You can wipe them at any time:

- **Settings → Erase all chats** clears `chats/`.
- **Settings → Delete model** removes the GGUF (re-downloaded on next
  launch).
- **Settings → Reset device ID** regenerates the per-install random
  device ID used for RevenueCat anonymous attribution.
- **Uninstalling Offline AI Buddy** removes everything.

## What we share with other devices

**Nothing.** The app does not connect to any other device.

The smart-reply keyboard moves data **within your phone** between the
keyboard extension process and the main app process via:
- iOS: an App Group shared file (`group.com.americangroupllc.offlineaibuddy`).
- Android: an exported ContentProvider with `android:exported="true"`
  but read-only and signature-permission-protected, so only the main
  app can query it.

The chat context the keyboard sees never leaves your phone.

## Permissions explained

| Permission | What we do with it |
|---|---|
| Microphone | Push-to-talk speech recognition. Only when you hold the mic button. |
| Speech recognition (iOS) | On-device speech-to-text where supported. Falls back to network STT only if you explicitly opt in (default OFF). |
| Internet | Downloading the language model on first launch (and re-downloading if you tap Delete Model). |
| Foreground service (Android) | Keeping the model download alive when you switch apps; sticky progress notification. |
| Notifications (Android) | The model-download progress notification only. We never send other notifications. |
| Bind input method (Android) | Required by Android for any app that registers a system keyboard. We never read your keystrokes outside the keyboard's own input field. |
| In-app billing (Android) / StoreKit (iOS) | Subscription + lifetime IAP for the Pro tier. RevenueCat handles the receipt validation. |

We never request: camera, contacts, photos, health, motion, HealthKit,
location, Bluetooth, calendar, calendar.

## Children

Offline AI Buddy has a built-in **Kid-Safe profile** with PIN-locked
escape:
- Strict refusal system prompt (no violence, romance, profanity, drugs,
  gambling, weapons).
- Output filter: every assistant token passes through `ContentPolicy`
  before being shown.
- Roast Mode disabled.
- Daily Challenges that touch flagged categories disabled.
- Premium voice forced to a "calm" preset.

The whole app is rated 12+ on iOS / Teen on Android due to the
open-text nature of the LLM. The Kid-Safe profile is intended as a
parental control, not a substitute for adult supervision.

## RevenueCat / AdMob (the third-party SDKs we DO ship)

- **RevenueCat** processes your in-app purchase receipt with Apple /
  Google to determine whether you're entitled to the Pro tier. It
  receives your purchase token and a random per-install device ID. It
  never receives your chat content. See:
  https://www.revenuecat.com/privacy
- **AdMob** serves the optional "watch ad for +5 chats" interstitial. It
  receives Google's standard ad-targeting signals (locale, device
  model, OS version). It never receives your chat content. See:
  https://policies.google.com/privacy

You can avoid both SDKs entirely by purchasing the **lifetime Pro IAP**:
RevenueCat's receipt check happens once and the AdMob SDK is never
loaded for Pro users.

## Changes to this policy

If a future version (v1.1+) adds optional analytics or crash reporting,
this document will be updated, and the new collection will be **opt-in**
behind a Settings toggle defaulting to OFF, with a fresh in-app
disclosure on the first launch after the update.

## Contact

For questions: open an issue at
https://github.com/AmericanGroupLLC/Offline-AI-Buddy
