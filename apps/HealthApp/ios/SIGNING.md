# Signing & provisioning

Both `ios/project.yml` and `watch/project.yml` ship with `DEVELOPMENT_TEAM: ""`
on purpose so the repo doesn't carry a personal Apple Developer team ID.

## Three-line setup

1. Find your team ID:
   - Apple Developer portal → **Membership** → "Team ID" (10-char string).
   - Or run `xcrun security find-identity -p codesigning -v` and pull the team
     from the cert subject.
2. Replace `DEVELOPMENT_TEAM: ""` in **both** `ios/project.yml` and
   `watch/project.yml`.
3. Re-run `xcodegen generate` in both directories.

## Capabilities checklist

When you first open the project in Xcode after generating it, Xcode may need
to provision the following capabilities. These match the entitlements files
and `project.yml` already in the repo:

### iOS app (`com.fitfusion.ios`)
- HealthKit (read + background delivery)
- iCloud → CloudKit container `iCloud.com.fitfusion`
- App Groups → `group.com.fitfusion`
- Sign in with Apple (optional, not required for current auth flow)
- Background Modes → location, processing, workout-processing
- Push notifications → only if you enable Live Activity remote updates (off by default)

### iOS extensions
- `MyHealthLiveActivity` (`com.fitfusion.ios.liveactivity`) — App Group only
- `MyHealthWidget` (`com.fitfusion.ios.widget`) — App Group only
- `MyHealthMessages` (`com.fitfusion.ios.messages`) — App Group only

### Watch app (`com.fitfusion.watch`)
- HealthKit
- iCloud (same container)
- App Groups (same group)
- Siri

### Watch complication (`com.fitfusion.watch.complication`)
- App Group only

## Bundle ID note

Display names changed to **MyHealth** during the rebrand, but bundle IDs and
the CloudKit container ID (`iCloud.com.fitfusion`) intentionally stayed
`com.fitfusion.*` so already-synced CloudKit data survives the rebrand. Don't
rename them unless you want to start fresh.

## Free Apple Developer account?

A free Apple ID can sign builds for **personal device testing only** (7-day
provisioning, single device). All capabilities except Push Notifications work
with a free account. For TestFlight / App Store you need the $99/year paid
Developer Program.
