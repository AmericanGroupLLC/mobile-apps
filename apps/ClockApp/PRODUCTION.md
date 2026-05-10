# Pocket — Production Readiness

> Honest answer: **not today**. Code is in. CI is in. Real OS-scheduled
> alarms are wired. But three things stand between this repo and an
> App Store / Play Store live listing:
>
> 1. **Two store-developer-account fees** — $99/yr (Apple) + $25 once (Google). Outside the repo.
> 2. **One real 1024×1024 app icon** — only the asset-set scaffolding ships.
> 3. **Three weeks of real-device polish** — see the polish list below.

## Gap audit

| Concern | Status | Where |
|---|---|---|
| Real OS alarm scheduling | ✅ Wired | `ios/.../AlarmService.swift`, `android/app/.../AlarmReceiver.kt` |
| Reboot survival (Android) | ✅ | `BootReceiver.kt` registered in `AndroidManifest.xml` |
| Persistence | ✅ | `AlarmStore` (Apple, JSON in UserDefaults), `AlarmDb` (Android Room) |
| `Info.plist` privacy strings | ✅ | `ios/Pocket/Resources/Info.plist` (`NSUserNotificationsUsageDescription` etc.) |
| Android runtime permissions | ✅ | `POST_NOTIFICATIONS` (API 33+), `SCHEDULE_EXACT_ALARM` (API 31+) |
| Notification channel | ✅ | `AlarmService.kt` creates `pocket.alarms` channel at boot |
| Onboarding flow | ✅ | iOS `OnboardingView.swift`, Android `OnboardingScreen.kt` |
| Settings (privacy toggles) | ✅ | iOS `SettingsView.swift`, Android `SettingsScreen.kt` |
| 1024×1024 app icon | ⚠️ scaffolding only | `ios/Pocket/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json` |
| Wear Tile + Complication | ✅ Stubs | `android/wear/.../tile/NextAlarmTileService.kt`, `complication/NextAlarmComplicationService.kt` |
| watchOS complication | ✅ Stub | `watchos/PocketComplication/NextAlarmComplication.swift` |
| Sentry / PostHog wiring | ✅ Opt-in stubs | `shared/PocketCore/.../{AnalyticsService,CrashReportingService}.swift`, `android/core/.../AnalyticsService.kt` |
| Sentry / PostHog real install | ❌ Documented only | [`OBSERVABILITY.md`](./OBSERVABILITY.md) |
| Signing (Android release) | ✅ Scaffolded | `android/keystore.properties.example`, `android/app/build.gradle.kts` `signingConfigs.release` |
| Signing (iOS) | ✅ Documented | [`ios/SIGNING.md`](./ios/SIGNING.md) |
| App Store privacy nutrition labels | ⚠️ Need to fill in App Store Connect | Out of repo |
| Play Store data-safety form | ⚠️ Need to fill in Play Console | Out of repo |
| Privacy policy URL | ⚠️ Self-host or GitHub Pages from `PRIVACY.md` | [`PRIVACY.md`](./PRIVACY.md) |
| Marketing screenshots | ❌ Not generated | App Store Connect / Play Console accept the same screenshots |
| Localizations | ⚠️ English only | Easy to add — `Localizable.strings` (Apple) / `strings.xml` (Android) |

## Free-deploy path (today)

Without paying the store fees you can still:

1. **Build the apps for real devices in dev mode.**
   - iOS: open `ios/Pocket.xcodeproj`, set `DEVELOPMENT_TEAM` to your free Apple ID Team ID, run on a paired iPhone (signs with a 7-day provisioning profile).
   - Android: `./gradlew :app:installDebug` to a connected device or sideload the debug APK from a GitHub Release.
2. **Run the marketing site on GitHub Pages free tier.** Push triggers `marketing.yml` which deploys `index.html` + `styles.css` + `script.js` to Pages.
3. **Distribute APKs via GitHub Releases.** Tag → release pipeline produces signed-on-CI debug APKs you can sideload.

## One-time setup before tagging `v1.0.0`

| Item | Where | Why |
|---|---|---|
| Pay $99 Apple Developer Program fee | <https://developer.apple.com/programs/> | Required for App Store + TestFlight |
| Pay $25 Google Play Console fee (one-time) | <https://play.google.com/console/signup> | Required for Play Store |
| Generate a 1024×1024 PNG app icon | drop into `ios/Pocket/Resources/Assets.xcassets/AppIcon.appiconset/` and `android/app/src/main/res/mipmap-*` | Stores reject submissions without one |
| Generate Apple App Store Connect API key | secrets `APP_STORE_CONNECT_API_KEY_*` | TestFlight upload |
| Generate Google Play service-account JSON | secret `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Play upload |
| Generate Android upload keystore | secrets `ANDROID_KEYSTORE_*` | Sign release APK/AAB |
| Sign up for Sentry free tier (optional) | secret `SENTRY_DSN_*` | Crash reporting |
| Sign up for PostHog free tier (optional) | secret `POSTHOG_*` | Analytics |
| Publish privacy-policy URL | host `PRIVACY.md` rendered to HTML on GitHub Pages | Apple + Google require it |

## 3-week pre-launch polish list

**Week 1 — visuals**
- Real 1024×1024 app icon + Apple/Android adaptive variants (round, monochrome).
- 3-7 marketing screenshots per device family (iPhone 6.7"/6.5", Apple Watch 46mm, Android phone 6.7", Wear OS round).
- Replace `LaunchScreen.storyboard` placeholder with branded splash.

**Week 2 — copy + legal**
- Polish App Store listing (subtitle, promotional text, keywords).
- Polish Play Store listing (short description, full description, feature graphic).
- Fill in App Store Connect privacy nutrition labels.
- Fill in Play Console data-safety form.
- Verify privacy policy URL renders.

**Week 3 — real-device QA**
- Run [`TESTING.md`](./TESTING.md) **Real-device-only checklist** on at least:
  - 1× iPhone (iOS 17+) + paired Apple Watch
  - 1× Android phone (Android 13+) + paired Wear OS watch
- Battery test: 24-hour idle with 5 alarms scheduled, verify no excess drain.
- Snooze + reboot regression sweep.

## Is it ready today?

**Honest summary**:

- ✅ Code complete for v1 functionality.
- ✅ CI passes on every push; tagged releases produce binaries.
- ✅ Real OS-scheduled alarms work with Snooze 9 / Stop and survive reboot.
- ✅ Privacy posture is defensible — no account, no tracking by default.
- ⚠️ Missing the icon, missing the dev-program fees, missing the polish week.
- 🚫 Not yet listed on either store.

After the icon + fees + polish week, **first tagged release**: `v0.1.0-rc1`.
After 1-2 weeks of TestFlight / Play internal-track shake-out: `v1.0.0`.
