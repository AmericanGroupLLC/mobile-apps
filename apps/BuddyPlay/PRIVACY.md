# PRIVACY.md

## TL;DR

**BuddyPlay does not send any data to us.** No accounts, no servers, no
analytics, no crash reports, no ads. v1 is fully offline.

## What we collect

Nothing.

## What we store on your phone

Two small JSON files:
- **`rivalries.json`** — your win/loss/draw counts per opponent, keyed by
  the opponent's stable per-device UUID and their chosen display name.
- **`device.json`** — a random UUID generated once on first launch. Used
  so other BuddyPlay phones can recognise yours across game sessions.

Both files live in the app's private documents directory. They are never
backed up to a server. You can wipe them at any time:
- **Settings → Erase all rivalries** clears `rivalries.json`.
- **Settings → Reset device ID** regenerates `device.json` (other phones
  will see you as a brand-new opponent).
- **Uninstalling BuddyPlay** removes both files.

## What we share with other devices

Only what's required for two phones to play together:
- Your **display name** (you set this in Settings).
- Your **device UUID**.
- **Game state** (whose turn, board position, dice roll, etc.) for the
  duration of one match.

This data goes only to the other phone you're playing with — never to a
server, never to us. It travels over your Wi-Fi network or directly via
Bluetooth.

## Permissions explained

| Permission | What we do with it |
|---|---|
| Bluetooth | Discover and connect to a nearby BuddyPlay phone when Wi-Fi is unavailable. |
| Local Network (iOS) | Discover nearby BuddyPlay phones via Bonjour. |
| Nearby Wi-Fi devices (Android 13+) | Same purpose, modern Android replacement for the legacy location-permission BLE scan. |
| Location (Android ≤12) | **Not used for location.** Required by Android ≤12 in order to scan for BLE devices. We tag the permission with `neverForLocation` from API 31+ to skip the prompt entirely. |

We never request: camera, microphone, contacts, photos, health, motion,
HealthKit, location-on-modern-Android, push notifications, calendar.

## Children

BuddyPlay is rated 4+ / Everyone. No chat, no UGC, no in-app purchases,
no ads. Suitable for minors. We collect no data, so no parental consent
flow is required.

## Changes to this policy

If a future version (v1.1+) adds optional analytics or crash reporting,
this document will be updated, and the new collection will be **opt-in**
behind a Settings toggle defaulting to OFF, with a fresh in-app disclosure
on the first launch after the update.

## Contact

For questions: open an issue at https://github.com/AmericanGroupLLC/BuddyPlay
