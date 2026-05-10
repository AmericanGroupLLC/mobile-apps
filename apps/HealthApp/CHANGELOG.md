# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - v1.4.0

Initial public release. See distribution/whatsnew/v1.4.0/en-US.txt for the user-facing summary.

## Commit history (since repo creation)

- 20650c0 Initial commit (Srikanth Patchava, 2026-05-01)
- 6468f05 feat: full MyHealth platform ΓÇö iOS + watchOS + Android + Wear OS + Expo + backend (Srikanth Patchava, 2026-05-01)
- 7061743 fix(ci): trigger workflows on master, fix release.yml secret-gating, drop missing npm cache (Srikanth Patchava, 2026-05-01)
- e154d1a fix(ci): macOS in Package.swift, Jest setupFiles key, Pages enablement, Android adaptive icon (Srikanth Patchava, 2026-05-01)
- fbd9d5e fix(ci): repair 47 Swift escapes, mobile/package.json JSON, marketing Pages tolerance (Srikanth Patchava, 2026-05-01)
- 3e750d6 fix(swift): combine surrogate pair into single \u{1F680} scalar in BiologicalAgeEngine (Srikanth Patchava, 2026-05-01)
- 04e7888 fix(swift): gate BackgroundTasks usage with os(iOS) instead of canImport (BGTaskScheduler is iOS-only) (Srikanth Patchava, 2026-05-01)
- b69b28f ci: test FitFusionCore on iOS Simulator (UIKit + WatchConnectivity preclude macOS host) (Srikanth Patchava, 2026-05-01)
- 0558200 Enhance with vibrant colors, animated gradients, full SEO + CI/CD deploy (Srikanth Patchava, 2026-05-03)
- 1aefe2c Add Google Analytics GA4 tracking (G-Y0CDD6QJ9J) (Srikanth Patchava, 2026-05-03)
- 4085759 Add sitemap.xml and robots.txt for SEO crawling (Srikanth Patchava, 2026-05-03)
- 9db9f20 fix(android): drop self-referential Modifier.clickable / Modifier.clip extensions (Srikanth Patchava, 2026-05-04)
- 1346552 fix(wear): add Guava + use DimensionBuilders.expand() in ReadinessTileService (Srikanth Patchava, 2026-05-04)
- 008849c feat(release): TestFlight auto-upload + PRODUCTION.md gap audit (Srikanth Patchava, 2026-05-04)
- 7706fce fix(release): publish-github-release tolerates partial build failures + always includes source archives (Srikanth Patchava, 2026-05-04)
- e12b36b fix(release): produce real binaries for every platform; drop source-archive fallback (Srikanth Patchava, 2026-05-04)
- 0a16c30 feat(ci): combined Pre-Release Tests gate + platform-clear binary names (Srikanth Patchava, 2026-05-04)
- e9c31fa docs(stores): STORE-PACKAGING.md ΓÇö watch-app bundling reality + remaining gaps (Srikanth Patchava, 2026-05-04)
- 613d1e0 feat: Sentry crash reporting wired across iOS+watchOS, Android phone+wear, Expo, backend (Srikanth Patchava, 2026-05-04)
- 4c29287 feat(observability): PostHog product analytics + OBSERVABILITY.md (Sentry + PostHog + Grafana matrix) (Srikanth Patchava, 2026-05-04)
- 5155221 ci(release): pass Sentry + PostHog secrets through to build steps (Srikanth Patchava, 2026-05-04)
- 4fb5c8b fix(ci): regenerate server lockfile with @sentry/node + posthog-node; mark wear-ui-tests informational (Srikanth Patchava, 2026-05-04)
- 723c4f4 fix(ci): emulator-based UI tests informational; release flatten only ships binaries (Srikanth Patchava, 2026-05-04)
- 0c883c7 feat(health): condition-aware workout filtering + GIF demos + diet suggestions (Srikanth Patchava, 2026-05-04)
- 88c81af docs(stores): correct xcodegen syntax for Apple Watch embed migration (Srikanth Patchava, 2026-05-04)
- aa19f23 fix(release): unmask iOS+Android phone build errors; drop xcodegen capabilities/INFOPLIST_KEY blocks (Srikanth Patchava, 2026-05-04)
- 6f8ce0d fix(release): drop GCC_PREPROCESSOR_DEFINITIONS injection that broke xcodebuild arg parsing (Srikanth Patchava, 2026-05-04)
- e2c6423 fix(ci): xcode-select to latest Xcode in every macOS job (objectVersion 77 fix) (Srikanth Patchava, 2026-05-04)
- 9cc5d88 fix(release): repair iOS/watchOS build failures (Srikanth Patchava, 2026-05-06)
- 2d2da82 chore(release): bump to 1.3.3 (Srikanth Patchava, 2026-05-06)
- 5652e6f fix(release): build iOS/watchOS sim binaries in Debug to match pre-release-tests (Srikanth Patchava, 2026-05-06)
- 2fd2195 docs: add MIT LICENSE and PRIVACY.md (Phase 2 production readiness) (Srikanth Patchava, 2026-05-06)
- 08a3d0d docs(distribution): add SUBMISSION-CHECKLIST.md (Phase 3 production readiness) (Srikanth Patchava, 2026-05-06)

