# iOS — Offline AI Buddy

XcodeGen-generated. The source of truth is `project.yml`. Always
re-run `xcodegen generate` after editing `project.yml` or the file
layout.

## Targets

| Target | Bundle ID | Notes |
|---|---|---|
| `OfflineAIBuddy` | `com.americangroupllc.offlineaibuddy` | Main iPhone app. |
| `OfflineAIBuddyKeyboard` | `com.americangroupllc.offlineaibuddy.keyboard` | Keyboard Extension. App Group entitlement on both targets. |
| `OfflineAIBuddyTests` | — | XCTest unit tests. |
| `OfflineAIBuddyUITests` | — | XCUITest smoke. |

## App Group

Both targets carry the entitlement
`group.com.americangroupllc.offlineaibuddy`. The keyboard reads/writes
two files in the shared container — `keyboard.request.json` and
`keyboard.reply.json` — and posts/listens for two Darwin notifications
documented in `KEYBOARD.md`.

## SPM dependencies

- `BuddyAICore` (local at `../shared/BuddyAICore`).
- `RevenueCat` — added at runtime via `canImport(RevenueCat)`-gated
  `RevenueCatEntitlementService`. Not declared as a hard dependency in
  v1; `EntitlementBootstrap` falls back to `NoopEntitlementService`
  when the SDK isn't linked.
- `Google-Mobile-Ads-SDK` — same gating pattern via `canImport(GoogleMobileAds)`.

## Local run

```sh
brew install xcodegen
./scripts/run-ios-sim.sh
```

## Stub backend in dev

`OfflineAIBuddyApp` instantiates `LlamaRunner(backend: StubLlamaBackend())`
on launch. The real `LlamaCppBackend` is wired up alongside the
`vendor/llama.cpp` Swift bindings — that integration lives behind a
build-config flag because it depends on the C source being present.
