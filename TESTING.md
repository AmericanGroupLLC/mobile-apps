# TESTING.md

## Shape of the test suite

| Layer | Where | Framework | Runs in CI |
|---|---|---|---|
| Apple shared logic | `shared/BuddyCore/Tests/BuddyCoreTests/` | XCTest | `ci.yml`, `ios.yml`, `pre-release-tests.yml` |
| iOS UI smoke | `ios/BuddyPlayUITests/` | XCUITest | `ios.yml`, `pre-release-tests.yml` |
| Android shared logic | `android/core/src/test/...` | JUnit 4 + Truth | `ci.yml`, `pre-release-tests.yml` |
| Android app unit | `android/app/src/test/...` | JUnit 4 + Truth | `ci.yml`, `pre-release-tests.yml` |
| Android UI smoke | `android/app/src/androidTest/...` | Compose UI testing | `android.yml`, `pre-release-tests.yml` |

## The keystone tests (these are the project's safety net)

Every keystone helper has an XCTest **and** a JUnit twin. They test the same
contract on both runtimes so behaviour cannot drift.

| Helper | XCTest | JUnit | What it asserts |
|---|---|---|---|
| `HostElection` | `HostElectionTests` | `HostElectionKtTest` | Deterministic; symmetric (both peers compute the same host); UUID lex order tiebreak; platform tiebreak. |
| `WireCodec` | `WireCodecTests` | `WireCodecKtTest` | Round-trip `encode→decode==input` for every game's input + state. Rejects unknown schema versions. |
| `ChessRules` | `ChessRulesTests` | `ChessRulesKtTest` | Scholar's Mate detected. En passant captured. Castling blocked through check. Promotion to queen. ~30 cases. |
| `LudoRules` | `LudoRulesTests` | `LudoRulesKtTest` | 6 grants extra turn. Capture sends opponent home. Only-6-leaves-base. Win on all-4-home. |
| `RacerPhysics` | `RacerPhysicsTests` | `RacerPhysicsKtTest` | Deterministic given fixed seed + fixed `dt`. Wall collision reflects velocity. Idle decay. |
| `LocalRivalryStore` | `LocalRivalryStoreTests` | `LocalRivalryStoreKtTest` | Write→read→increment yields right tallies. Corrupt JSON falls back to empty. |

These six files MUST compile + test green on both Swift and Kotlin before
any UI work for the corresponding game ships.

## Running locally

```sh
# Everything (auto-skips suites the host can't run)
./scripts/test-all.sh

# Just BuddyCore
cd shared/BuddyCore && swift test
# or with coverage on iPhone Sim
xcodebuild test -scheme BuddyCore-Package \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -enableCodeCoverage YES CODE_SIGNING_ALLOWED=NO

# Just Android :core
cd android && ./gradlew :core:test

# Just Android :app unit
cd android && ./gradlew :app:testDebugUnitTest

# Compose UI smoke (requires emulator + adb)
cd android && ./gradlew :app:connectedDebugAndroidTest

# Just XCUITest smoke
cd ios && xcodegen generate
xcodebuild test -project BuddyPlay.xcodeproj -scheme BuddyPlay \
  -sdk iphonesimulator -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

## Manual cross-platform / cross-transport checklist (pre-release)

| Scenario | Steps | Pass criterion |
|---|---|---|
| iOS host ↔ Android guest, Chess, Wi-Fi | Both phones same router. iOS hosts Chess, Android joins. Make first move. | First move syncs in < 200 ms. |
| iOS host ↔ Android guest, Chess, BLE | Disable Wi-Fi on both phones. iOS hosts. Android joins via BLE. | First move syncs in < 1 s. |
| Hotspot fallback | Turn off router. iOS enables hotspot. Android joins it. | Chess game runs to completion. |
| Mini Racer rejects BLE | Disable Wi-Fi. iOS picks Mini Racer. | UI shows "Mini Racer needs Wi-Fi or Hotspot" and BLE is disabled. |
| Local rivalry tally | Play Chess → quit → play Chess again. | Rivalries screen shows 2 games against the same opponent. |
| Erase rivalries | Settings → Erase. | Rivalries screen empty state. |
| Reset device ID | Settings → Reset device ID → re-pair with friend. | Friend sees a *new* opponent (rivalries restart). |

## Coverage targets

- BuddyCore (Swift): 80%+ on the keystone helpers.
- :core (Kotlin): 80%+ on the keystone helpers.
- App layers: best-effort; these are mostly thin glue.

Coverage is uploaded by CI to Codecov; the report is informational, not a
blocker.
