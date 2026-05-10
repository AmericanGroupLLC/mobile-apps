# Card — PRODUCTION

What is real, what is fake, and what blocks shipping to the stores.

---

## 1. What is production-ready

| Area                                    | Status                                                      |
|-----------------------------------------|-------------------------------------------------------------|
| Domain (`Card`, `CardKindTransitions`, `ReminderScheduler`, `CardSorter`) | ✅ pure logic, mirrored Swift + Kotlin, fully tested |
| Storage (`CardStore` JSON, Room)        | ✅ atomic writes; App Group on Apple                        |
| Reminders (UNUserNotifications, AlarmManager) | ✅ real OS-scheduled, survives reboot via `BootReceiver` |
| Quick-capture surfaces                  | ✅ Share Extension, watch complication, Quick Settings tile, Wear tile + complication |
| Settings (12/24h, theme, opt-ins, erase) | ✅ all real and persistent                                  |
| Observability stubs                     | ✅ canImport/canImport-equivalent gating; SDKs not bundled  |
| 6-workflow CI/CD                        | ✅ from day 1, with all 4 known fixes baked in              |
| Marketing site                          | ✅ static + auto-deployed to GitHub Pages                   |

---

## 2. What is fake / placeholder

| Area                          | Reality                                                                     |
|-------------------------------|-----------------------------------------------------------------------------|
| App Icon                      | Asset-set scaffolding only. Add real PNGs before submitting to either store.|
| Marketing screenshots         | None. Generate from the simulators after the visual smoke pass.             |
| Sentry SDK                    | Wrapper present, **SDK not added as a dependency**. See `SENTRY.md` to wire up. |
| PostHog SDK                   | Same as Sentry.                                                             |
| Privacy nutrition / Privacy Labels | Templates in `PRIVACY.md`; you must paste them into the Play Console + App Store Connect by hand. |
| App Group entitlement         | Declared in `Card.entitlements` and `CardShareExtension.entitlements`, but you must enable the App Group in your Apple Developer account first (Identifiers → App Groups → `group.com.americangroupllc.card`). |
| Fastlane `Matchfile`          | Generated inline by `release.yml` from secrets at run time; no committed Matchfile. |
| Real Sentry/PostHog DSNs      | Read from GitHub Secrets at build time; commit nothing.                     |

---

## 3. Gap audit before App Store submission

- [ ] **App Icon** — fill `ios/Card/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`.
- [ ] **Launch screen** — current placeholder `LaunchScreen.storyboard` is a plain background. Add a logo if desired.
- [ ] **App Group registration** — enable `group.com.americangroupllc.card` in your developer account; the Share Extension will not write to the shared `CardStore` until this is done.
- [ ] **Notification permission strings** — already in `Info.plist`; review wording in `STORE-PACKAGING.md`.
- [ ] **Speech / Microphone strings** — already in `Info.plist` (for share-ext voice fallback); review wording.
- [ ] **Privacy Nutrition Labels** — paste the table from `PRIVACY.md` §3 into App Store Connect.
- [ ] **Demo account** — App Store reviewers need to test the app; Card is fully on-device, so write a one-liner explaining no account is required.
- [ ] **Watch complication preview screenshots** — required by App Store Connect for any watchOS submission.

---

## 4. Gap audit before Play Store submission

- [ ] **App Icon** — replace `android/app/src/main/res/mipmap-*` placeholders.
- [ ] **Adaptive icon** — Card requires `mipmap-anydpi-v26/ic_launcher.xml` (foreground/background layers). Not yet shipped.
- [ ] **Play Console Privacy section** — answer the data-safety form using the table in `PRIVACY.md` §4.
- [ ] **Target SDK 34** — already configured in `build.gradle.kts`.
- [ ] **`POST_NOTIFICATIONS` runtime perm** — wired in `MainActivity` on first launch (Android 13+). Test on API 33+ device.
- [ ] **`SCHEDULE_EXACT_ALARM`** — Play requires a justification statement; see template in `STORE-PACKAGING.md`.
- [ ] **Quick Settings tile screenshot** — required for the tile listing description on Play.
- [ ] **Wear app listing** — separate listing tied to the same package; reuse the AAB and indicate `wear_only`.

---

## 5. Things to monitor in production (when SDKs are wired)

- **Capture-loop latency** — `surface_tap_to_disk_ms` event from each `Surface` enum case. Alert on p95 > 500 ms.
- **Reminder fire success rate** — per-platform; alert if < 99%.
- **Share-extension write failures** — should be zero; the App Group container is always available.
- **App-launch crash rate** — Sentry; freeze deploys if > 0.5%.

---

## 6. Things explicitly NOT shipping in v1

These are documented as v1.1 candidates, in priority order:

1. Search across the feed.
2. iOS WidgetKit home-screen widget + Android Glance widget.
3. Today / Upcoming / Done filters when the feed exceeds ~200 cards.
4. Recurring reminders.
5. Tags and saved filters.
6. iCloud / Google Drive optional encrypted backup.
7. AI auto-classification (suggest "this looks like a task").
8. Card sharing (URL → another Card user → import as a Card).
9. Subscription / IAP scaffolding.
