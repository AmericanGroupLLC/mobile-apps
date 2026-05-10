# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - v0.1.0

Initial public release. See distribution/whatsnew/v0.1.0/en-US.txt for the user-facing summary.

## Commit history (since repo creation)

- 3c1bf29 Initial commit (Srikanth Patchava, 2026-05-05)
- 2dde228 feat(repo): Phase 0 -- repo skeleton, 12 docs, marketing site, 7 workflows, Drift palette (Srikanth Patchava, 2026-05-06)
- 6f5a0c3 feat(backend): Phase 1 -- Supabase config, schema, RLS helpers, Realtime, 3 Edge Functions, Deno tests, seed (Srikanth Patchava, 2026-05-06)
- 4d3bb92 feat(shared): Phase 2 -- DriftCore Swift Package: models, LayerScorer, ToneClassifier, LocationFuzzer, ReplyPromptBuilder, SupabaseClient, observability stubs, full XCTest coverage (Srikanth Patchava, 2026-05-06)
- e32f59d feat(android-core): Phase 3 -- :core models, domain helpers, Ktor SupabaseClient, JUnit/Truth tests mirrored case-for-case (Srikanth Patchava, 2026-05-06)
- f976fe7 feat(ios): Phases 4-8 -- DriftApp, onboarding, Discover/Wave/Matches, Chat+ReplySuggestions, Profile, Settings, Safety, services, NotificationService extension, tests (Srikanth Patchava, 2026-05-06)
- 351e5b5 feat(watchos): Phase 9 -- DriftWatchApp, MatchesListView, QuickReplyView, MatchesComplication (WidgetKit) (Srikanth Patchava, 2026-05-06)
- 23b53f1 feat(android-app): Phase 10 -- DriftApplication, MainActivity, RootNav, Discover/Matches/Chat/Profile/Settings Compose screens, AppModule (Hilt), FCM stub, Compose smoke test (Srikanth Patchava, 2026-05-06)
- 32cd0cf feat(wear): Phase 11 -- DriftWear MainActivity, MatchTileService, QuickReplyComplicationService (Guava pinned for tile Futures) (Srikanth Patchava, 2026-05-06)
- 637e7fd fix(core): SupabaseClient compile errors -- use URLBuilder.parameters.append in rawGet, expose client via @PublishedApi for inline postJson (Srikanth Patchava, 2026-05-06)
- ff573a7 fix(core-tests): align LayerScorer low-score threshold with documented weights and skip Companion field in LocationFuzzer reflection (Srikanth Patchava, 2026-05-06)
- e0c8eef fix(android-app): expose ktor-client-core via api so :app can construct SupabaseClient; mark RootNav local item() composable (Srikanth Patchava, 2026-05-06)
- a194f5a fix(wear): use Wear Compose Material (not material3) for MainActivity (Srikanth Patchava, 2026-05-06)
- 3718419 fix(wear): use ComponentActivity so setContent's @Composable lambda is in scope (Srikanth Patchava, 2026-05-06)
- 25be188 docs(distribution): add SUBMISSION-CHECKLIST.md (Phase 3 production readiness) (Srikanth Patchava, 2026-05-06)

