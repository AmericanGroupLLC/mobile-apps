# SIGNING.md

## Local dev

`xcodegen generate` produces a project that signs with whatever team
your Xcode session is logged into. For a clean unsigned build (Sim
only):

```sh
xcodebuild -project OfflineAIBuddy.xcodeproj \
  -scheme OfflineAIBuddy \
  -sdk iphonesimulator \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Release builds (CI)

`release.yml` uses [Fastlane Match](https://docs.fastlane.tools/actions/match/)
to sync the App Store distribution profile + cert. Required secrets:

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8_BASE64`
- `APPLE_TEAM_ID`
- `MATCH_PASSWORD`
- `MATCH_GIT_URL`

When unset, `release.yml` skips the TestFlight upload and only stages
an unsigned simulator binary as a release artifact.

## Bundle IDs

Both the main app and the keyboard extension MUST be added to the App
Identifier list in App Store Connect, and both MUST share the App Group
`group.com.americangroupllc.offlineaibuddy`. Match's `Matchfile` lists
both identifiers (see `release.yml`).

## Provisioning gotchas

- The keyboard extension MUST have its own provisioning profile (not
  inherited from the main app).
- Both profiles MUST include the App Group entitlement.
- Set `RequestsOpenAccess = false` in the keyboard's `Info.plist` —
  without "open access", the keyboard cannot reach the network at all,
  which simplifies App Review (we don't need to justify network
  permissions).
