# Pocket — Privacy Policy

*Last updated: 2026-05-06*

## TL;DR

- **No account.** No login. No email collected.
- **No tracking by default.** Crash reporting and product analytics ship as
  *off-by-default* and only run if you opt in via Settings → Privacy.
- **Local-only data.** Alarms, world clocks, timer presets, and bedtime
  settings live in your device's storage. We never see them.
- **Open source.** Every line is at <https://github.com/AmericanGroupLLC/Pocket>
  under the MIT License.

## What Pocket stores

On your device, in OS-private storage that's wiped if you uninstall:

- Your alarms (time, label, repeat days, sound choice).
- Your World Clock entries (IANA timezone strings).
- Your timer presets (duration, label).
- Your bedtime settings (wake / sleep target).
- Your privacy preferences (12/24-hour, opt-in toggles).

We do **not** sync this anywhere by default. There is no Pocket server.

## What Pocket sends off-device (only if you opt in)

### Crash reports — Sentry (off by default)

If — and only if — you toggle **Settings → Privacy → Crash reports** on, we
send Sentry an event when the app crashes. Each event contains:

- The stack trace (file + line + function names from the binary).
- OS version + app version + device model.
- An anonymous per-event ID.

Each event explicitly **never** contains:

- Your alarm names, schedules, or sounds.
- Your World Clock selections.
- Your bedtime targets.
- Any user identifier (email, account, IDFV, AAID).

A sanitiser strips these fields before any network call. The Sentry
free-tier endpoint receives at most 5,000 events per month, after which we
drop new events on the floor.

### Product analytics — PostHog (off by default)

If — and only if — you toggle **Settings → Privacy → Product analytics** on,
we send PostHog anonymous feature-usage events:

- "alarm_set" (count, no name).
- "world_clock_added" (count, no zone).
- "bedtime_configured" (count, no time).
- App-launch count + screen-view count.

Each event explicitly **never** contains:

- The alarm time, label, sound, or repeat days.
- The World Clock zone or city.
- The bedtime time.
- Any user identifier.

PostHog free-tier ingests at most 1,000,000 events per month, after which we
drop new events on the floor.

## What we never collect

- Location data.
- Microphone or camera access.
- Calendar or contacts access.
- HealthKit / Health Connect data.
- Browser history.
- Any cross-app or cross-site identifiers.

## Permissions we ask for

| Permission | Why | When |
|---|---|---|
| Notifications (iOS / Android `POST_NOTIFICATIONS`) | Surface alarms + bedtime reminders | Onboarding, before first alarm |
| Schedule exact alarm (Android `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`) | Fire alarms at the requested minute even under battery-saver | Implicit, granted by default for alarm-clock apps |
| Boot completed receiver (Android `RECEIVE_BOOT_COMPLETED`) | Re-schedule alarms after device reboot | Implicit |
| Wake lock (Android `WAKE_LOCK`) | Brief wake to surface the alarm notification | Implicit |

We do **not** ask for: location, microphone, camera, contacts, calendar,
storage (beyond app-private), HealthKit, Health Connect, advertising ID,
biometric authentication.

## Children

Pocket is suitable for all ages. There is no account, no chat, no in-app
purchase, and no social feature.

## Changes to this policy

If we ever change what data is sent off-device, we will:

1. Update this file in the repo.
2. Bump the **Last updated** date above.
3. Note the change in the GitHub Release notes.
4. Add a one-time in-app banner explaining the change.

## Contact

For privacy questions, open an issue at
<https://github.com/AmericanGroupLLC/Pocket/issues> or email the maintainers
listed in the repo's `LICENSE` file.

## Where this policy is hosted

When the marketing site is published to GitHub Pages (via `marketing.yml`),
this policy is served at:

> `https://americangroupllc.github.io/Pocket/PRIVACY.md`

That URL is the one to drop into the Apple App Store Connect privacy URL
field and the Google Play Console privacy policy URL field.
