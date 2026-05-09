# MyHealth — Production Readiness & Store Deployment

> **Honest answer**: the **CI/CD pipeline is production-grade**; the **app code itself needs ~3 weeks of polish + the unavoidable store fees** before it's accepted by Apple App Review or Google Play Review.
>
> Everything below is **free** except the two store fees.

---

## 1. Are you ready to ship today? — gap audit

| Status | Item | What's needed |
|---|---|---|
| ✅ Done | iOS app builds, signs, and uploads via CI | – |
| ✅ Done | Android phone APK + AAB builds and uploads via CI | – |
| ✅ Done | Wear OS APK builds | – |
| ✅ Done | iOS Simulator UI tests + Android unit tests | – |
| ✅ Done | Backend smoke + Jest tests pass | – |
| ✅ Done | GitHub Release artefact pipeline | – |
| ✅ Done | Play Store auto-upload (`r0adkll/upload-google-play`) | Just needs the Service Account secret |
| ✅ Done | TestFlight auto-upload (`Apple-Actions/upload-testflight-build`) | **Just added in this commit** — needs App Store Connect API key secret |
| ✅ Done | Onboarding · Guest Mode · 5-tab nav · Vitals · Bio Age · Medicine reminders · Diary | – |
| ⚠️ Gap | **Apple Developer Program membership** | **$99 / year** — unavoidable. Without it Xcode won't even sign for device. |
| ⚠️ Gap | **Google Play Developer account** | **$25 one-time** — unavoidable. Without it, Play Console rejects your AAB. |
| ⚠️ Gap | **Real app icon (1024 × 1024 PNG)** | 5 min in any free icon tool ([icon.kitchen](https://icon.kitchen) is free) |
| ⚠️ Gap | **App Store screenshots** (iPhone 6.7" + 5.5", iPad 12.9", Apple Watch) | Generated via `fastlane snapshot` — free |
| ⚠️ Gap | **Play Store screenshots** (Phone, 7" tablet, 10" tablet, Wear) | Generated via `fastlane screengrab` — free |
| ⚠️ Gap | **Privacy policy URL** | Required by both stores. Use [GitHub Pages site](https://yourorg.github.io/HealthApp) — free. |
| ⚠️ Gap | **App description, keywords, category** | Manual entry in Play Console + App Store Connect, ~30 min |
| ⚠️ Gap | **Apple Health usage descriptions** in `Info.plist` | Already present (`NSHealthShareUsageDescription` etc.) — review wording |
| ⚠️ Gap | **HealthKit privacy declaration** in App Store Connect | Manual form, ~15 min |
| ⚠️ Gap | **Play Data Safety form** | Manual form in Play Console, ~30 min |
| ⚠️ Gap | **Real `.mlmodel` files** for AdaptivePlanner + FoodClassifier | App falls back to heuristic; OK to ship without |
| ⚠️ Gap | **Real exercise demo videos** | Detail page falls back to placeholder; OK to ship |
| ⚠️ Gap | **Sign in with Apple** (App Store rule 4.8) | Only required if you ship login at all. Guest Mode means we may be exempt — verify with App Review. |
| ⚠️ Gap | **Account deletion endpoint** (App Store rule 5.1.1(v) / Play Data Deletion) | Wire `DELETE /api/auth/me` in backend; surface "Delete account" in Settings. ~2 hours. |
| ⚠️ Gap | **Real app icon assets** in iOS Assets.xcassets / Android mipmap | Drop a 1024×1024 PNG; everything else is templated |
| ⚠️ Gap | **Production-grade signing keys** (release keystore for Android, distribution provisioning for iOS) | Generate once, store as Base64 GitHub Secret — see below |
| ⚠️ Optional | **Crash reporting** (Sentry / Firebase Crashlytics) | Both have free tiers. Recommended before public beta. |
| ⚠️ Optional | **Analytics** (PostHog / Plausible / Umami self-hosted) | Free open-source options |
| 🔵 Future | Apple Health entitlement approval | Auto-approved for HKHealthStore reads; some types need explicit declaration |
| 🔵 Future | "Made for kids" / age gating | Not applicable unless you target under-13 users |
| 🔵 Future | EU AI Act / FDA clearance | Only if you make diagnostic claims (we explicitly don't — bio-age has disclaimers) |

**Effective time to first store submission**: ~3 weeks of polish + waiting for Apple Review (1-3 days first time) + Play Review (a few hours typically).

---

## 2. Free deploy path — who pays for what

| Component | Cost | Why |
|---|---|---|
| **GitHub Actions (public repo)** | **FREE — unlimited minutes** | Public repos get unlimited Linux + macOS minutes |
| **GitHub Actions (private repo)** | 2,000 free min/mo Linux, **200 free min/mo macOS** (10× billing multiplier) | Should be enough for ~10 releases/month |
| Fastlane | **FREE (MIT)** | OSS by Felix Krause |
| `r0adkll/upload-google-play` | **FREE (MIT)** | OSS GitHub Action |
| `Apple-Actions/upload-testflight-build` | **FREE (MIT)** | Maintained by Apple |
| Codecov (public repo) | **FREE — unlimited** | Free tier covers public repos |
| GitHub Pages (privacy policy site) | **FREE — unlimited** | Static hosting |
| **Apple Developer Program** | **$99 / year** | **Unavoidable** — Apple's gate |
| **Google Play Developer** | **$25 one-time** | **Unavoidable** — Google's gate |

**Total cash to ship:** ~$124 first year, $99/year after.

---

## 3. The wired-up CI/CD path (what you already have)

```
git tag v1.0.0
git push origin v1.0.0
        ↓
.github/workflows/release.yml fires
        ↓
        ├─ build-android       (ubuntu, free)        →  APK + AAB
        ├─ build-ios           (macos, ~5-10 min)    →  unsigned XCArchive
        ├─ build-server        (ubuntu, free)        →  tarball
        ├─ build-web           (ubuntu, free)        →  zip
        ↓
publish-github-release   →  Creates Release at v1.0.0 with all artefacts
        ↓
publish-play-store       →  Uploads AAB to Play Console (gated by secret)
publish-testflight       →  Builds signed .ipa, uploads to TestFlight
                              (gated by App Store Connect API key secret)
```

Both store-upload jobs are **conditionally skipped** if the corresponding
secret isn't set, so the workflow runs cleanly even before you've configured
deployment credentials.

---

## 4. One-time setup checklist

### Android → Google Play

1. Pay **$25** at https://play.google.com/console/signup
2. Create a new app for `com.myhealth.app`
3. Settings → API access → **Create new service account** in Google Cloud Console
4. Grant the service account "Release Manager" role on your app
5. Download the service-account JSON key
6. **Manually upload one APK** to Play Console once (Google requires this so it can register the package name)
7. Generate an upload keystore:
   ```bash
   keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
8. In GitHub repo → Settings → Secrets → New repository secret (one each):
   - `PLAY_STORE_SERVICE_ACCOUNT_JSON` — paste the raw JSON
   - `PLAY_STORE_PACKAGE_NAME` — `com.myhealth.app`
   - `ANDROID_KEYSTORE_BASE64` — `base64 -i upload.jks | pbcopy`
   - `ANDROID_KEYSTORE_PASSWORD` — keystore password
   - `ANDROID_KEY_ALIAS` — `upload`
   - `ANDROID_KEY_PASSWORD` — key password
9. **Done.** Next `git tag v*` push uploads automatically.

### iOS → TestFlight + App Store

1. Pay **$99/year** at https://developer.apple.com/programs/enroll/
2. In Xcode (one time): create the App ID `com.fitfusion.ios` + bundle IDs for the 3 extensions
3. App Store Connect → Users and Access → **Keys** → Generate API key with "App Manager" role
4. Download the `.p8` private key file
5. Note the **Key ID** and **Issuer ID** (visible on the Keys page)
6. In GitHub repo → Settings → Secrets:
   - `APP_STORE_CONNECT_API_KEY_ID` — e.g. `XYZ1234567`
   - `APP_STORE_CONNECT_API_ISSUER_ID` — UUID
   - `APP_STORE_CONNECT_API_KEY_P8_BASE64` — `base64 -i AuthKey_XYZ.p8 | pbcopy`
   - `APPLE_TEAM_ID` — 10-char team ID from Membership page
7. **Optional but recommended** — Fastlane Match for shared code-signing:
   - Create a private GitHub repo (e.g. `MyHealth-Certs`)
   - `fastlane match init` → choose `git` storage → point at that repo
   - `fastlane match appstore` once locally to populate it
   - Add secrets `MATCH_GIT_URL` (e.g. `git@github.com:you/MyHealth-Certs.git`) and `MATCH_PASSWORD` (the symmetric encryption key Match prompted you for)
   - The CI job will read-only sync the cert/profile from this repo
8. **Done.** Next `git tag v*` push builds a signed `.ipa` and uploads to TestFlight automatically.

---

## 5. Three-week pre-launch polish checklist

| Week | What to do |
|---|---|
| **Week 1 — Visuals + Privacy** | • Make a 1024×1024 app icon and drop into `ios/FitFusion/Assets.xcassets/AppIcon.appiconset` and `android/app/src/main/res/mipmap-anydpi-v26/`<br>• Take 6 screenshots per platform/device class (`fastlane snapshot`/`screengrab`)<br>• Write a 1-page privacy policy and host it on GitHub Pages<br>• Write the app description, short tagline, keywords (App Store) / category, contact email |
| **Week 2 — Compliance** | • Add **Delete Account** button in Settings + `DELETE /api/auth/me` route (App Store 5.1.1(v) + Play Data Deletion)<br>• Fill the Apple Privacy Nutrition Labels (App Store Connect → App Privacy)<br>• Fill Play Data Safety form<br>• Verify all `Info.plist` `NSHealthShareUsageDescription` strings are clear + honest<br>• Add Sentry / Crashlytics free tier for crash reports |
| **Week 3 — Beta + dogfood** | • Tag `v0.9.0-beta1` → push → automatic upload to TestFlight (internal) + Play **internal** track<br>• Recruit 5-20 testers via TestFlight + Play Internal email lists<br>• Iterate on feedback; fix bugs<br>• When ready: bump to `v1.0.0`, push, and submit for review (no code change required — the workflow just promotes to `production` track based on the tag suffix) |

---

## 6. Things you do NOT need to worry about

- ✅ The build pipeline (already wired)
- ✅ Code signing automation (Match + ASC API key)
- ✅ The version-bump script (`scripts/bump-version.sh`)
- ✅ Release notes (`distribution/whatsnew/whatsnew-en-US/whatsnew.txt` already templated)
- ✅ macOS runner cost (your repo is public → free)

---

## 7. The realistic answer to "is it production-ready?"

| Question | Answer |
|---|---|
| Will it pass App Review **today**? | ❌ Probably no — needs the icon, screenshots, privacy policy, account-deletion route, privacy form |
| Will it crash and burn on a real device? | ❌ Probably no — but you should TestFlight + Play Internal-track for ~2 weeks first to catch device-specific issues |
| Is the architecture production-quality? | ✅ Yes — privacy-first, local-first, on-device AI, multi-platform, well-tested CI |
| Can you deploy a beta this week? | ✅ Yes — set up the 8 secrets above, tag `v0.1.0-beta1`, push. The CI does the rest. |
| Can you deploy to **production** this week? | ⚠️ Technically yes (Apple/Google won't *prevent* it), but not recommended without the 3-week polish above |

**Bottom line:** the **path** to production is fully wired and free; the **content** still needs ~3 weeks of human polish + $124 in store fees.
