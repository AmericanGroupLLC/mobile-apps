# RELEASING.md

BuddyPlay's release pipeline is `release.yml`, gated on `pre-release-tests.yml`.
Cutting a release is one tag push.

## 0. Pre-flight

- All keystone tests green locally: `./scripts/test-all.sh`
- Two-device manual smoke checklist passed (see `TESTING.md`).
- Marketing site preview reads correctly: `python3 -m http.server`.

## 1. Bump version

```sh
./scripts/bump-version.sh 1.2.0
git diff
```

This updates the iOS `Info.plist` and Android `:app:build.gradle.kts`
versions to the new semver.

## 2. Commit + tag

```sh
git commit -am 'chore(release): v1.2.0'
git tag v1.2.0
git push origin main v1.2.0
```

Pushing the tag triggers `release.yml`. Pre-release tests must pass before
any binary is built or uploaded.

## 3. What `release.yml` does

| Job | Purpose | Gated on |
|---|---|---|
| `pre-release-tests` | Run every test suite (iOS unit + UI, Android unit + UI). | always |
| `build-android` | Build APK + AAB. Sign if `ANDROID_KEYSTORE_BASE64` secret set. | pre-release-tests |
| `build-ios` | Build unsigned `BuddyPlay.app` for iPhone Sim. | pre-release-tests |
| `build-web` | Zip the marketing site. | pre-release-tests |
| `publish-github-release` | Create the GitHub Release with all artefacts. | all build-* |
| `publish-play-store` | Upload AAB to Google Play. | secret `PLAY_STORE_SERVICE_ACCOUNT_JSON` |
| `publish-testflight` | Build signed `.ipa` + push to TestFlight. | secret `APP_STORE_CONNECT_API_KEY_P8_BASE64` |

## 4. Required secrets

All optional — workflow no-ops gracefully when unset.

| Secret | Purpose |
|---|---|
| `CODECOV_TOKEN` | Coverage upload (private repos). |
| `ANDROID_KEYSTORE_BASE64` | Sign Play Store AAB. |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Sign Play Store AAB. |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Upload AAB to Play. |
| `PLAY_STORE_PACKAGE_NAME` | `com.americangroupllc.buddyplay` |
| `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_P8_BASE64` | TestFlight upload. |
| `APPLE_TEAM_ID` | Code signing. |
| `MATCH_PASSWORD`, `MATCH_GIT_URL` | Fastlane Match (provisioning profile sync). |

## 5. Pre-release tags

Use `-rc.N`, `-beta.N`, `-alpha.N` suffixes:

```sh
git tag v1.2.0-rc.1
```

These are flagged as pre-releases on GitHub and routed to the `beta` track
on Google Play.

## 6. Hotfix

```sh
./scripts/bump-version.sh 1.2.1
git commit -am 'fix(chess): castling-through-check regression'
git tag v1.2.1
git push origin main v1.2.1
```

## 7. Local dry-run

Before tagging, validate the build will succeed:

```sh
./scripts/release-dry-run.sh v1.2.0
```

Stages all artefacts in `distribution/staging-v1.2.0/`. No tag is pushed.
