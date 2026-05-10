# Drift — RELEASING

## 1. Branch + tag scheme

- `main` is always shippable.
- Every release lives behind a tag: `vMAJOR.MINOR.PATCH` (e.g. `v1.0.0`).
- Pre-release tags use suffixes: `v1.1.0-rc1`, `v1.1.0-beta3`, `v1.1.0-alpha1`,
  or `v1.1.0-internal4`. The release workflow auto-flags these as
  pre-releases on GitHub.

## 2. Cutting a release

1. **Bump version** on every platform in one commit:
   ```sh
   ./scripts/bump-version.sh 1.1.0
   ```
   This updates:
   - `ios/project.yml` `MARKETING_VERSION`
   - `watchos/project.yml` `MARKETING_VERSION`
   - `android/app/build.gradle.kts` `versionName` + `versionCode`
   - `android/wear/build.gradle.kts` `versionName` + `versionCode`
2. **Update what's-new copy** in `distribution/whatsnew/whatsnew-en-US/whatsnew.txt`.
3. **Run pre-release tests locally** (or trigger the workflow):
   ```sh
   gh workflow run pre-release-tests.yml --ref main
   ```
4. **Tag + push**:
   ```sh
   git tag v1.1.0
   git push origin v1.1.0
   ```
5. The `release.yml` workflow runs the pre-release-tests gate, builds the
   four binaries (iOS .app, watchOS .app, Android phone APK + AAB,
   Wear APK), creates a GitHub Release with auto-generated notes, and
   *if the right secrets are set*, uploads to Google Play and TestFlight.

## 3. What is uploaded where

| Artefact | Destination | Trigger |
|---|---|---|
| `Drift-iOS-iPhone-vX.Y.Z-Simulator.app.zip` | GitHub Release | always |
| `Drift-Apple-Watch-vX.Y.Z-Simulator.app.zip` | GitHub Release | always |
| `Drift-Android-Phone-vX.Y.Z.apk` / `.aab` | GitHub Release | always |
| `Drift-Android-Watch-vX.Y.Z.apk` | GitHub Release | always |
| `Drift-Web-vX.Y.Z.zip` (marketing site bundle) | GitHub Release | always |
| Signed `.ipa` → TestFlight | Apple App Store Connect | requires `APP_STORE_CONNECT_API_KEY_P8_BASE64` |
| `.aab` → Google Play | Play Console | requires `PLAY_STORE_SERVICE_ACCOUNT_JSON` |

## 4. Required GitHub Secrets

The workflow degrades gracefully when these are absent (the optional
upload steps are gated by `if [ -z "$X" ]`).

### iOS / watchOS

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8_BASE64` — base64 of the .p8 file
- `APPLE_TEAM_ID`
- `MATCH_PASSWORD`, `MATCH_GIT_URL` — Fastlane Match storage
- `SENTRY_DSN_IOS`, `POSTHOG_API_KEY_IOS`, `POSTHOG_HOST`

### Android / Wear

- `ANDROID_KEYSTORE_BASE64` — base64 of `upload.jks`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `PLAY_STORE_SERVICE_ACCOUNT_JSON`
- `PLAY_STORE_PACKAGE_NAME` — usually `com.americangroupllc.drift`
- `SENTRY_DSN_ANDROID`, `SENTRY_DSN_WEAR`, `POSTHOG_API_KEY_ANDROID`

### Backend

- `SUPABASE_PROJECT_REF` — for `backend.yml` deploy steps.
- `SUPABASE_DB_PASSWORD` — for `supabase db push`.
- `LLM_API_KEY` — set as a Supabase **secret** via `supabase secrets set`,
  not as a GitHub secret.
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` — Supabase
  secrets used by `verify-selfie/index.ts`.

## 5. Release dry-run

```sh
./scripts/release-dry-run.sh v1.1.0
```

Mirrors the CI build steps locally. Useful to catch packaging issues before
tagging.

## 6. Rolling back

If a release is critically broken:

```sh
gh release edit vX.Y.Z --draft   # un-publish from GitHub Release
# Play Store + App Store rollbacks are manual via their consoles.
```

Tag a follow-up patch release immediately rather than retracting (consumers
who already pulled the .apk should be migrated forward).
