# Pocket — Testing

> Two layers: **automated** (CI + local `scripts/test-all.sh`) and **manual** (real-device sanity checklists per feature). Real OS-scheduled alarms can only be fully verified on a real phone.

## Sanity-test matrix per platform

### iPhone

| Feature | Steps | Expected |
|---|---|---|
| Clock | Open app → Clock tab | Time updates every second; AM/PM follows Settings → Privacy 12/24h toggle |
| World Clock | Tap +, search "Tokyo" | Tokyo appears with current local time + offset |
| Alarm | Add alarm 1 min out, lock device | Notification fires with Snooze 9 + Stop actions |
| Alarm reboot | Add alarm 5 min out, reboot device | Notification still fires (re-registered on launch) |
| Stopwatch | Start, lap 3×, kill app, reopen | Laps preserved |
| Timer | Start 30 sec timer, lock device | Notification at 0 with sound |
| Bedtime | Set wake = 7 am, sleep = 11 pm | Wind-down notification at 10:30 pm |
| Settings | Toggle 24-hour | Clock + alarms re-render in 24-hour |
| Settings | Toggle Sentry opt-in | Restart app — crash test does/doesn't reach Sentry |
| Settings | Erase all data | Alarms, presets, world clocks all reset |

### Apple Watch

| Feature | Steps | Expected |
|---|---|---|
| Tabs | Swipe Clock → World → Stopwatch → Timer → Bedtime → Settings | Each loads w/o crash |
| Complication | Long-press face → Edit → add Pocket Next Alarm | Shows next alarm time / `--:--` if none |
| Alarm | Schedule from phone, surface on watch | Notification arrives |

### Android phone

| Feature | Steps | Expected |
|---|---|---|
| Onboarding | First launch | 3 pages: Welcome → Notification permission → Done |
| Alarm | Add alarm 1 min out, lock device | High-importance notification fires with Snooze 9 + Stop |
| Alarm reboot | Add alarm 5 min out, reboot device | Fires (BootReceiver re-registers) |
| Snooze | Tap Snooze on a fired alarm | Re-fires 9 min later |
| Notification permission | Revoke `POST_NOTIFICATIONS` | Settings shows red banner; alarm-fire path no-ops gracefully |
| Settings | Toggle theme / 24-hour / Sentry / PostHog | Persisted via DataStore across restart |
| Erase | Settings → Erase all data | Room cleared; alarms cancelled |

### Wear OS

| Feature | Steps | Expected |
|---|---|---|
| Pages | Swipe Clock → World → Stopwatch → Timer → Bedtime → Settings | Each loads w/o crash |
| Tile | Swipe right from face → Pocket tile | Shows next alarm + current time |
| Complication | Long-press face → Edit → add Pocket Next Alarm | Shows next alarm time |

## Automated test matrix (CI)

| Layer | Job | Where |
|---|---|---|
| Swift Package unit | `xcodebuild test -scheme PocketCore-Package` on iPhone 15 sim | `ios.yml` `swift-tests` + `ci.yml` `ios` |
| iOS sim build | `xcodebuild build … iphonesimulator` | `ios.yml` `ios-build` + `ci.yml` `ios` |
| iOS XCUITest | `xcodebuild test` for `Pocket` scheme | `ios.yml` `ios-ui-tests` + `pre-release-tests.yml` |
| watchOS sim build | `xcodebuild build … watchsimulator` | `ios.yml` `watch-build` + `ci.yml` `ios` |
| Android `:core` unit | `./gradlew :core:testDebugUnitTest` | `ci.yml` `android` + `pre-release-tests.yml` |
| Android `:app` unit | `./gradlew :app:testDebugUnitTest` | `ci.yml` `android` + `pre-release-tests.yml` |
| Android `:wear` unit | `./gradlew :wear:testDebugUnitTest` | `ci.yml` `android` + `pre-release-tests.yml` |
| Android Compose UI smoke | `:app:connectedDebugAndroidTest` on KVM emulator | `android.yml` (instrumented) |
| Wear Compose UI smoke | `:wear:connectedDebugAndroidTest` on Wear emulator | `pre-release-tests.yml` (informational, flaky) |
| Marketing lint | `htmlhint` + `stylelint` (best-effort) | `ci.yml` `marketing` |

## Real-device-only checklist

Before tagging any release, run these on at least one real iPhone and one real Android phone (the simulator/emulator can't fully reproduce notification scheduling under doze + reboot):

1. **iPhone**: schedule alarm 5 min out → background app → lock device → notification fires with Snooze 9 / Stop. Tap Snooze → notification re-fires +9 min.
2. **iPhone**: schedule alarm 5 min out → reboot device → notification still fires.
3. **Android**: schedule alarm 5 min out → background → lock → fires with Snooze / Stop. Snooze re-fires +9 min.
4. **Android**: same but reboot before fire-time → still fires (BootReceiver).
5. **Android**: revoke `POST_NOTIFICATIONS` → Settings UI shows the missing-permission banner; no crash on alarm-fire path.

## Known caveats

- **watchOS standalone alarms** are limited compared to iOS — by design we
  rely on the phone-companion bridge for cross-device alarm visibility.
- **Wear OS doesn't run on-device alarms.** That's intentional — phone alarms
  surface on the watch via the standard companion notification bridge.
- **Linux KVM Android emulators on GitHub Actions** are notoriously flaky.
  The `android-phone-ui-tests` and `wear-ui-tests` jobs are
  `continue-on-error: true` — the unit tests are the real release gate.

## Run every test on your machine

```bash
./scripts/test-all.sh
```

Skips suites that need tooling you don't have. See [`QUICKSTART.md`](./QUICKSTART.md) for what each suite covers.
