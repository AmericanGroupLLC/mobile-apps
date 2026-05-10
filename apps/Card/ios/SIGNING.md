# Card — iOS code-signing

For local builds, `CODE_SIGNING_ALLOWED=NO` is enough — every CI job uses it
and so does `./scripts/run-ios-sim.sh`.

For TestFlight / App Store builds, Fastlane Match handles certificates and
provisioning profiles. See [`../RELEASING.md`](../RELEASING.md) §5 for the
required GitHub Secrets:

- `APP_STORE_CONNECT_API_KEY_P8_BASE64`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APPLE_TEAM_ID`
- `MATCH_PASSWORD`
- `MATCH_GIT_URL`

`release.yml` builds the Matchfile inline at run time, so nothing tied to a
specific Apple account ever lives in this repo. When the secrets are not set,
the TestFlight job no-ops with a `::notice::` annotation.

## App Group

`com.apple.security.application-groups → group.com.americangroupllc.card` is
declared in:

- `Card/Resources/Card.entitlements`
- `CardShareExtension/CardShareExtension.entitlements`

Enable the App Group in Apple Developer → Identifiers before any Share
Extension submission, otherwise the extension cannot write to the shared
`CardStore` and the share path will silently fail.
