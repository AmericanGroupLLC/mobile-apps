# Pocket — Releasing

> Cut a release in 2 lines. Everything else is automated.

## TL;DR

```bash
./scripts/bump-version.sh 1.0.0
git commit -am "chore(release): v1.0.0" && git tag v1.0.0 && git push origin main v1.0.0
```

GitHub Actions then runs [`release.yml`](./.github/workflows/release.yml):
1. Gates on every test in [`pre-release-tests.yml`](./.github/workflows/pre-release-tests.yml).
2. Builds in parallel: Android phone APK + AAB, Wear APK, iOS sim `.app.zip`,
   watchOS sim `.app.zip`, marketing site zip.
3. Creates a **GitHub Release** at the tag with auto-generated changelog and all artefacts attached.
4. Optionally uploads the AAB to Google Play (gated on `PLAY_STORE_SERVICE_ACCOUNT_JSON`).
5. Optionally builds a signed `.ipa` and uploads to TestFlight (gated on `APP_STORE_CONNECT_API_KEY_P8_BASE64`).

`-rc` / `-beta` / `-alpha` tags publish as **prereleases** and route to the matching Play track.

## Tag conventions

| Tag | GitHub Release | Play track | TestFlight |
|---|---|---|---|
| `v1.0.0` | stable | production | yes |
| `v1.0.0-rc1` | prerelease | beta | yes |
| `v1.0.0-beta1` | prerelease | beta | yes |
| `v1.0.0-alpha1` | prerelease | alpha | yes |
| `v1.0.0-internal1` | prerelease | internal | yes |

## What `bump-version.sh` touches

- `android/app/build.gradle.kts` — `versionName`
- `android/wear/build.gradle.kts` — `versionName`
- `ios/Pocket/Resources/Info.plist` — `CFBundleShortVersionString`
- `watchos/PocketWatch/Resources/Info.plist` — `CFBundleShortVersionString`
- `watchos/PocketComplication/Info.plist` — `CFBundleShortVersionString`

## One-time setup per remote target

### GitHub Releases (always works)

No secrets needed. Tag pushes always create a Release with all artefacts.

### Google Play

Create a service account JSON at <https://play.google.com/console> → Setup → API access.
Add these repo secrets:

- `PLAY_STORE_SERVICE_ACCOUNT_JSON` (the entire JSON contents)
- `PLAY_STORE_PACKAGE_NAME` = `com.americangroupllc.pocket`
- `ANDROID_KEYSTORE_BASE64` = `base64 -i your-upload.jks`
- `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`

The `whatsnew` blurb served to the Play Console is `distribution/whatsnew/whatsnew-en-US/whatsnew.txt`.

### Apple TestFlight

Create an App Store Connect API key (App Store Connect → Users and Access → Keys).
Add these repo secrets:

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8_BASE64` = `base64 -i AuthKey_XXXX.p8`
- `APPLE_TEAM_ID`
- `MATCH_GIT_URL`, `MATCH_PASSWORD` (only if you use [Fastlane Match](https://docs.fastlane.tools/actions/match/))

If you don't use Match, the workflow falls back to automatic signing — works for a single-developer Apple ID.

### Sentry / PostHog (optional)

- `SENTRY_DSN_IOS`, `SENTRY_DSN_ANDROID`, `SENTRY_DSN_WEAR`
- `POSTHOG_API_KEY_IOS`, `POSTHOG_API_KEY_ANDROID`, `POSTHOG_HOST`

When unset, the BuildConfig fields land as empty strings and the SDKs no-op safely. See [`OBSERVABILITY.md`](./OBSERVABILITY.md) and [`SENTRY.md`](./SENTRY.md).

## Local dry-run

```bash
./scripts/release-dry-run.sh v1.0.0
```

Builds every artefact into `distribution/staging-v1.0.0/` without pushing anything.

## Rollback

GitHub Releases are created with `draft: false` but you can always edit / delete the Release in the Releases UI. Play Store rollouts can be halted from the Play Console; TestFlight builds can be expired from App Store Connect.

## Changelog

`release.yml` auto-generates the GitHub Release notes from `git log` between the previous tag and the current tag. For human-readable highlights served to the Play Store on each release, edit `distribution/whatsnew/whatsnew-en-US/whatsnew.txt` before tagging.
