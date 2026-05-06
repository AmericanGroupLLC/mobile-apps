# Pocket — Store Packaging

> Reality check on how the four binaries actually map onto the two app stores.

## 1. Apple Watch bundling reality check

The `release.yml` pipeline produces **two separate Apple .app bundles**:

- `Pocket-iOS-iPhone-<version>-Simulator.app.zip`
- `Pocket-Apple-Watch-<version>-Simulator.app.zip`

Both are **iPhone Simulator / watchOS Simulator binaries** — useful for QA
distribution and reviewer testing. Neither is a store-shippable binary on
its own.

Apple's App Store **only ships one .ipa per app listing**. To get the watch app onto a real Apple Watch via the App Store, the watchOS app must be bundled inside the iOS app's `.ipa` as a **watch-app extension target**.

Two paths:

### Path A — keep them as standalone projects (current setup)

- ✅ Each project (`ios/`, `watchos/`) is independent. Each has its own XcodeGen spec and can be built/tested in isolation.
- ❌ Cannot ship to the App Store directly. Watch app is sideload / TestFlight-only.
- ✅ Simulator and developer-mode device installs work today.

### Path B — embed `PocketWatch` as a watch2-app target inside `Pocket.xcodeproj`

- Edit `ios/project.yml` to add a second target of type `application.watchapp2`
  with the watchOS sources.
- Add the watch target's bundle ID as an `embed` of the iOS target.
- The `release.yml` `build-ios` job's `xcodebuild archive` then produces a
  single `.ipa` containing both binaries, ready for `xcodebuild -exportArchive`
  → `Apple-Actions/upload-testflight-build@v1`.

Path B is the migration plan for `v1.0.0`. Until then, the watch app ships as a separate sim binary on the GitHub Release page and via TestFlight (via the standalone bundle ID).

## 2. iOS bundle IDs

| Target | Bundle ID |
|---|---|
| iPhone app | `com.americangroupllc.pocket` |
| Apple Watch app (when embedded under Path B) | `com.americangroupllc.pocket.watchkitapp` |
| Apple Watch app (current standalone Path A) | `com.americangroupllc.pocket` (separate provisioning profile) |
| WidgetKit complication | `com.americangroupllc.pocket.complication` |

## 3. Android packaging

Android is simpler — phone and wear are **two separate Play listings, both backed by the same multi-module Gradle project**:

| Listing | App ID | Module | Track |
|---|---|---|---|
| Pocket (phone) | `com.americangroupllc.pocket` | `:app` | production |
| Pocket Wear | `com.americangroupllc.pocketwear` | `:wear` | production |

The `r0adkll/upload-google-play@v1` step in `release.yml` only uploads the
phone AAB by default (gated on `PLAY_STORE_SERVICE_ACCOUNT_JSON`). To also
publish the Wear app, add a sibling job that points `releaseFiles` at
`android/wear/build/outputs/bundle/release/wear-release.aab` and bumps
`PLAY_STORE_PACKAGE_NAME` to `com.americangroupllc.pocketwear`.

## 4. Marketing site

`marketing.yml` deploys `index.html` + `styles.css` + `script.js` + `robots.txt` + `sitemap.xml` to GitHub Pages. The site doubles as the publicly-hosted privacy policy URL when you publish `PRIVACY.md` rendered to HTML alongside it.

## 5. App icons

The asset-set scaffolding ships in:

- `ios/Pocket/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `android/app/src/main/res/mipmap-anydpi-v26/` (adaptive icon)

Both are **placeholder slots**. Drop a real 1024×1024 PNG into the iOS asset
set and per-density PNGs into `android/app/src/main/res/mipmap-{mdpi,hdpi,
xhdpi,xxhdpi,xxxhdpi}/` before tagging `v1.0.0`. See [`PRODUCTION.md`](./PRODUCTION.md) Week 1 polish.

## 6. Localizations

English only at v1. Adding more is a per-platform `Localizable.strings` /
`values-{xx}/strings.xml` exercise — no code changes needed thanks to all UI
strings being centralised.
