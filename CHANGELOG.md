# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - v0.1.0

Initial public release. See distribution/whatsnew/v0.1.0/en-US.txt for the user-facing summary.

## Commit history (since repo creation)

- 2719d61 Phase 0: repo skeleton, 11 docs, marketing site, 6 workflows (Srikanth Patchava, 2026-05-06)
- 5dbba75 Phase 1: shared/BuddyCore Swift Package (models, keystone helpers, transports, tests) (Srikanth Patchava, 2026-05-06)
- 222f68c Phase 2: Android :core (Kotlin/JVM mirror of BuddyCore + JUnit tests) (Srikanth Patchava, 2026-05-06)
- 9bbe1c4 Phase 3: iOS phone shell (Home/Lobby/Settings/Rivalries + ConnectivityService + Plist + tests) (Srikanth Patchava, 2026-05-06)
- 8cb15d9 Phase 4: iOS Royal Chess (ChessViewModel/BoardView/Screen) (Srikanth Patchava, 2026-05-06)
- 9e8fe65 Phase 5: iOS Dice Kingdom (LudoViewModel/BoardView/Screen) (Srikanth Patchava, 2026-05-06)
- 26ae5c8 Phase 6: iOS Mini Racer (RacerViewModel/CanvasView/Screen + BLE rejection) (Srikanth Patchava, 2026-05-06)
- 161a21c Phase 7: Android :app shell (manifest, Compose Home/Lobby/Rivalries/Settings, Hilt) (Srikanth Patchava, 2026-05-06)
- 5d10dc2 Phase 8: Android connectivity adapters (NsdDiscovery, WifiTcpTransport, BleTransport, ConnectivityViewModel) (Srikanth Patchava, 2026-05-06)
- 5b1f917 Phase 9: Android Chess + Ludo + Racer Compose screens (Srikanth Patchava, 2026-05-06)
- d0b7b9a fix(core): repair Kotlin syntax error in GameSession.kt (Srikanth Patchava, 2026-05-06)
- 4cd785f fix(app): add material AAR for XML Theme.Material3 parent (Srikanth Patchava, 2026-05-06)
- eff8534 fix(app): annotate startHosting return type as Unit to satisfy override (Srikanth Patchava, 2026-05-06)
- 13d9d39 fix(app): rename SettingsViewModel mutators to avoid JVM setter clash (Srikanth Patchava, 2026-05-06)
- 7ec2333 fix(app): wire Hilt instrumented test infra (runner + deps) for smoke test (Srikanth Patchava, 2026-05-06)
- 0b2459a fix(app): make Settings scrollable; smoke test uses assertExists for off-screen items (Srikanth Patchava, 2026-05-06)
- b74343f fix(app): use onAllNodesWithText().assertCountEquals(1) for off-screen smoke checks (Srikanth Patchava, 2026-05-06)
- db50b6b docs(distribution): add SUBMISSION-CHECKLIST.md (Phase 3 production readiness) (Srikanth Patchava, 2026-05-06)

