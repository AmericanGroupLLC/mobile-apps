# Card — PRIVACY

Card collects nothing by default. This file lists every datum the app touches,
where it lives, and the language to paste into App Store Privacy Nutrition
Labels and the Play Console Data Safety form.

---

## 1. The one-paragraph version

Card stores every Card you write on the device you wrote it on. It does not
have a server, an account system, or a sync mechanism. The only data that ever
leaves your device is anonymized crash and product-analytics data — and **only**
if you explicitly enable both Settings → "Send crash reports" and "Send anonymous
usage data". Both are off by default.

---

## 2. What each surface touches

| Surface                          | Data                                                                  | Where it goes                                  |
|----------------------------------|-----------------------------------------------------------------------|------------------------------------------------|
| iPhone composer                  | Card text                                                             | Local JSON, App Group container                |
| iOS Share Extension              | Selected text from the source app                                     | Same App Group container                       |
| iOS reminder                     | Card id + reminder Date                                               | `UNUserNotificationCenter` (system-only)       |
| Apple Watch composer             | Voice recording (transcribed on device) + Card text                  | Local JSON; **audio is never stored**         |
| Apple Watch complication         | Tap-target only                                                       | Launches composer; no data of its own          |
| Android composer                 | Card text                                                             | Room (SQLite) in the app's private storage     |
| Android Quick Settings tile      | Tap-target only                                                       | Launches composer activity; no data of its own |
| Android reminder                 | Card id + alarm time                                                  | AlarmManager (system-only)                     |
| Wear OS composer / tile          | Voice recording (transcribed on device) + Card text                  | Same                                           |
| Settings                         | Boolean toggles + theme choice                                        | UserDefaults (Apple) / DataStore (Android)     |
| Sentry / PostHog (when opted in) | Anonymized event names + crash stack traces — **never** Card text     | Sentry / PostHog cloud, only after explicit opt-in |

**Permissions never requested**: Camera, Location (precise or coarse),
Contacts, Calendar, Photos, Health, Bluetooth, NFC.

---

## 3. App Store Privacy Nutrition Label (paste into App Store Connect)

| Data Type                | Linked to user | Tracking | Purpose                         |
|--------------------------|----------------|----------|---------------------------------|
| Crash data               | No             | No       | App Functionality (opt-in only) |
| Performance data         | No             | No       | App Functionality (opt-in only) |
| Diagnostic data          | No             | No       | App Functionality (opt-in only) |
| Voice recordings         | No             | No       | App Functionality (transcribed locally; never stored or transmitted) |

All other categories: **Data Not Collected**.

---

## 4. Play Console Data Safety (paste into Data Safety form)

**Does your app collect or share any of the required user data types?**

- Yes — but only **opt-in** crash logs and **opt-in** product analytics.

**For each opted-in data type:**

- *Crash logs* — Collected, not shared. Encrypted in transit. User can request
  deletion via Sentry's data-export controls.
- *App diagnostics (analytics)* — Collected, not shared. Encrypted in transit.
  User can request deletion.

**For everything else** (location, contacts, files, photos, audio, etc.):

- **Data Not Collected.**

**Does your app collect data even when you say it doesn't?**

- No.

**Is all of the user data collected by your app encrypted in transit?**

- Yes (Sentry / PostHog HTTPS endpoints; nothing else leaves the device).

**Do you provide a way for users to request that their data be deleted?**

- Yes, via Settings → "Erase all data" (wipes Room/JSON locally) and via
  Sentry / PostHog data-export tooling for opted-in telemetry.

---

## 5. Voice / Speech specifics

The watch composer and the Quick Settings tile flow accept voice input. The
audio:

- Is processed by the **on-device** speech recognizer (`SFSpeechRecognizer` on
  Apple, `SpeechRecognizer` on Android with the **on-device** flag set).
- Is **never** sent to Apple or Google speech servers (the on-device flag is
  required at runtime; if the device doesn't support on-device, the voice path
  is disabled and the composer falls back to typing).
- Is **never** stored — the transcription is the only output and the audio
  buffer is released immediately.

This is also true for the iOS Share Extension's voice fallback, which is gated
behind the same on-device check.

---

## 6. App Group + Share Extension

The iOS Share Extension writes to `group.com.americangroupllc.card`, the same
container the main app reads from. This means:

- The Share Extension can see Cards written by the main app, and vice versa.
- The container is sandboxed by iOS — no other app can read it.
- The container is **not** backed up to iCloud unless the user has iCloud
  Backup enabled at the OS level (Card itself never opts into iCloud sync).

---

## 7. Children

Card is rated 4+ on the App Store and "Everyone" on Play. No data is collected
that could conflict with COPPA / GDPR-K, because no data is collected by
default.
