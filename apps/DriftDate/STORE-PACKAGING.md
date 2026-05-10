# Drift — STORE PACKAGING

Notes on getting Drift into the App Store, Play Store, and TestFlight /
Play Internal track.

## 1. iOS — Xcode targets vs App Store layout

XcodeGen generates a project with these targets:

- `Drift` (the iPhone app)
- `DriftNotificationService` (Notification Service Extension, rich-push)
- `DriftTests`
- `DriftUITests`

The Apple Watch app is in **a separate project** (`watchos/DriftWatch.xcodeproj`).
For development this is fine — both run side by side in the simulator.

**For App Store submission**, the watchOS app must be embedded inside the
iOS app's `.ipa` as a watch2-app extension target. This requires either:
1. Combining `watchos/project.yml` into `ios/project.yml` as a nested
   target with the `WKApplication` flag, **or**
2. Using `xcodebuild -workspace` with the watchOS project added as a
   sub-project.

Until Drift submits to App Store, we keep them split for faster
incremental development. The migration is a single
`ios/project.yml` change planned for v1.1.

## 2. Android — single AAB, single Wear APK

Two `applicationId`s — `com.americangroupllc.drift` and
`com.americangroupllc.driftwear` — meaning **two separate Play Console
listings** linked together (Play recognises a "wearable companion" via
the `<uses-feature android:name="android.hardware.type.watch" />` flag in
the wear manifest).

## 3. Bundle ID map (canonical)

| Surface | Bundle ID |
|---|---|
| iOS app                       | `com.americangroupllc.drift` |
| iOS Notification Extension    | `com.americangroupllc.drift.notify` |
| Apple Watch app               | `com.americangroupllc.drift.watchkitapp` |
| Apple Watch complication      | `com.americangroupllc.drift.complication` |
| Android phone                 | `com.americangroupllc.drift` |
| Wear OS app                   | `com.americangroupllc.driftwear` |
| iOS App Group                 | `group.com.americangroupllc.drift` |

## 4. Permissions / usage strings

### iOS — `Info.plist` keys

- `NSCameraUsageDescription` — "Drift uses the camera so you can take a live verification selfie and add photos to your profile. Photos and the selfie are uploaded only when you confirm the upload."
- `NSPhotoLibraryUsageDescription` — "Drift lets you pick existing photos for your profile."
- `NSMicrophoneUsageDescription` — "Drift records a 30-second voice prompt for your profile so people can hear your voice before they wave."
- `NSLocationWhenInUseUsageDescription` — "Drift uses your location only to fuzz it to a ZIP-prefix on your device. Drift's servers never see your precise location."
- `NSUserNotificationsUsageDescription` — "Drift notifies you when someone waves at you or sends a message."

**No Bluetooth strings, no precise-location strings.**

### Android — `AndroidManifest.xml`

- `INTERNET`
- `POST_NOTIFICATIONS`
- `RECEIVE_BOOT_COMPLETED`
- `CAMERA`
- `RECORD_AUDIO`
- `ACCESS_COARSE_LOCATION` (only if user opts into the ZIP-finder
  in onboarding; **never `ACCESS_FINE_LOCATION`**)

**No Bluetooth permissions, no precise-location, no foreground service.**

## 5. App Store / Play Store review notes

- The dating-app category requires demo credentials. Use a phone number we
  control (Twilio test number) and a verified profile flagged as
  `is_review_account` in Postgres.
- Verification image processing (AWS Rekognition CompareFaces) is
  documented in `PRIVACY.md` §3 and `SAFETY.md` §1. Highlight that we
  store **only the boolean result**, never the facial-feature embedding.
- Block + Report are surfaced in three places (profile, chat, settings)
  per Apple's UGC guidelines.

## 6. Marketing site

`marketing.yml` deploys the static site at `index.html` to GitHub Pages.
DNS for `drift.americangroupllc.com` (or whatever the brand domain is)
is wired manually in the repo Settings → Pages → Custom domain.

## 7. What's-new copy

Lives in `distribution/whatsnew/whatsnew-en-US/whatsnew.txt`. The Play
release workflow uploads it via `r0adkll/upload-google-play@v1`. App
Store Connect's "What's New" field is updated manually each release
(automating it requires App Store Connect API privileges Drift doesn't
yet have).

---

## Desktop binaries (Electron)

The `build-desktop` job in `.github/workflows/release.yml` uses
`electron-builder` on an Ubuntu runner to produce three artifacts
attached to every GitHub Release:

| Artifact                      | Signed?  | Notes                          |
|-------------------------------|:--------:|--------------------------------|
| `Drift-Setup-X.Y.Z.exe` (NSIS) | no       | Windows SmartScreen will prompt on first run; click *More info* → *Run anyway*. |
| `Drift-X.Y.Z.AppImage`  | no       | `chmod +x` then double-click on Linux. |
| `Drift-X.Y.Z.dmg`       | **no**   | macOS Gatekeeper will refuse. To install: |

```bash
xattr -cr "/Volumes/Drift/Drift.app"
cp -R "/Volumes/Drift/Drift.app" /Applications/
```

(or *System Settings → Privacy & Security → Open Anyway*.)

A future change can add a separate `macos-latest` job + Apple
Developer cert to produce a properly notarised .dmg without
restructuring this workflow.

The Electron shell loads the existing root `index.html` in a
`BrowserWindow` with `contextIsolation` enabled. See
`desktop/main.js`.
