# MyHealth — Store Packaging Reality Check

This is the **honest** doc covering how watch apps actually ship to each store
and what the current MyHealth repo does vs. what each store requires.

---

## TL;DR

| Surface | What stores need | What this repo produces today | Gap |
|---|---|---|---|
| 📱 iPhone | One `.ipa` containing the phone app | ✅ `MyHealth-iOS-iPhone-vX-Simulator.app.zip` (sim) + `.ipa` via TestFlight job | none — once the ASC API key secret is set |
| ⌚ Apple Watch | The watch app **embedded inside** the iPhone app's `.ipa` | ❌ Currently builds a **standalone** `MyHealth-Apple-Watch-vX-Simulator.app.zip` from a separate `watch/HealthAppWatch.xcodeproj` | **Real gap** — see §1 below |
| 🤖 Android phone | One `.aab` for Play Console | ✅ `MyHealth-Android-Phone-vX.aab` | none |
| ⌚ Wear OS | Either (a) standalone `.aab` with own Play listing, OR (b) embedded as wearable APK in phone AAB | ✅ Standalone `MyHealth-Android-Watch-vX.apk` (route a) | optional — can also bundle into the phone AAB (§2) |
| 🔌 Backend | Tarball / Docker image | ✅ `MyHealth-Server-vX.tgz` | none |
| 🌐 Web | Static zip / Pages deploy | ✅ `MyHealth-Web-vX.zip` + Pages | none |

---

## 1. Apple Watch — must be embedded in the iPhone `.ipa`

### What Apple requires
> A watchOS app is shipped as a **watch2-app extension target inside the iOS
> app's bundle**. App Store Connect accepts ONE `.ipa` per app, and that `.ipa`
> contains the iPhone executable + all its embedded extensions including the
> watchOS app. Users install the iPhone app, and the Watch app appears
> automatically on the paired Apple Watch.
> [HIG · Distribute watchOS](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

### What this repo does today
Two **separate** xcodegen projects:
```
ios/project.yml      → produces FitFusion.app          (iPhone app)
watch/project.yml    → produces HealthAppWatch.app     (watch app, NOT bundled)
```

Two separate `.app` files. **Apple App Store will reject this.**

### The fix path
Migrate the watchOS target into `ios/project.yml` as an embedded
`watch2-app` extension. Concretely:

1. Move `watch/HealthAppWatch/Sources/**` → `ios/HealthAppWatch/`
2. Edit `ios/project.yml`:
   ```yaml
   targets:
     FitFusion:
       …
       dependencies:
         - target: HealthAppWatch          # ← add
     HealthAppWatch:
       type: application.watchapp2         # ← watch2-app
       platform: watchOS
       deploymentTarget: "10.0"
       sources:
         - path: HealthAppWatch
       info:
         path: HealthAppWatch/Info.plist
       settings:
         base:
           PRODUCT_BUNDLE_IDENTIFIER: com.fitfusion.ios.watchkitapp
           WATCHOS_DEPLOYMENT_TARGET: "10.0"
           SDKROOT: watchos
   ```
3. Delete the separate `watch/project.yml` (or leave it for stand-alone QA)
4. Run `xcodegen generate` inside `ios/`
5. Now `xcodebuild archive` for the iOS scheme produces a single `.ipa` with
   the watch app inside

### Effort
~30 min on a Mac with Xcode. **Not done yet** — left as a follow-up because it
needs hands-on Xcode validation that's hard to do from CI alone.

### Until that's done
The current `MyHealth-Apple-Watch-vX-Simulator.app.zip` artefact is **only
useful for**:
- Manually running the watch app in Apple Watch Simulator for QA / screenshots
- Code-review of the watch UI without firing up Xcode

It is **NOT** a binary you can submit to the App Store.

---

## 2. Wear OS — two valid distribution shapes (we use shape A)

### Shape A — Standalone Wear OS app  *(what we do today)*
- Wear app has its own package (`com.myhealth.wear`)
- Listed as a separate app in Play Console (form factor: Wear OS)
- Phone APK + Wear APK are completely independent — a user can install one
  without the other
- ✅ This is what the current repo produces (`MyHealth-Android-Watch-vX.apk`)

### Shape B — Bundled wearable APK inside the phone AAB
- Phone APK contains the Wear APK as a wearable feature module
- Single Play Console listing, single AAB upload
- Wear Play Store auto-installs the wear feature when the phone app is
  installed on a paired watch
- Modern Play AAB feature delivery makes this nicer than the old Wear 2.x
  bundling

### Which one to use?
- **Shape A** is best for **standalone Wear OS apps** that don't need a phone
  (the user can install MyHealth on their Pixel Watch without owning the
  phone app). MyHealth fits this — the watch tabs work even without the
  phone app installed.
- **Shape B** is required if your watch app **only makes sense paired with a
  specific phone app**. Not our case.

**No code change needed.** Both wear and phone apps already declare
`com.google.android.wearable.standalone = true` in their manifests, which is
the required marker for Shape A.

### To list both in Play Console
1. In Play Console, create **two separate apps**:
   - `com.myhealth.app` (Phone)
   - `com.myhealth.wear` (Wear OS)
2. Mark the Wear OS app with the "Wear OS" form factor in Store presence
3. Upload both AABs / APKs through the existing release pipeline (the
   `r0adkll/upload-google-play` step takes whatever AAB it finds — extend the
   matrix to also upload the wear APK to its own listing)

---

## 3. Updated `release.yml` matrix — what we *should* aim for

| Asset | Today | Target after watch-embedding fix |
|---|---|---|
| `MyHealth-iOS-iPhone-vX.ipa` | ⚠️ unsigned `.app.zip` only | ✅ signed `.ipa` containing iPhone + watch (uploaded to TestFlight by `publish-testflight`) |
| `MyHealth-Apple-Watch-vX-*.app.zip` | ✅ standalone QA artefact | 🟡 keep for QA but it's no longer the store-shippable binary |
| `MyHealth-Android-Phone-vX.aab` | ✅ ready for Play | ✅ same |
| `MyHealth-Android-Watch-vX.apk` | ✅ ready for Play (separate listing) | ✅ same |
| `MyHealth-Server-vX.tgz` | ✅ | ✅ |
| `MyHealth-Web-vX.zip` | ✅ | ✅ |

---

## 4. Action items before App Store submission

- [ ] Migrate `watch/` into `ios/project.yml` as a `watch2-app` target (§1)
- [ ] Verify the resulting `.ipa` contains both `FitFusion.app` and
      `HealthAppWatch.app` via `unzip -l MyHealth-iOS-iPhone-vX.ipa`
- [ ] Set `APP_STORE_CONNECT_API_KEY_*` secrets so `publish-testflight`
      uploads the combined `.ipa` automatically

## 5. Action items before Play Store submission

- [ ] Pay $25 + create two Play Console apps (`com.myhealth.app`,
      `com.myhealth.wear`) — only the **first** AAB upload needs to be
      manual; everything after that flows through CI
- [ ] Set `PLAY_STORE_SERVICE_ACCOUNT_JSON` + `PLAY_STORE_PACKAGE_NAME`
      secrets — the existing `publish-play-store` job auto-uploads the phone
      AAB
- [ ] Optionally add a second `publish-play-store` job step for the wear APK
      using a second package name secret

---

## 6. Honest summary

| Question | Answer |
|---|---|
| Can I download today's `v1.0.1` binaries and use them? | ✅ Yes — Android phone APK / AAB + Wear APK are real installable binaries |
| Can I submit `v1.0.1` to App Store today? | ❌ No — the Apple Watch app is a separate `.app`, not embedded |
| Can I submit `v1.0.1` to Play Store today? | ✅ Yes for the phone AAB; ✅ Yes for Wear APK as a separate listing |
| Will future tags ship a complete iOS `.ipa` with the watch inside? | ⏳ Only after the §1 migration + `APP_STORE_CONNECT_API_KEY_*` secrets |

The repo is **fully production-ready for Google Play** today (modulo the $25
fee + the one-time manual first upload). It's **80% production-ready for
Apple App Store** — only the watch-embedding restructure is missing.
