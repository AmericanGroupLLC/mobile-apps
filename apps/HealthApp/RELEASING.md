# MyHealth — Releasing & Distribution

This document covers **how to cut a release**, **what GitHub Actions does
automatically**, and **whether direct Play Store / App Store deployment is
possible** (spoiler: yes for Play, conditional for App Store).

---

## 1. TL;DR — Cut a release

```bash
# 1. Pick a version number that follows semver
git tag v1.2.0
git push origin v1.2.0
```

That's it. The `release.yml` workflow under `.github/workflows/` will
automatically:

1. Build the **Android phone APK** (`MyHealth-v1.2.0.apk`)
2. Build the **Wear OS APK** (`MyHealth-Wear-v1.2.0.apk`)
3. Build the **server tarball** (`myhealth-server-v1.2.0.tgz`)
4. Build the **marketing-site zip** (`myhealth-web-v1.2.0.zip`)
5. Upload **iOS XCArchive** + **iOS .ipa** when run on a macOS runner
   (skipped on Linux runners — no Xcode)
6. Create a **GitHub Release** at `v1.2.0` with:
   - Title: "MyHealth v1.2.0"
   - Body: auto-generated changelog from commit messages since the previous tag
   - All built artefacts attached as downloads
7. Apply tag labels (`release`, `android`, `ios`, `wear`) for filtering

If the tag uses **`v*-rc*`** (e.g. `v1.2.0-rc1`) the release is marked **pre-release**.

---

## 2. Workflow files

| File | Trigger | What it does |
|---|---|---|
| `.github/workflows/ci.yml` | every push + PR | Backend tests · Android build · Compose lint · iOS Swift Package tests (macOS runner) |
| `.github/workflows/release.yml` | push of `v*` tag | Build all binaries, attach to GitHub Release, optionally upload to Play Store |
| `.github/workflows/android.yml` | push to main + PR | Android-specific: lint, unit, instrumented (when emulator runner available) |
| `.github/workflows/ios.yml` | push to main + PR | iOS Swift Package tests + watch tests (macOS runner) |
| `.github/workflows/backend.yml` | push touching `server/**` | Backend Jest + smoke run |
| `.github/workflows/marketing.yml` | push touching `index.html`/`styles.css`/`script.js` | Validates HTML/CSS, optionally publishes to GitHub Pages |

All workflows are committed under `.github/workflows/`.

---

## 3. Direct Google Play Store upload — yes, fully automated

Yes — **the release workflow can publish directly to Google Play** without any
manual step in the Play Console. The mechanism:

1. **Create a Google Play Service Account** in
   [Play Console → Setup → API access](https://play.google.com/console/api-access).
2. Grant it permission to **Release manager** for the `com.myhealth.app` package.
3. Download the resulting JSON key.
4. Add it as a GitHub secret:
   - `PLAY_STORE_SERVICE_ACCOUNT_JSON` — raw contents of the JSON file
   - `PLAY_STORE_PACKAGE_NAME` — e.g. `com.myhealth.app`
5. The release workflow uses
   [`r0adkll/upload-google-play@v1`](https://github.com/r0adkll/upload-google-play)
   to push the AAB to a track of your choice.

In `release.yml` the publish step is **gated by an env flag** so you can land
the workflow before Play Console setup:

```yaml
- name: Publish to Google Play (internal track)
  if: env.PLAY_STORE_SERVICE_ACCOUNT_JSON != ''
  uses: r0adkll/upload-google-play@v1
  with:
    serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT_JSON }}
    packageName: com.myhealth.app
    releaseFiles: android/app/build/outputs/bundle/release/app-release.aab
    track: internal     # internal / alpha / beta / production
    status: completed
    inAppUpdatePriority: 2
    whatsNewDirectory: distribution/whatsnew
```

Tracks supported: `internal`, `alpha`, `beta`, `production`. Most teams promote
through them: `internal` → `alpha` → `beta` → `production`.

For the first publish, you must **manually upload an APK once** to Play
Console so it can register the package name. After that, every subsequent
release flows through CI.

### What's-new release notes

Drop short release notes in `distribution/whatsnew/whatsnewen-US/whatsnew.txt`
(and other locales). The workflow reads `whatsnewDirectory` and uploads them
to the matching Play Console fields.

---

## 4. Apple App Store — partial automation

Apple is **stricter** than Google, but still scriptable:

- **TestFlight upload** — fully automatable via `fastlane pilot` or
  `xcrun altool`. Requires an App-Specific Password or App Store Connect API
  key (a `.p8` file). See `ios/SIGNING.md` for setup.
- **Production release** — App Review remains a **manual + opaque** human
  review step. Once approved, you can press "Release Now" via App Store
  Connect API or trigger the release manually.

The `release.yml` workflow gates the iOS upload behind macOS runners and the
presence of `APP_STORE_CONNECT_API_KEY` secret — same pattern as Play.

---

## 5. Wear OS distribution

Wear OS apps ship through the **same Play Console package**. The release
workflow builds `:wear:assembleRelease` alongside `:app:assembleRelease` and
the **Play Store automatically associates the Wear APK** with the phone APK
(both share `com.myhealth.app` family of bundle IDs and the workflow zips
them into a single AAB).

For standalone Wear OS distribution, set `com.google.android.wearable.standalone = true`
in the Wear manifest (already done) and submit through the **Wear OS** track
in Play Console.

---

## 6. Versioning

Use **SemVer**:

| Tag pattern | Meaning | Play track default |
|---|---|---|
| `v1.0.0` | Stable | `production` (gated — flip the env flag) |
| `v1.1.0` | Minor (new features, backwards-compat) | `beta` |
| `v1.0.1` | Patch (bug fixes) | `production` |
| `v1.2.0-rc1` | Release candidate | `alpha` |
| `v1.2.0-beta1` | Public beta | `beta` |
| `v1.2.0-internal1` | Internal QA | `internal` |

Bump these matching values **in lockstep** before tagging:

| File | Field |
|---|---|
| `android/app/build.gradle.kts` | `versionName` + `versionCode` |
| `android/wear/build.gradle.kts` | `versionName` + `versionCode` |
| `ios/FitFusion/Info.plist` | `CFBundleShortVersionString` + `CFBundleVersion` |
| `watch/HealthAppWatch/Info.plist` | same |
| `mobile/app.json` | `expo.version` + `android.versionCode` + `ios.buildNumber` |
| `server/package.json` | `version` |

Or run the helper:

```bash
./scripts/bump-version.sh 1.2.0
```

---

## 7. Distribution checklist

Before pushing the tag:

- [ ] Bumped versions in all manifests (script above)
- [ ] Updated `RELEASE_NOTES.md` with the highlight reel
- [ ] Updated `distribution/whatsnew/whatsnew-en-US/whatsnew.txt` (≤ 500 chars per Play)
- [ ] Ran `./scripts/test-all.sh` locally — all green
- [ ] Squashed the diff and merged to `main`
- [ ] Signed the Android AAB (configured via `keystore.properties` — never committed)
- [ ] Confirmed iOS provisioning profile is current
- [ ] Tagged with `git tag vX.Y.Z && git push origin vX.Y.Z`

After CI completes:

- [ ] Verify GitHub Release contains all expected artefacts
- [ ] Verify Play Console shows the new bundle on the chosen track
- [ ] Smoke test the downloaded APK on a real Android device
- [ ] Promote to next track in Play Console when ready

---

## 8. First-time secrets setup

In repo Settings → Secrets and variables → Actions → New repository secret,
add:

| Secret | What it is |
|---|---|
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Play Service Account JSON (raw) |
| `PLAY_STORE_PACKAGE_NAME` | e.g. `com.myhealth.app` |
| `ANDROID_KEYSTORE_BASE64` | Base64 of the upload keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias inside the keystore |
| `ANDROID_KEY_PASSWORD` | Per-key password |
| `APP_STORE_CONNECT_API_KEY_ID` | (iOS) From App Store Connect |
| `APP_STORE_CONNECT_API_ISSUER_ID` | (iOS) |
| `APP_STORE_CONNECT_API_KEY_P8_BASE64` | (iOS) Base64 of the .p8 file |
| `APPLE_TEAM_ID` | (iOS) e.g. ABCD123456 |

Without these, the workflow still runs but **skips the upload steps** —
artefacts are still attached to the GitHub Release for manual download.

---

## 9. Local pre-release dry run

```bash
./scripts/release-dry-run.sh v1.2.0
```

This builds every artefact locally without pushing anything — useful to catch
issues before the tag is in.
