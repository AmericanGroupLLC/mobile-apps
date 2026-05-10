# Card — RELEASING

This file describes the tag → release flow. Routine version bumps go through
`./scripts/bump-version.sh`; the actual release is tag-driven by GitHub Actions
(`release.yml`).

---

## 1. Pre-release sanity

```bash
./scripts/test-all.sh                 # every available platform
./scripts/release-dry-run.sh v0.1.0   # build the artefacts that release.yml will build
```

If either fails, fix and re-run. Do not tag with red CI.

The `pre-release-tests.yml` workflow is also runnable manually from the GitHub
Actions UI — it is the same gate that `release.yml` uses, so a green manual run
predicts a green tag run.

---

## 2. Bump every manifest

```bash
./scripts/bump-version.sh 0.1.0
git diff                              # review
git commit -am 'chore(release): v0.1.0'
git push origin main
```

The script edits:

- `android/app/build.gradle.kts`        — `versionName = "0.1.0"`
- `android/wear/build.gradle.kts`       — `versionName = "0.1.0"`
- `ios/Card/Resources/Info.plist`       — `CFBundleShortVersionString = 0.1.0`
- `watchos/CardWatch/Resources/Info.plist`     — `CFBundleShortVersionString = 0.1.0`
- `watchos/CardComplication/Info.plist` — `CFBundleShortVersionString = 0.1.0`

It does **not** bump `CFBundleVersion` / `versionCode` — bump those manually
when you need a new App Store / Play upload of the same `versionName`.

---

## 3. Tag and let CI do the rest

```bash
git tag v0.1.0
git push origin v0.1.0
```

`release.yml` will:

1. Run the full `pre-release-tests.yml` matrix (gate).
2. Build Android phone APK + AAB and Wear APK.
3. Build iOS `.app` (iPhone simulator binary).
4. Build watchOS `.app` (watchOS simulator binary).
5. Zip the marketing site.
6. Create a GitHub Release with all artefacts attached and auto-generated
   release notes.
7. **If `PLAY_STORE_SERVICE_ACCOUNT_JSON` is set**, upload the AAB to the right
   Play track (internal / alpha / beta / production based on the tag suffix).
8. **If `APP_STORE_CONNECT_API_KEY_P8_BASE64` is set**, build a signed `.ipa`
   via Fastlane Match and upload to TestFlight.

When the optional secrets are absent, those jobs gracefully skip with a
`::notice::` annotation — the GitHub Release itself still ships.

---

## 4. Tag suffix → release-channel mapping

| Tag form         | GitHub Release | Play track     | TestFlight             |
|------------------|----------------|----------------|------------------------|
| `v0.1.0-internal`| draft + prerelease | `internal`  | (manual upload only)   |
| `v0.1.0-alpha.1` | prerelease     | `alpha`        | TestFlight internal    |
| `v0.1.0-beta.2`  | prerelease     | `beta`         | TestFlight external    |
| `v0.1.0-rc.1`    | prerelease     | `beta`         | TestFlight external    |
| `v0.1.0`         | release        | `production`   | TestFlight → App Store |

---

## 5. Required GitHub Secrets (release.yml)

All optional — `release.yml` no-ops cleanly when missing.

### Android

- `ANDROID_KEYSTORE_BASE64`           — base64 of `upload.jks`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `PLAY_STORE_SERVICE_ACCOUNT_JSON`   — full Play Console service-account JSON
- `PLAY_STORE_PACKAGE_NAME`           — `com.americangroupllc.card`

### iOS

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8_BASE64` — base64 of the `.p8` file
- `APPLE_TEAM_ID`
- `MATCH_PASSWORD`                     — Fastlane Match repo encryption password
- `MATCH_GIT_URL`                      — git URL of the Match certificate repo

### Both

- `SENTRY_DSN_IOS`, `SENTRY_DSN_ANDROID`, `SENTRY_DSN_WEAR`
- `POSTHOG_API_KEY_IOS`, `POSTHOG_API_KEY_ANDROID`, `POSTHOG_HOST`

When unset, the SDKs no-op; nothing crashes; the binary still ships.

---

## 6. Hot-fix flow

```bash
# Branch from the tag
git switch -c hotfix/v0.1.1 v0.1.0

# Cherry-pick or commit the fix
git cherry-pick <fix-commit>

# Bump + tag
./scripts/bump-version.sh 0.1.1
git commit -am 'chore(release): v0.1.1'
git tag v0.1.1
git push origin hotfix/v0.1.1 v0.1.1
```

The same `release.yml` runs.

---

## 7. Rollback

GitHub Releases can be marked as `prerelease: true` after the fact — that hides
the release from the "latest" badge without deleting the artefacts. For Play
Store, halt the rollout from the Play Console; for TestFlight, expire the
build. **Do not delete tags** — they are the only audit trail of what shipped.
