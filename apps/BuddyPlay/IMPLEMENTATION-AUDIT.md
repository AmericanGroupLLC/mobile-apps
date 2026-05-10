# BuddyPlay — Implementation Audit (Round-4 Phase-7a)

**Date:** 2026-05-08
**Auditor:** automated repo sweep
**Repo root:** `Z:\home\spatchava\AmericanGroupLLC\BuddyPlay`

## Purpose

This audit reconciles the v1 feature inventory in
[`BUDDYPLAY-FEATURES.md`](BUDDYPLAY-FEATURES.md) (supplemented by `README.md`
and `DESIGN.md`) against what is actually implemented on disk in the iOS,
Android, and shared `BuddyCore` source trees. The goal is to surface false
advertising risk, missing features, and intentional stubs ahead of a v1.0
store submission.

## Severity legend

| Severity | Meaning |
|----------|---------|
| **P0** | False advertising / store-rejection risk — feature claimed prominently but completely missing |
| **P1** | Claimed feature missing or non-functional in production code path |
| **P2** | Rough edges / polish — feature partially implemented |
| **P3** | Intentional stub or safe fallback — documented and acceptable for v1 |

---

## 1. Promised features → implementation citations

Each row is one feature claimed in `BUDDYPLAY-FEATURES.md`. Citations use
`file:line` form. "✅" = implemented on that platform; **GAP** rows include a
severity classification.

### Connectivity

| # | Feature | Android impl | iOS impl | Status |
|---|---------|--------------|----------|--------|
| 1 | Local Wi-Fi via NSD/Bonjour `_buddyplay._tcp` + length-prefixed TCP framing | `android/app/src/main/java/com/americangroupllc/buddyplay/connectivity/WifiTcpTransport.kt:29` + `NsdDiscovery.kt:19` + `core/.../domain/WireCodec.kt:68` (`frame`/`unframe`) | `shared/BuddyCore/Sources/BuddyCore/Connectivity/WifiTransport.swift:9` (`NWListener`/`NWBrowser` Bonjour) + `WireCodec.swift` (`frame`) | ✅ both platforms |
| 2 | Mobile Hotspot via same Wi-Fi path once both peers join | `core/.../connectivity/HotspotAdvisor.kt:10` (instructional helper — both platforms route Hotspot through the same Wi-Fi/NSD path) | `shared/BuddyCore/Sources/BuddyCore/Connectivity/HotspotAdvisor.swift` (mirrored) | ✅ — implementation is the same Wi-Fi transport once peers share an L2 segment |
| 3 | BLE GATT fallback on service `0xBP01` (turn-based only) | `android/app/.../connectivity/BleTransport.kt:21` — service UUID + char UUIDs declared; **all transport methods are empty bodies** (lines 34-56) | `shared/BuddyCore/.../BleTransport.swift:15` — service UUID declared; all delegate plumbing is `#if canImport(CoreBluetooth)` placeholders (lines 29-65) | **GAP — P1** (scaffold only; the BLE-only failover path will not actually transfer frames) |
| 4 | Auto failover ladder (Wi-Fi → Hotspot → BLE) | `android/core/.../connectivity/ConnectivityBridge.kt:41-65` (`host()` tries Wi-Fi first, falls through to BLE on AUTO) | `shared/BuddyCore/.../ConnectivityBridge.swift` (mirrored API per `RootView`/`HostLobbyScreen` callers) | ✅ orchestration exists; downstream BLE leg is gap #3 |
| 5 | User-overridable transport choice (auto / Wi-Fi-only / BLE-only) | `core/.../ConnectivityBridge.kt:25` `Preference` enum; `data/SettingsRepo.kt:36` persists; `settings/SettingsScreen.kt:49-61` UI | `ios/BuddyPlay/Features/Settings/SettingsScreen.swift:18-24` Picker | ✅ both platforms |
| 6 | 4-character pairing code (`BUDD-7Q2K`) | `android/app/.../lobby/HostLobbyScreen.kt:32-36` (`makePairingCode`) + `lobby/PairingCodeView.kt` | `ios/BuddyPlay/Features/Lobby/HostLobbyScreen.swift:72-76` (`makeCode`) + `PairingCodeView.swift` | ✅ both platforms |
| 7 | Cross-platform iOS ↔ Android peers | Wire format + service UUIDs are byte-identical between `core/.../models/WireFrame.kt` and `shared/BuddyCore/.../Models/WireFrame.swift`; same `_buddyplay._tcp` Bonjour name | (same) | ✅ contract-wise; un-testable end-to-end until BLE leg lands |
| 8 | Schema-versioned wire format (`v: 1`); decoder rejects unknown versions | `core/.../models/WireFrame.kt:25` `CURRENT_VERSION = 1`; `core/.../domain/WireCodec.kt:51-53` raises `UnsupportedVersion` | `shared/BuddyCore/.../Models/WireFrame.swift` + `WireCodec.swift` | ✅ both platforms (covered by `WireCodecKtTest.kt`) |
| 9 | Deterministic host election (no round-trip) | `core/.../domain/HostElection.kt:15-30` | `shared/BuddyCore/.../Domain/HostElection.swift` | ✅ both platforms (covered by `HostElectionKtTest.kt`) |

### Games

| # | Feature | Android impl | iOS impl | Status |
|---|---------|--------------|----------|--------|
| 10 | Royal Chess — full move legality (castling, en-passant, promotion, check/mate/stalemate) | `core/.../domain/ChessRules.kt` (rules engine, exercised by `ChessRulesKtTest.kt`); `app/.../games/chess/ChessScreen.kt:14`, `ChessViewModel.kt`, `ChessBoardComposable.kt` | `shared/BuddyCore/.../Domain/ChessRules.swift`; `ios/BuddyPlay/Features/Games/Chess/ChessScreen.swift` | ✅ rules + UI exist on both platforms; **but** Android UI is unreachable from the navigation graph (see gap #17a below) |
| 11 | Dice Kingdom — Ludo-style 4-token race, 2-player, turn-based, BLE-OK | `core/.../domain/LudoRules.kt` (covered by `LudoRulesKtTest.kt`); `app/.../games/ludo/LudoScreen.kt:14` | `shared/BuddyCore/.../Domain/LudoRules.swift`; `ios/BuddyPlay/Features/Games/Ludo/LudoScreen.swift` | ✅ rules + UI exist on both platforms; same Android navigation gap (#17a) |
| 12 | Mini Racer — 30 Hz host tick + client prediction; BLE refused | `core/.../domain/RacerPhysics.kt` (covered by `RacerPhysicsKtTest.kt`); `app/.../games/racer/RacerViewModel.kt:23-28` (BLE refusal) + `RacerScreen.kt:39-50` (refusal UI); `RacerViewModel.kt:36-42` 33 ms ticker (~30 Hz) | `shared/BuddyCore/.../Domain/RacerPhysics.swift`; `ios/BuddyPlay/Features/Games/Racer/RacerScreen.swift` | ✅ physics + BLE-refusal logic; **client-prediction wiring (sent inputs, host reconciliation) is not present in either RacerViewModel** — local input only mutates local state | **Partial — P2** for missing client prediction wiring |

### Home

| # | Feature | Android impl | iOS impl | Status |
|---|---------|--------------|----------|--------|
| 13 | Horizontal card scroller of 3 games | `home/HomeScreen.kt:83-92` (`CardScroller`) | `Features/Home/HomeScreen.swift:52-61` (`cardScroller`) | ✅ both platforms |
| 14 | Persistent floating "Join Nearby Game" button (auto-scans every ~5 s) | `home/HomeScreen.kt:31-38` FAB; **but** auto-scan is not wired — tapping shows a "Phase 8" placeholder dialog (`HomeScreen.kt:68-75`) | `Features/Home/HomeScreen.swift:90-107` FAB → opens `JoinLobbyScreen` which calls `connectivity.scan(...)` (`JoinLobbyScreen.swift:50-52`) | **Android GAP — P1** (FAB exists but does not start scanning); iOS ✅ |
| 15 | Tabs: All / DuoPlay / Party (dimmed) | `home/HomeScreen.kt:41-49`, `LobbyTab` enum (line 78); Party dimmed at line 50-51 + `PartyDimmedCard` (lines 147-161) | `Features/Home/HomeScreen.swift:11-15` enum; party dimmed at lines 30-31 + `partyDimmedCard` (lines 74-88) | ✅ both platforms |
| 16 | "Last played" carousel above the grid | `home/HomeScreen.kt:135-144` (`LastPlayedSection`) — renders an empty-state string only, no actual carousel data binding | `Features/Home/HomeScreen.swift:63-72` (`lastPlayedSection`) — same: empty-state text only | **Partial — P2** on both platforms (label is present but it is a static placeholder, not a carousel) |

### Lobby

| # | Feature | Android impl | iOS impl | Status |
|---|---------|--------------|----------|--------|
| 17 | Host: pick game → advertise on Wi-Fi + BLE simultaneously → show pairing code | Code exists: `lobby/HostLobbyScreen.kt:16-30` + `ConnectivityBridge.kt:41-58` advertises on both rungs in AUTO. **However, `HomeScreen.kt:59-67` does not navigate to `HostLobbyScreen`; it shows an `AlertDialog` with "Phase 7 stub" comment** (line 60). | `Features/Lobby/HostLobbyScreen.swift:6` is reachable via `HomeScreen.swift:43-45 sheet(item: $hostKind)` and calls `connectivity.host(...)` at line 42 | **Android GAP — P1** (host lobby is unreachable from production navigation); iOS ✅ |
| 17a | Android nav wiring (corollary to #17) | `ui/RootNav.kt:30-60` only routes `home`, `rivalries`, `settings` — none of `HostLobbyScreen`, `JoinLobbyScreen`, `ChessScreen`, `LudoScreen`, `RacerScreen` are referenced from the nav graph or from `HomeScreen.kt`. `search_files` confirms zero call sites for `ChessScreen(`, `LudoScreen(`, `RacerScreen(`. | n/a (iOS `RootView.swift` plus `HomeScreen.swift` sheet wiring covers it) | **Android GAP — P0** (Android v1 cannot reach lobby/game screens at all — store-blocking) |
| 18 | Join: live scan list → tap a peer → confirm code → exchange names → start | `lobby/JoinLobbyScreen.kt:13-27` exists but only renders static "Scanning..." text — no `connectivity.scan` wiring, no peer list, no confirm-code sheet. Plus same nav-unreachable gap as #17. | `Features/Lobby/JoinLobbyScreen.swift:13-62` — full flow with hosts list, `ConfirmCodeSheet`, and `connectivity.connect(...)` | **Android GAP — P1** (Android join flow is a placeholder); iOS ✅ |

### Local rivalries

| # | Feature | Android impl | iOS impl | Status |
|---|---------|--------------|----------|--------|
| 19 | Per-opponent W/L/D tally per game | `core/.../models/Rivalry.kt` + `core/.../storage/LocalRivalryStore.kt:38-57` (`record`); UI `app/.../rivalries/RivalriesScreen.kt:50-58` | `shared/BuddyCore/.../Models/Rivalry.swift` + `Storage/LocalRivalryStore.swift`; UI `ios/BuddyPlay/Features/Rivalries/RivalriesScreen.swift` | ✅ both platforms |
| 20 | Keyed by stable opponent UUID + display name | `core/.../models/Rivalry.kt` (`opponentId`, `opponentName`); `LocalRivalryStore.kt:38` `record(opponentId, opponentName, …)` | mirrored | ✅ both platforms |
| 21 | On-disk JSON store (no cloud) | `core/.../storage/LocalRivalryStore.kt:19` (`rivalries.json` in app filesDir) | mirrored Swift store | ✅ both platforms |
| 22 | Settings → Erase all rivalries | `settings/SettingsScreen.kt:80,90-98` (button + confirm dialog) → `LocalRivalryStore.eraseAll()` (`LocalRivalryStore.kt:59-61`) | `Features/Settings/SettingsScreen.swift:55-57,68-73` | ✅ both platforms |
| 23 | Settings → Reset device ID | `settings/SettingsScreen.kt:81,99-107` → `AndroidDeviceIdProvider.kt:28-32` `reset()` | `Features/Settings/SettingsScreen.swift:58-60,74-79` | ✅ both platforms |

### Settings

| # | Feature | Android impl | iOS impl | Status |
|---|---------|--------------|----------|--------|
| 24 | Connectivity preference (auto / Wi-Fi-only / BLE-only) | `settings/SettingsScreen.kt:48-61` | `Features/Settings/SettingsScreen.swift:18-24` | ✅ both platforms |
| 25 | Display name | `settings/SettingsScreen.kt:39-46` | `Features/Settings/SettingsScreen.swift:15-17` | ✅ both platforms |
| 26 | Default game | `settings/SettingsScreen.kt:63-72` | `Features/Settings/SettingsScreen.swift:25-34` | ✅ both platforms |
| 27 | Sound on/off | `settings/SettingsScreen.kt:75` | `Features/Settings/SettingsScreen.swift:36` | ✅ both platforms |
| 28 | Haptics on/off | `settings/SettingsScreen.kt:76` | `Features/Settings/SettingsScreen.swift:37` | ✅ both platforms |
| 29 | Theme: system / light / dark | Persisted in `data/SettingsRepo.kt:25,41,54-55`. **No UI exposure in `settings/SettingsScreen.kt`** (no Theme section / picker present). | `Features/Settings/SettingsScreen.swift:39-48` (Appearance section, Picker) | **Android GAP — P2** (data layer exists but user can't change it); iOS ✅ |
| 30 | Telemetry: nothing in v1 (disclosure label) | `settings/SettingsScreen.kt:78-79` "BuddyPlay does not send any data." | `Features/Settings/SettingsScreen.swift:50-54` "BuddyPlay does not send any data." | ✅ both platforms |

### Telemetry

| # | Feature | Android impl | iOS impl | Status |
|---|---------|--------------|----------|--------|
| 31 | Stub `AnalyticsService` / `CrashReportingService` interfaces — no transports attached | `core/.../observability/AnalyticsService.kt:16` `NoopAnalyticsService`; `CrashReportingService.kt:15` `NoopCrashReportingService`; wired in `di/AppModule.kt:40,43` | `shared/BuddyCore/.../Observability/AnalyticsService.swift` + `CrashReportingService.swift` (mirrored) | ✅ both platforms (intentional v1 noop, P3) |

### Monetisation

| # | Feature | Android impl | iOS impl | Status |
|---|---------|--------------|----------|--------|
| 32 | `PremiumGateService` stub returning `unlocked = true` | **No file matches `Premium*` anywhere in `android/`** — referenced only in `BUDDYPLAY-FEATURES.md:61` and `PRODUCTION.md:57`. | **No file matches `Premium*` anywhere in `ios/` or `shared/`** — same. | **GAP — P1** on both platforms (claimed in feature inventory + PRODUCTION.md but the type does not exist in source) |

---

## 2. Bug / marker list

Repo-wide search across `**/*.{kt,swift,js,ts,tsx}` (excluding `.md`,
`node_modules`, `.git`, build outputs) for the markers `TODO|FIXME|XXX|HACK|stub|placeholder|Phase \d` plus lower-case variants and `Noop`.

| File:line | Marker text | Classification |
|-----------|-------------|----------------|
| `android/app/.../connectivity/NoopBuddyTransport.kt:8` | `"placeholder until Phase 8 lands the real Android WifiTcpTransport + BleTransport"` | **Intentional CI fallback / no-op safe in prod** — `NoopBuddyTransport` has zero call sites; production `AppModule.kt:46-47` wires `WifiTcpTransport` + `BleTransport` (P3). The class is dead code retained for tests; the comment is stale (claims it is the wired transport, but it isn't). |
| `android/app/.../di/AppModule.kt:24` | `"v1 wires noop transports for both rungs — Phase 8 swaps in the real WifiTcpTransport and BleTransport"` | **Stale comment** — the actual provider on lines 46-47 already wires the real transports. P3 (doc-only) but should be cleaned up. |
| `android/app/.../home/HomeScreen.kt:60` | `"// Phase 7 stub: opens a placeholder host lobby. Real lobby in Phase 8."` | **Missing real implementation** — HomeScreen pops an `AlertDialog` instead of navigating to the existing `HostLobbyScreen`. See feature gap #17 / #17a (P0/P1). |
| `android/app/.../home/HomeScreen.kt:64` | `"Connectivity adapters land in Phase 8. The lobby flow + game screens are wired through Phase 9."` | **Missing real implementation** — same root cause as line 60 (P0/P1). |
| `android/app/.../home/HomeScreen.kt:72` | `"Scanning for nearby BuddyPlay phones — connectivity adapters land in Phase 8."` | **Missing real implementation** — Join FAB shows a placeholder dialog. Feature gap #14 (P1). |
| `android/app/.../connectivity/BleTransport.kt:18` | `"Phase 9.x will fill in the delegate plumbing for the BLE-only test scenario."` + `startHosting` / `startScanning` / `connect` / `send` empty bodies (lines 34-56) | **Missing real implementation** — gap #3 (P1). |
| `ios/BuddyPlay/Services/GameSessionService.swift:7` | `"v1 is a thin scaffold — Phase 4-6 will fill in per-game wiring."` | **Missing real implementation** — `start()` only constructs a `GameSession` value, no input pump or `WireCodec` send. Affects feature #12 client-prediction wiring (P2). |
| `shared/BuddyCore/.../Connectivity/BleTransport.swift:11-14` | `"actual CBPeripheralManager / CBCentralManager delegate plumbing is more involved [...] for v1 the lobby can fall back to Wi-Fi"` + empty bodies in `startHosting`/`startScanning`/`connect`/`send` (lines 29-63) | **Missing real implementation** — feature gap #3 (P1). |
| `ios/BuddyPlay/Features/Games/Ludo/LudoBoardView.swift:5` | `"Phase 6+ can replace with a [richer renderer]"` | **Polish only** — board renders progress markers; functional. P3 / cosmetic. |
| `ios/BuddyPlay/Resources/LaunchScreen.storyboard:21` | `<placeholder placeholderIdentifier="IBFirstResponder" …>` | **Intentional Xcode XML boilerplate** — not a code marker. P3. |

---

## 3. Summary counts

- **Promised features inventoried:** 32 (rows #1-#32 above; row #17a is a corollary highlighting the navigation root-cause and is folded into #17 for the count)
- **Implemented on both platforms (✅):** 21
- **iOS-only (Android gap):** 4 (features #14, #17, #18, #29)
- **Both-platform gaps:** 4 (features #3, #12, #16, #32)
- **Net unique gaps:** 8

### Severity tally

| Severity | Count | Items |
|----------|-------|-------|
| **P0** | 1 | Android nav graph never reaches lobby or game screens (#17a — false-advertising risk: app advertises 3 games + Join Nearby + Host but the Android user cannot actually open any of them) |
| **P1** | 5 | BLE GATT plumbing empty on both platforms (#3); Android Join FAB unwired (#14); Android Host flow unwired (#17/#18); Android Join scan unwired (#18); `PremiumGateService` does not exist anywhere in source (#32) |
| **P2** | 3 | Mini Racer client-prediction wiring absent (#12); "Last played" carousel is a static empty-state string on both platforms (#16); Android Theme picker missing in `SettingsScreen.kt` even though `SettingsRepo` persists it (#29) |
| **P3** | 4+ | `NoopBuddyTransport.kt` (dead code, safe), stale comment in `AppModule.kt:24`, Noop telemetry services (#31, expected), `LudoBoardView.swift` polish marker, `LaunchScreen.storyboard` XML placeholder |

### Top recommendations before v1.0 store submission

1. **(P0)** Wire `HostLobbyScreen` / `JoinLobbyScreen` / `ChessScreen` / `LudoScreen` / `RacerScreen` into `android/app/.../ui/RootNav.kt` and replace the two placeholder `AlertDialog`s in `HomeScreen.kt:60-75` with real navigation. Without this, the Android app cannot perform any advertised game flow.
2. **(P1)** Either (a) fill in the empty `BleTransport` bodies on both platforms or (b) remove the BLE bullet from `BUDDYPLAY-FEATURES.md` and the BLE chips on the Home cards, and remove `BLE-only` from the Settings preference, to avoid claiming a feature the app cannot deliver.
3. **(P1)** Either add a `PremiumGateService` type that returns `unlocked = true` (matching the `BUDDYPLAY-FEATURES.md:61` and `PRODUCTION.md:57` claims) or strike both bullets.
4. **(P2)** Add the Theme picker to Android `SettingsScreen.kt` to match the Repo + iOS surface area.
5. **(P3)** Clean up the stale "wires noop transports" comment in `AppModule.kt:24` and either delete `NoopBuddyTransport.kt` or move it to `androidTest/` since it is dead production code.
