# DESIGN — Pocket

This document describes how Pocket is structured, the per-tool sensor stack,
the shared libraries, and how each platform borrows what it needs.

---

## Repo map

```
Pocket/
├── README.md                         Top-level introduction + 5-tool matrix.
├── DESIGN.md                         (this file)
├── QUICKSTART.md                     Fastest path to a running build per platform.
├── TESTING.md                        Sanity-test matrix + real-device-only checklist.
├── RELEASING.md                      Tagging, store-bound builds, fastlane.
├── PRODUCTION.md                     Gap audit (signing, certs, App Store assets…).
├── OBSERVABILITY.md                  Sentry + PostHog wrapper contract.
├── SENTRY.md                         Real Sentry install steps.
├── STORE-PACKAGING.md                App Store + Play Store metadata + privacy labels.
├── PRIVACY.md                        What data each tool touches + why.
├── TOOLS-FEATURES.md                 Per-tool feature catalogue + matrix.
│
├── distribution/whatsnew/...         What's-new copy (Play / TestFlight).
├── docs/                             (reserved — long-form per-tool guides)
│
├── index.html · styles.css · script.js · robots.txt · sitemap.xml
│                                     Marketing site (GitHub Pages).
│
├── .github/workflows/                ci · ios · android · marketing ·
│                                     pre-release-tests · release.
├── scripts/                          test-all · bump-version · release-dry-run ·
│                                     run-ios-sim · run-android-emulator ·
│                                     run-wear-emulator.
│
├── shared/PocketCore/                Swift Package. iOS + watchOS share this.
│   ├── Package.swift
│   ├── Sources/PocketCore/
│   │   ├── Clock/                    Models · AlarmStore · TimezoneCatalog ·
│   │   │                             BedtimeEngine.
│   │   ├── Calculator/               CalculatorEngine · CalculatorState.
│   │   ├── Compass/                  HeadingMath (pure math, no CoreLocation).
│   │   ├── Level/                    LevelMath (pure math, no CoreMotion).
│   │   └── Observability/            AnalyticsService · CrashReportingService
│   │                                 (canImport-gated stubs).
│   └── Tests/PocketCoreTests/        Mirrors Sources/ one-for-one.
│
├── ios/                              SwiftUI iPhone app (XcodeGen).
│   ├── project.yml
│   ├── Pocket/
│   │   ├── App/                      PocketApp · RootView.
│   │   ├── Views/
│   │   │   ├── Onboarding/           4-page Welcome → Notification → Camera+Loc → Done.
│   │   │   ├── Tools/                ToolsLauncherView (5-card grid).
│   │   │   ├── Clock/                ClockView · WorldClockView · AlarmListView ·
│   │   │   │                         AlarmEditView · StopwatchView · TimerView ·
│   │   │   │                         BedtimeView.
│   │   │   ├── Calculator/           CalculatorView (basic + scientific landscape).
│   │   │   ├── Measure/              MeasureView · MeasureARViewController (ARKit) ·
│   │   │   │                         MeasureRulerView (fallback).
│   │   │   ├── Compass/              CompassView (analog face + lat/lon panel).
│   │   │   ├── Level/                LevelView (bullseye + bubble).
│   │   │   ├── MainTabView.swift     Five primary destinations.
│   │   │   └── Settings/             SettingsView (units, heading ref, opt-ins…).
│   │   ├── Services/                 AlarmService · HeadingService · AttitudeService ·
│   │   │                             AppDelegate.
│   │   └── Resources/                Info.plist · Pocket.entitlements ·
│   │                                 Assets.xcassets · LaunchScreen.storyboard.
│   ├── PocketTests/                  Unit tests for view-model glue.
│   ├── PocketUITests/                XCUITest smoke through every tool.
│   ├── README.md · SIGNING.md
│
├── watchos/                          SwiftUI Apple Watch (XcodeGen).
│   ├── project.yml
│   ├── PocketWatch/                  4 tools (skip Measure).
│   ├── PocketComplication/           WidgetKit complication bundle.
│   └── README.md
│
└── android/                          Multi-module Gradle.
    ├── settings.gradle.kts           rootProject.name = "Pocket".
    ├── build.gradle.kts              Root plugins.
    ├── core/                         :core — pure-Kotlin domain layer (no Android deps).
    │   ├── build.gradle.kts
    │   └── src/main/java/com/americangroupllc/pocket/core/
    │       ├── clock/                Models · AlarmRepository · TimezoneCatalog · Bedtime.
    │       ├── calculator/           CalculatorEngine.
    │       ├── compass/              HeadingMath.
    │       ├── level/                LevelMath.
    │       └── obs/                  AnalyticsService · CrashReportingService.
    ├── app/                          :app — Compose phone app, Hilt, Room, ARCore.
    │   ├── build.gradle.kts
    │   └── src/main/
    │       ├── AndroidManifest.xml   CAMERA + ACCESS_FINE_LOCATION + AR feature.
    │       └── java/com/americangroupllc/pocket/
    │           ├── tools/            ToolsLauncher.
    │           ├── clock/ calculator/ measure/ compass/ level/ settings/
    │           ├── alarm/            AlarmService · AlarmReceiver · BootReceiver.
    │           ├── data/             Room DAO + DB.
    │           └── di/               Hilt modules.
    └── wear/                         :wear — Wear Compose, Tile, Complication.
        ├── build.gradle.kts
        └── src/main/java/com/americangroupllc/pocketwear/
            ├── clock/ calculator/ compass/ level/ settings/
            ├── tile/                 NextAlarmTileService.
            └── complication/         NextAlarmComplicationService.
```

---

## 5-tool catalogue (sensor stack per platform)

| Tool | Dep on iOS | Dep on watchOS | Dep on Android | Dep on Wear OS |
|---|---|---|---|---|
| Clock | UNUserNotificationCenter | UNUserNotificationCenter | AlarmManager + WorkManager | (no on-device alarms — phone bridge) |
| Calculator | pure Swift | pure Swift | pure Kotlin | pure Kotlin |
| Measure | ARKit + AVFoundation (camera) | — | ARCore + arsceneview + CameraX | — |
| Compass | CoreLocation (heading + lat/lon) | CoreLocation (heading only) | SensorManager.TYPE_ROTATION_VECTOR + LocationManager | SensorManager.TYPE_ROTATION_VECTOR (heading only) |
| Level | CoreMotion (CMMotionManager) | CoreMotion | SensorManager.TYPE_GRAVITY | SensorManager.TYPE_GRAVITY |

The pure-logic helpers (`CalculatorEngine`, `HeadingMath`, `LevelMath`) live in
`PocketCore` / `:core` so the same algorithms drive every platform and the
same tests cover both Apple and Android sides.

---

## Layered design

1. **Domain layer** (`PocketCore` Swift Package + `:core` Kotlin module) holds
   the pure-logic units — no UI, no platform sensors. Same algorithms on
   Apple + Android. Same test cases on both sides.
2. **Service layer** (per-platform) wraps the OS sensors / capability APIs
   (`HeadingService`, `AttitudeService`, `AlarmService`) and turns them into
   `@Published` / `StateFlow` streams the UI binds to.
3. **UI layer** is platform-idiomatic: SwiftUI on Apple, Jetpack Compose on
   Android. Each tool is its own folder.
4. **Composition root** wires services into views via SwiftUI environment
   (Apple) or Hilt (Android).

---

## Why Apple Watch + Wear OS skip Measure

ARKit / ARCore both require a back-facing camera and a powerful enough GPU
for real-time SLAM. Watches have neither. The companion phone is always
within Bluetooth range — Measure is the right fit for the phone tier only.

---

## Why combined permissions in onboarding

Asking for camera + location + notifications upfront would normally feel
intrusive, but Pocket's onboarding splits the asks into 3 distinct pages so
users can deny any one without losing the others. Each tool also re-asks
contextually if it discovers its permission is missing.
