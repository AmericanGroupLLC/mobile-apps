# Card — STORE PACKAGING

App Store (iOS + watchOS) and Play Store (Android phone + Wear OS) listing
metadata, screenshots, and the data-safety / privacy-label tables.

---

## 1. App Store Connect — iOS + watchOS

Card ships as **one iOS app with an embedded Apple Watch app**. The
`watchos/` Xcode project produces a standalone `.app` for QA convenience, but
for store submission the watch app must be embedded inside the iOS `.ipa` as a
`watch2-app` extension target.

### Migration: standalone watchOS → embedded

In `ios/project.yml`, add the watchOS app and complication as embedded
extensions of the iOS target:

```yaml
targets:
  Card:
    type: application
    platform: iOS
    dependencies:
      - target: CardWatchApp        # the watchOS app, brought into ios/project.yml
      - target: CardShareExtension
  CardWatchApp:
    type: watch2-app
    platform: watchOS
    dependencies:
      - target: CardComplication
  CardComplication:
    type: app-extension
    platform: watchOS
```

Then move `watchos/CardWatch/` and `watchos/CardComplication/` source paths
into the iOS `project.yml` so they get embedded at archive time.

For now (v0.1.0) the standalone `watchos/CardWatch.xcodeproj` is the
development scaffold — submission requires the merge above.

### Bundle IDs (already set in `project.yml`)

| Target               | Bundle ID                                            |
|----------------------|------------------------------------------------------|
| Card (iOS)           | `com.americangroupllc.card`                          |
| CardShareExtension   | `com.americangroupllc.card.share`                    |
| CardWatchApp         | `com.americangroupllc.card.watchkitapp`              |
| CardComplication     | `com.americangroupllc.card.complication`             |

App Group (used by Card + CardShareExtension to share the JSON CardStore):
`group.com.americangroupllc.card` — must be created in your developer account
under Identifiers → App Groups.

### Privacy Nutrition Label (App Store Connect → App Privacy)

| Data Type                         | Linked to user | Tracking | Purpose                         |
|-----------------------------------|----------------|----------|---------------------------------|
| Crash data                        | No             | No       | App functionality (opt-in only) |
| Performance data                  | No             | No       | App functionality (opt-in only) |
| Diagnostic data                   | No             | No       | App functionality (opt-in only) |
| Voice recordings (transcribed)    | No             | No       | App functionality (Watch dictation; never stored as audio) |

All other categories: **None collected**.

### Permission strings (final wording)

- `NSUserNotificationsUsageDescription` — "Card needs to send notifications so the reminders you set actually fire."
- `NSMicrophoneUsageDescription` — "Card – Save can record a quick voice note. Audio is transcribed on device and discarded."
- `NSSpeechRecognitionUsageDescription` — "Card uses on-device speech recognition to turn dictation into Cards. The recordings never leave your phone."

---

## 2. App Store screenshots

Required sizes (all device classes):

- **iPhone 6.7"** — 1290 × 2796
- **iPhone 6.5"** — 1242 × 2688
- **iPhone 5.5"** — 1242 × 2208 (still required if you target old hardware)
- **iPad Pro 12.9" (3rd gen)** — 2048 × 2732 (only if you ship iPad)
- **Apple Watch (44mm + 49mm Ultra)** — 396 × 484 / 410 × 502

Suggested screen flow (5 screenshots):

1. Hero feed with three cards visible.
2. Composer mid-type ("Buy milk").
3. Action sheet open on a Card with all three convert toggles.
4. Reminder time picker.
5. Watch composer mid-dictation (or watch feed list).

---

## 3. Play Console — Android phone + Wear OS

Card ships as **one app, two listings**:

- **Phone** — `com.americangroupllc.card`, AAB built from `android/app/`.
- **Wear OS** — same package, separate listing flagged `wearOnly`, AAB built
  from `android/wear/`.

The Play Console links them automatically when the same `applicationId` is
detected.

### Data Safety form

Pasteable answers:

- **Does your app collect or share any of the required user data types?**
  - Crash logs / diagnostics — **opt-in only**.
- **Is all of the user data collected by your app encrypted in transit?** — N/A (nothing leaves the device by default).
- **Do you provide a way for users to request that their data be deleted?** —
  Yes, via Settings → Erase all data (wipes the local Room DB).

### `SCHEDULE_EXACT_ALARM` justification

Required since Android 14:

> Card uses `SCHEDULE_EXACT_ALARM` only to fire user-set reminders at the
> exact minute the user picked. The permission is never used to wake the
> device for any background task. Reminders are scheduled when the user
> creates them and re-scheduled by `BootReceiver` after a reboot. There is no
> server-side trigger.

### Quick Settings tile listing

The `<service>` entry in `AndroidManifest.xml` powers the tile listing. Play
requires:

- A 24×24 dp white-on-transparent icon (`@drawable/ic_quick_capture_tile`).
- A short label ("Card – Capture").
- A description ("Tap to add a Card without opening the app.").

---

## 4. Play screenshots

- **Phone** — minimum 320 px on the short side, 16:9, max 8 screenshots.
- **Wear** — 384 × 384, max 8 screenshots.
- **Feature graphic** — 1024 × 500 (required for Play listing).

Suggested flow mirrors the iOS list above.

---

## 5. Asset prep checklist before submission

- [ ] App Icon (iOS 1024×1024 + adaptive Android `mipmap-anydpi-v26/`).
- [ ] Apple Watch complication preview screenshots.
- [ ] Quick Settings tile preview (Android).
- [ ] Wear OS tile preview.
- [ ] Five iPhone 6.7" screenshots.
- [ ] Five Android phone screenshots.
- [ ] Privacy policy URL (host on the marketing site, e.g.
  `https://americangroupllc.github.io/Card/privacy`).
- [ ] Demo account — Card needs none; explain "no account required" in the
  reviewer notes field.
- [ ] App Store Promotional text + Description (use the bullets from
  `index.html`).
- [ ] Play Short description (80 chars max) + Full description.

---

## Desktop binaries (Electron)

The `build-desktop` job in `.github/workflows/release.yml` uses
`electron-builder` on an Ubuntu runner to produce three artifacts
attached to every GitHub Release:

| Artifact                      | Signed?  | Notes                          |
|-------------------------------|:--------:|--------------------------------|
| `Card-Setup-X.Y.Z.exe` (NSIS) | no       | Windows SmartScreen will prompt on first run; click *More info* → *Run anyway*. |
| `Card-X.Y.Z.AppImage`  | no       | `chmod +x` then double-click on Linux. |
| `Card-X.Y.Z.dmg`       | **no**   | macOS Gatekeeper will refuse. To install: |

```bash
xattr -cr "/Volumes/Card/Card.app"
cp -R "/Volumes/Card/Card.app" /Applications/
```

(or *System Settings → Privacy & Security → Open Anyway*.)

A future change can add a separate `macos-latest` job + Apple
Developer cert to produce a properly notarised .dmg without
restructuring this workflow.

The Electron shell loads the existing root `index.html` in a
`BrowserWindow` with `contextIsolation` enabled. See
`desktop/main.js`.
