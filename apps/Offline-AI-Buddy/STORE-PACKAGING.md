# STORE-PACKAGING.md

How Offline AI Buddy v1 ships to the App Store and Google Play.

## §1 — App Store (iPhone)

| Field | Value |
|---|---|
| Display name | Offline AI Buddy |
| Bundle ID | `com.americangroupllc.offlineaibuddy` |
| Min OS | iOS 17 |
| Devices | iPhone (no iPad-specific layout in v1) |
| Category | Productivity |
| Subcategory | Utilities |
| Age rating | 12+ (open-text AI; kid-safe profile available) |
| Pricing | Free with IAP ($4.99/mo subscription, $19.99 one-time lifetime) |

### Capabilities used

- **App Group** — `group.com.americangroupllc.offlineaibuddy` declared
  on the main target AND the keyboard extension; required for the
  smart-reply IPC.
- **In-App Purchase** — StoreKit via RevenueCat.
- **Microphone + Speech Recognition** — usage descriptions in
  `Info.plist`; permissions prompted on first push-to-talk use.
- **Background Tasks** — `URLSession` background download for the
  ~1 GB model.

### NOT used

- Push notifications (no APS entitlement).
- Camera, Photos, Contacts, Location, HealthKit, Bluetooth.
- Sign in with Apple (no accounts).

### Privacy nutrition label

| Section | v1 |
|---|---|
| Data Used to Track You | None |
| Data Linked to You | None |
| Data Not Linked to You | None (opt-in v1.1: anonymous usage counts) |

### App Review notes (CRITICAL — paste into App Review Notes field)

> Offline AI Buddy is an on-device LLM app. On first launch the app
> downloads a ~1 GB language model file over Wi-Fi (size + Wi-Fi
> requirement disclosed on the Consent screen BEFORE the download
> starts). After that, all features run offline.
>
> Test account: not required (no accounts).
> Sandbox IAP: enable a sandbox tester to test the
> `oab_pro_monthly` subscription and `oab_pro_lifetime` one-time
> purchase from the Settings → Premium screen.
> Keyboard extension: enable "Buddy Keyboard" in iOS Settings →
> General → Keyboard → Keyboards → Add New Keyboard. Then open Messages
> and tap the globe to switch to Buddy Keyboard. Type any sentence; the
> candidate strip will populate with 3 AI-generated suggestions
> (sourced from the main app via App Group).
> Kid-safe profile: switch profiles from the home screen avatar; PIN
> defaults to `1234` in TestFlight builds for ease of review.

## §2 — Google Play (Android)

| Field | Value |
|---|---|
| Application label | Offline AI Buddy |
| Package | `com.americangroupllc.offlineaibuddy` |
| `minSdkVersion` | 26 (Android 8) |
| `targetSdkVersion` | 34 (Android 14) |
| Category | Productivity |
| Content rating | Teen (open-text AI; kid-safe profile available) |
| Ads | Yes (interstitial only; no banner ads) — declared in Data Safety. |
| In-app purchases | Yes — declared in Data Safety. |

### Permissions declared

See `PRODUCTION.md §3`. Summary: Mic + Internet + Network State +
Notifications + ForegroundService + BindInputMethod + Billing only.
**No camera, no Bluetooth, no location.**

### AdMob App ID (release builds)

The `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID">`
entry in `android/app/src/main/AndroidManifest.xml` is wired via the
`admobAppId` manifestPlaceholder set in `android/app/build.gradle.kts`.
Resolution order:

1. Gradle project property `-PADMOB_APP_ID_ANDROID=ca-app-pub-XXXX...`
2. Environment variable `ADMOB_APP_ID_ANDROID`
3. Google's official sample/test ID
   (`ca-app-pub-3940256099942544~3347511713`) — used by CI and local dev
   builds so the process doesn't crash at startup with the
   `MobileAdsInitProvider` `IllegalStateException`.

**Production releases must pass the real ID.** For local release builds:

```bash
cd android
./gradlew -PADMOB_APP_ID_ANDROID=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY \
  :app:bundleRelease
```

In CI, define the `ADMOB_APP_ID_ANDROID` GitHub repository secret. The
`.github/workflows/release-binaries-only.yml` workflow forwards it to
gradle automatically when present (and warns + falls back to the test ID
when it is empty).

### Data safety form

| Question | Answer |
|---|---|
| Does your app collect or share any user data? | **No** (default). v1.1 may add an opt-in usage-count flag. |
| Does your app encrypt data in transit? | Yes (model download is HTTPS only). |
| Can users request deletion? | N/A (no remote data; "Erase all chats" + "Delete model" wipe local store). |

### Play Console release tracks

`release.yml` routes by tag suffix:
- `vX.Y.Z`              → production
- `vX.Y.Z-rc.N`         → beta
- `vX.Y.Z-beta.N`       → beta
- `vX.Y.Z-alpha.N`      → alpha
- `vX.Y.Z-internal.N`   → internal

## §3 — Marketing assets

Per-store screenshots live in `distribution/screenshots/<platform>/<lang>/`
(not committed; generated on demand). Required:

- iOS: 6.7" (iPhone 16 Pro Max), 6.5" (iPhone 11 Pro Max), 5.5" (iPhone 8 Plus).
- Android: phone (1080×1920) — minimum 2, maximum 8.

Localised whatsnew text lives in `distribution/whatsnew/whatsnew-<locale>/whatsnew.txt`
for en-US, hi-IN, zh-CN, fr-FR, es-ES.

## §4 — What's new

`distribution/whatsnew/whatsnew-en-US/whatsnew.txt` is uploaded by
`release.yml` as the Play Store release notes (English fallback). The
other four locales are uploaded the same way to their localised slots.
Keep each under 500 chars.

## §5 — Bundle size budget

See `PRODUCTION.md §7`. The store binary stays < 50 MB; the ~1 GB
model is downloaded on first launch.

## §6 — App Review risk flags

| Risk | Mitigation |
|---|---|
| 1 GB-on-first-launch download flagged as misleading | Consent screen on first launch states the download size + Wi-Fi requirement BEFORE the download starts. Pasted in App Review Notes (§1). |
| AI-generated content flagged for moderation | Kid-safe profile + content blocklist + `SAFETY.md` documents the policy explicitly. App Review Notes link to it. |
| Keyboard extension flagged for collecting keystrokes | Extension's `RequestsOpenAccess = false`; it cannot reach network. IPC via App Group. Documented in `KEYBOARD.md`. |

---

## Desktop binaries (Electron)

The `build-desktop` job in `.github/workflows/release.yml` uses
`electron-builder` on an Ubuntu runner to produce three artifacts
attached to every GitHub Release:

| Artifact                      | Signed?  | Notes                          |
|-------------------------------|:--------:|--------------------------------|
| `Offline AI Buddy-Setup-X.Y.Z.exe` (NSIS) | no       | Windows SmartScreen will prompt on first run; click *More info* → *Run anyway*. |
| `Offline AI Buddy-X.Y.Z.AppImage`  | no       | `chmod +x` then double-click on Linux. |
| `Offline AI Buddy-X.Y.Z.dmg`       | **no**   | macOS Gatekeeper will refuse. To install: |

```bash
xattr -cr "/Volumes/Offline AI Buddy/Offline AI Buddy.app"
cp -R "/Volumes/Offline AI Buddy/Offline AI Buddy.app" /Applications/
```

(or *System Settings → Privacy & Security → Open Anyway*.)

A future change can add a separate `macos-latest` job + Apple
Developer cert to produce a properly notarised .dmg without
restructuring this workflow.

The Electron shell loads the existing root `index.html` in a
`BrowserWindow` with `contextIsolation` enabled. See
`desktop/main.js`.
