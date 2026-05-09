# CONNECTIVITY.md — BuddyPlay's offline transport layer

This is the load-bearing doc for v1. Two phones must find each other and
exchange game state with no internet. The ladder below is the user-visible
**Connect** screen; it tries each rung top-down and surfaces a clear status,
and lets the user explicitly pick a rung if the auto-detect picks the wrong
one.

## §1 — The ladder

| Rung | Transport | Discovery | Why this order |
|---|---|---|---|
| 1 | **Local Wi-Fi** | Bonjour / NSD on `_buddyplay._tcp` | Highest throughput, lowest latency, zero user setup. |
| 2 | **Mobile Hotspot** | same Bonjour / NSD path once both peers are on the hotspot's subnet | Works when there's no router. Requires user to enable hotspot manually (no programmatic toggle on either platform). |
| 3 | **Bluetooth LE** | GATT advertisement on service UUID `0xBP01` | Last resort. Fine for turn-based games (Chess, Ludo). Mini Racer **rejects** this rung. |

## §2 — Wire format

JSON on Wi-Fi, length-prefixed framing. CBOR opt-in via flag for v1.1.

```
4-byte big-endian length  ║  utf-8 JSON payload
```

### Frame envelope (every payload)

```json
{
  "v": 1,
  "sessionId": "<uuid>",
  "from": "<peer-uuid>",
  "kind": "input" | "state" | "lobby" | "ping" | "pong",
  "ts": 1735689600000,
  "payload": { ... }
}
```

### Versioning

Decoder hard-fails on unknown major versions and surfaces an
**"Update your friend's app"** toast. Tested in `WireCodecTests` /
`WireCodecKtTest`.

## §3 — Bonjour / NSD interop

Both peers should *publish* their own service AND *scan* for peers. Android's
`NsdManager` sometimes skips registrations made before the service was fully
initialised; mitigate by running the publish-then-scan sequence with a
1-second debounce + retry loop.

| | iOS | Android |
|---|---|---|
| Service type | `_buddyplay._tcp` | `_buddyplay._tcp` |
| Publisher API | `NWListener` | `NsdManager.registerService` |
| Scanner API | `NWBrowser` | `NsdManager.discoverServices` |
| Permission prompt | `NSLocalNetworkUsageDescription` (Local Network) — surfaced on first Host/Join action, not at app launch. | `NEARBY_WIFI_DEVICES` (API 33+) or `ACCESS_FINE_LOCATION` (API ≤30) — gated by `usesPermissionFlags="neverForLocation"` for `BLUETOOTH_SCAN` on API 31+. |

## §4 — BLE GATT layout

Single custom service exposing two characteristics:

| Characteristic | UUID | Direction | Properties | Purpose |
|---|---|---|---|---|
| **Inbound** (client→host) | `42554450-0001-1000-8000-00805F9B34FB` | client writes | `WRITE_WITHOUT_RESPONSE` | Guest sends inputs to host. |
| **Outbound** (host→client) | `42554450-0002-1000-8000-00805F9B34FB` | host notifies | `NOTIFY` | Host streams state back. |

Service UUID: `42554450-0000-1000-8000-00805F9B34FB` (the `42554450` prefix
spells `BUDP` in ASCII).

Frames > MTU (typically 185 bytes) are split into 4-byte length-prefixed
chunks; receiver reassembles. Same envelope as Wi-Fi.

## §5 — Host election

Both peers run `HostElection` locally on the `(peerA.id, peerB.id)` tuple.
Lexicographically smaller UUID wins; tie-break by platform: iOS wins (no
particular reason, just deterministic). No round-trip required — both peers
agree without negotiating.

## §6 — Per-game transport requirements

| Game | Wi-Fi | Hotspot | BLE |
|---|---|---|---|
| Royal Chess | ✅ | ✅ | ✅ |
| Dice Kingdom | ✅ | ✅ | ✅ |
| Mini Racer | ✅ | ✅ (RTT-gated) | ❌ refused |

Mini Racer needs a 30 Hz state tick from host to guest; BLE's GATT throughput
+ ~30-200 ms latency makes that infeasible. Lobby refuses to start Racer on
BLE and recommends Chess / Ludo. On Hotspot, lobby runs an RTT probe and
refuses Racer if RTT > 250 ms.

## §7 — Cross-platform interop matrix

| Host | Guest | Wi-Fi | Hotspot | BLE |
|---|---|---|---|---|
| iOS | iOS | ✅ | ✅ | ✅ |
| iOS | Android | ✅ | ✅ | ✅ |
| Android | iOS | ✅ | ✅ | ✅ |
| Android | Android | ✅ | ✅ | ✅ |

Cross-platform is a hard constraint. Wire format is JSON to make debugging
easy across language runtimes.

## §8 — Pairing UX

1. **Host** picks a game → BuddyPlay starts advertising on Wi-Fi + BLE
   simultaneously. UI shows a 4-character pairing code (`BUDD-7Q2K`) for
   the guest to confirm.
2. **Join** scans the list of advertised peers. Tapping a peer pulls up the
   same code-confirm step.
3. After confirm, the lobby exchanges player names, runs `HostElection`,
   and starts the chosen game.

Pairing codes are 4 base32 characters derived from the host's session UUID.
Collisions are deliberately allowed (4 chars = 1024 codes) — the user must
visually confirm both peers see the same code before proceeding.

## §9 — Permissions audit

### iOS
- `NSBluetoothAlwaysUsageDescription` — BLE advertise + scan.
- `NSLocalNetworkUsageDescription` — NWBrowser / NWConnection.
- `NSBonjourServices` — declares `_buddyplay._tcp`.

**No camera, no microphone, no location.** No background modes in v1
(both peers must keep BuddyPlay foregrounded during play).

### Android
- `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT` + `BLUETOOTH_ADVERTISE` (API 31+).
- `BLUETOOTH` + `BLUETOOTH_ADMIN` (API ≤30 fallback).
- `ACCESS_FINE_LOCATION` (only API ≤30, gated by
  `usesPermissionFlags="neverForLocation"` from API 31).
- `NEARBY_WIFI_DEVICES` (API 33+).
- `ACCESS_WIFI_STATE` + `CHANGE_WIFI_STATE`.
- `INTERNET` (BLE peripheral SDK sometimes wants it during pairing).

**No camera, no microphone, no foreground service, no notifications.**

## §10 — Failure modes

| Failure | Detection | Recovery |
|---|---|---|
| Wi-Fi router blocks mDNS | Bonjour scan returns empty after 5 s | UI offers "switch to Hotspot" + "switch to BLE" |
| iOS Local Network prompt rejected | NWBrowser returns `unsatisfied` | UI shows "Enable Local Network in Settings → Privacy" deep link |
| BLE permission rejected | scanner throws | UI shows "Enable Bluetooth permission in Settings" deep link |
| Connection drops mid-game | TCP/GATT connection error | UI offers "Reconnect" + auto-saves last move so the rivalry tally still increments on Chess / Ludo |
| Schema version mismatch | WireCodec decode fails on `v` field | UI shows "Update your friend's app" toast |
| RTT > 250 ms on Hotspot Racer | RTT probe before game start | Lobby refuses Racer + recommends Chess / Ludo |
