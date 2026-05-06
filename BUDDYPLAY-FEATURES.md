# BUDDYPLAY-FEATURES.md — v1.0 feature inventory

## Connectivity

- [x] Local Wi-Fi via NSD/Bonjour (`_buddyplay._tcp`) + length-prefixed TCP framing.
- [x] Mobile Hotspot via the same Wi-Fi path once both peers join.
- [x] Bluetooth LE GATT fallback on service `0xBP01` (turn-based games only).
- [x] Auto failover ladder (Wi-Fi → Hotspot → BLE).
- [x] User-overridable transport choice (auto / Wi-Fi-only / BLE-only).
- [x] 4-character pairing code (`BUDD-7Q2K`) for visual confirm.
- [x] Cross-platform iOS ↔ Android peers.
- [x] Schema-versioned wire format (`v: 1`); decoder rejects unknown versions.
- [x] Deterministic host election (no round-trip).

## Games

- [x] **Royal Chess** — 8×8, full move legality (castling, en-passant,
      promotion, check/mate/stalemate). Turn-based, BLE-OK.
- [x] **Dice Kingdom** — Ludo-style 4-token race. 2-player (DuoPlay).
      Turn-based, BLE-OK.
- [x] **Mini Racer** — top-down 2D racer. 30 Hz host tick + client prediction.
      Wi-Fi or Hotspot only; BLE refused.

## Home

- [x] Horizontal "card scroller" of the 3 games.
- [x] Persistent floating **Join Nearby Game** button (auto-scans every ~5 s).
- [x] Tabs: All games · DuoPlay (2P) · Party (3-4P, dimmed in v1).
- [x] "Last played" carousel above the grid.

## Lobby

- [x] **Host**: pick a game → advertise on Wi-Fi + BLE simultaneously → show pairing code.
- [x] **Join**: live scan list → tap a peer → confirm code → exchange names → start.

## Local rivalries (instead of leaderboards)

- [x] Per-opponent win/loss/draw tally, per game.
- [x] Keyed by stable opponent UUID + display name.
- [x] On-disk JSON store (no cloud).
- [x] Settings → Erase all rivalries.
- [x] Settings → Reset device ID.

## Settings

- [x] Connectivity preference (auto / Wi-Fi-only / BLE-only).
- [x] Display name.
- [x] Default game.
- [x] Sound on/off.
- [x] Haptics on/off.
- [x] Theme: system / light / dark.
- [x] Telemetry: nothing in v1 (disclosure label).

## Telemetry

- [x] Stub interfaces (`AnalyticsService`, `CrashReportingService`) — no transports attached.
- [ ] Real Sentry / PostHog wiring (v1.1).

## Monetisation

- [x] `PremiumGateService` stub returning `unlocked = true`.
- [ ] RevenueCat / Play Billing (v1.1).
- [ ] Cached AdMob (v1.1).

## NOT in v1 (explicitly)

- [ ] Wi-Fi Direct (`WifiP2pManager`).
- [ ] 3-4 player party games.
- [ ] In-app purchases / ads.
- [ ] Voice chat (v2).
- [ ] UGC / custom maps (v2).
- [ ] Tournament mode (v2).
- [ ] Apple Watch / Wear OS surfaces.
- [ ] Backend / server.
- [ ] Telemetry SDKs.
- [ ] Cloud leaderboards.
- [ ] Push notifications.
- [ ] Foreground service.
