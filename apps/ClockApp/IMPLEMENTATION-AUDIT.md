# IMPLEMENTATION-AUDIT — Pocket

**Date:** 2026-05-08
**Round / Phase:** Round-4 / Phase-7a
**Scope:** Cross-platform feature audit (iOS, watchOS, Android, Wear OS) against `TOOLS-FEATURES.md`, `README.md`, `DESIGN.md`. Bug list scoped to Kotlin/Swift/JS/TS sources under `android/`, `ios/`, `watchos/`, `shared/` (excludes `.md`, build artefacts, and `node_modules`).

---

## 1. Severity Legend

| Severity | Meaning |
|---|---|
| **P0** | Ship-stopper. Crashes, data loss, store-policy violations, or a promised flagship feature is non-functional in a way users will hit on launch. |
| **P1** | Promised feature missing or fundamentally broken on a shipped platform. Must be fixed before next release. |
| **P2** | Capability incomplete vs. promise (e.g., one tier of a feature missing) but the tool still has user value. Schedule for follow-up release. |
| **P3** | Documented design limitation, known wontfix on a single platform, or polish item. Track but does not block. |

---

## 2. Promised Features → Implementation Citations

### 2.1 Clock

| Capability | Platform | Status | Citation / Gap |
|---|---|---|---|
| Alarms — real OS scheduling | iOS | **GAP (P1)** — `AlarmService` exists (`UNUserNotificationCenter`) but UI never invokes it. | Service: `Z:\home\spatchava\AmericanGroupLLC\ClockApp\ios\Pocket\Services\AlarmService.swift:5-42` (defines `schedule/cancel`). UI: `Z:\home\spatchava\AmericanGroupLLC\ClockApp\ios\Pocket\AlarmView.swift:9-35` keeps alarms in `@State` only — no call site for `AlarmService.shared.schedule(_:)` exists in `ios/`. |
| Alarms — survive reboot (Android `BootReceiver`) | Android | **GAP (P1)** — receiver only logs; reschedule TODO. | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\app\src\main\java\com\americangroupllc\pocket\alarm\BootReceiver.kt:12` — `// TODO load Alarm rows from Room and re-schedule via AlarmService.` |
| Alarms — fire notification when alarm triggers (Android) | Android | **GAP (P1)** — receiver only logs; no notification/sound. | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\app\src\main\java\com\americangroupllc\pocket\alarm\AlarmReceiver.kt:11` — `// TODO wake the user with a high-priority foreground notification + sound.` |
| World Clock — TimezoneCatalog | iOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\shared\PocketCore\Sources\PocketCore\Clock\TimezoneCatalog.swift` (referenced from `ios/Pocket/ClockView.swift`). |
| World Clock | Android | **GAP (P1)** — UI is placeholder text. | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\app\src\main\java\com\americangroupllc\pocket\clock\ClockScreen.kt:27` — `Text("World clock, alarms, stopwatch, timer, bedtime — see /clock subscreens.")`. No subscreens exist under `android/app/src/main/java/com/americangroupllc/pocket/clock/`. |
| Stopwatch | iOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\ios\Pocket\StopwatchView.swift`. |
| Stopwatch | Android | **GAP (P1)** — only the `ClockScreen` placeholder above. No `StopwatchScreen.kt` in `android/app/src/main/java/com/americangroupllc/pocket/clock/`. |
| Timer | iOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\ios\Pocket\TimerView.swift`. |
| Timer | Android | **GAP (P1)** — no `TimerScreen.kt` under `android/app/.../clock/`; promised `AlarmManager.setExact + foreground service` not present. |
| Bedtime — `BedtimeEngine` | iOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\shared\PocketCore\Sources\PocketCore\Clock\BedtimeEngine.swift` + `ios/Pocket/Views/Clock/BedtimeView.swift`. |
| Bedtime — `BedtimeEngine` | Android | **GAP (P2)** — engine ported (`Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\core\src\main\java\com\americangroupllc\pocket\core\clock\BedtimeEngine.kt`) and unit-tested (`...\core\src\test\...\BedtimeEngineTest.kt`), but no UI consumer (`BedtimeScreen.kt` does not exist). |
| Wear — clock face | Wear OS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\wear\src\main\java\com\americangroupllc\pocketwear\ClockScreen.kt`. |
| Wear — Next-Alarm Tile | Wear OS | **GAP (P1)** — empty stub. | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\wear\src\main\java\com\americangroupllc\pocketwear\tile\NextAlarmTileService.kt:9-32` — class doc says `"This stub returns an empty tile."`; `onTileRequest` returns `TileBuilders.Tile.Builder().setResourcesVersion("1").build()` with no layout. |
| Wear — on-device alarm | Wear OS | **GAP (P3)** — explicitly out-of-scope per `TOOLS-FEATURES.md` cross-tool matrix (`⚠️ no on-device alarm`). Documented design limitation. |

### 2.2 Calculator

| Capability | Platform | Status | Citation / Gap |
|---|---|---|---|
| Basic | iOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\ios\Pocket\Views\Calculator\CalculatorView.swift:8-14` (`basicKeys`). |
| Basic | Android | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\app\src\main\java\com\americangroupllc\pocket\calculator\CalculatorScreen.kt:42-48`. |
| Basic | Wear OS | ✅ (basic shown in `WatchCalculator` analogue) — present in `WatchCalculatorView` only on watchOS, not Wear OS. **GAP (P2)** for Wear OS — no `CalculatorScreen.kt` under `android/wear/src/main/java/.../`. |
| Basic | watchOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\watchos\PocketWatch\App\PocketWatchApp.swift:38-63` (`WatchCalculatorView`). |
| Scientific (landscape) | iOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\ios\Pocket\Views\Calculator\CalculatorView.swift:16-19` (`scientificKeys`) + `:45-46` (`isLandscape`). |
| Scientific (landscape) | Android | **GAP (P1)** — only basic 4-column grid; no `sin/cos/tan/ln/log/√/x²/x^y/π/e/( )` keys, no landscape handling. See `CalculatorScreen.kt:42-48`. |
| History (last 10, swipe to clear) | iOS | **GAP (P2)** — no history UI. `grep -i history` in `ios/Pocket/Views/Calculator/` returns 0 results. |
| History (last 10, swipe to clear) | Android | **GAP (P2)** — no history UI in `CalculatorScreen.kt`. |
| Tip-splitter | watchOS | **GAP (P2)** — `WatchCalculatorView` has only `0–9 . = + - × ÷ AC`. No `tip` or split UI; `grep -i tip` in `watchos/` returns 0 results. |
| Shared `CalculatorEngine` (Swift) | iOS / watchOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\shared\PocketCore\Sources\PocketCore\Calculator\CalculatorEngine.swift`. |
| Shared `CalculatorEngine` (Kotlin) | Android | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\core\src\main\java\com\americangroupllc\pocket\core\calculator\CalculatorEngine.kt`. |

### 2.3 Measure (phone-only)

| Capability | Platform | Status | Citation / Gap |
|---|---|---|---|
| ARKit point-to-point | iOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\ios\Pocket\Views\Measure\MeasureARViewController.swift:5-84` — `ARSCNView`, raycast, two-marker measurement. |
| ARKit ruler fallback | iOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\ios\Pocket\Views\Measure\MeasureRulerView.swift`. |
| ARCore point-to-point | Android | **GAP (P1)** — only an availability check + placeholder text. The promised `MeasureSession` host of `arsceneview` + `HitResult` does not exist. | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\app\src\main\java\com\americangroupllc\pocket\measure\MeasureScreen.kt:24-32` — only renders text; line 27 references `(MeasureSession scaffold — see measure/MeasureSession.kt for ARCore wiring.)` but `MeasureSession.kt` is not present in the repo (filename search returned no results). Dependency `io.github.sceneview:arsceneview:2.2.1` is declared in `android/app/build.gradle.kts:78` but never instantiated. |
| ARCore ruler fallback | Android | **GAP (P2)** — `MeasureScreen.kt:29-31` shows fallback copy only; no on-screen ruler component is rendered. |

### 2.4 Compass

| Capability | Platform | Status | Citation / Gap |
|---|---|---|---|
| Magnetic heading | iOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\ios\Pocket\Services\HeadingService.swift:11,33` (`CLLocationManager` + `didUpdateHeading`). |
| Magnetic heading | watchOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\watchos\PocketWatch\Services\WatchHeadingService.swift`. |
| Magnetic heading | Android | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\app\src\main\java\com\americangroupllc\pocket\compass\CompassScreen.kt:57-65` (`TYPE_ROTATION_VECTOR` + `getOrientation`). |
| Magnetic heading | Wear OS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\wear\src\main\java\com\americangroupllc\pocketwear\compass\WearCompass.kt:36-43`. |
| True heading (declination) | iOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\ios\Pocket\Services\HeadingService.swift:42` (`didUpdateLocations`) + shared `HeadingMath.magneticToTrue`. |
| True heading (declination) | Android | **GAP (P2)** — `CompassScreen.kt` reads only `TYPE_ROTATION_VECTOR`; no `LocationManager` query nor call to `HeadingMath.magneticToTrue`. |
| Cardinal label | All platforms | ✅ via shared math | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\shared\PocketCore\Sources\PocketCore\Compass\HeadingMath.swift` + `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\core\src\main\java\com\americangroupllc\pocket\core\compass\HeadingMath.kt`. |
| Lat/lon panel (phone only) | iOS | ✅ | `HeadingService.swift:42-49`. |
| Lat/lon panel (phone only) | Android | **GAP (P2)** — no `LocationManager` use in `CompassScreen.kt`. |
| Accuracy ring | iOS / Android | **GAP (P2)** — no accuracy heuristic surfaced in either `CompassView` or `CompassScreen`. |

### 2.5 Level

| Capability | Platform | Status | Citation / Gap |
|---|---|---|---|
| Flat mode | iOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\ios\Pocket\Views\Level\LevelView.swift` + shared `LevelMath.bubbleOffset`. |
| Flat mode | watchOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\watchos\PocketWatch\App\PocketWatchApp.swift:82-96` (`WatchLevelView`). |
| Flat mode | Android | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\app\src\main\java\com\americangroupllc\pocket\level\LevelScreen.kt:37,56-62` (`TYPE_GRAVITY` + `LevelMath.bubbleOffset`). |
| Flat mode | Wear OS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\wear\src\main\java\com\americangroupllc\pocketwear\level\WearLevel.kt:31,49-55`. |
| Tilted mode (phone) | iOS / Android | **GAP (P2)** — neither `LevelView.swift` nor `LevelScreen.kt` toggles a separate "upright" mode with a single-axis bubble + degree readout. |
| Calibration (long-press zero) | iOS / Android | **GAP (P2)** — no long-press handler / stored offset visible in `LevelView.swift` or `LevelScreen.kt`. |
| Shared `LevelMath` | iOS | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\shared\PocketCore\Sources\PocketCore\Level\LevelMath.swift`. |
| Shared `LevelMath` | Android | ✅ | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\core\src\main\java\com\americangroupllc\pocket\core\level\LevelMath.kt`. |

---

## 3. Bug / TODO Inventory (source files only)

Pattern searched: `\b(TODO|FIXME|XXX|HACK)\b` and `\b(stub|placeholder)\b` over `*.kt`, `*.swift`, `*.js`, `*.ts`, `*.tsx`, `*.jsx` in `android/`, `ios/`, `watchos/`, `shared/`. Excludes `.md`, build outputs, `node_modules`.

| # | File:Line | Pattern | Severity | Description |
|---|---|---|---|---|
| 1 | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\app\src\main\java\com\americangroupllc\pocket\alarm\BootReceiver.kt:12` | `TODO` | **P1** | Boot receiver logs only; alarms do not survive device reboot. Promised in `TOOLS-FEATURES.md §1` ("Android via `AlarmManager.setAlarmClock()` + `BootReceiver` for reboot survival"). |
| 2 | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\app\src\main\java\com\americangroupllc\pocket\alarm\AlarmReceiver.kt:11` | `TODO` | **P1** | Alarm receiver logs only; no high-priority foreground notification or sound is fired when an alarm triggers. |
| 3 | `Z:\home\spatchava\AmericanGroupLLC\ClockApp\android\wear\src\main\java\com\americangroupllc\pocketwear\tile\NextAlarmTileService.kt:9-21` | `stub` (class doc + empty `onTileRequest`) | **P1** | Wear tile is documented as `"This stub returns an empty tile."` and returns a `Tile.Builder()` with no layout. |

No other `TODO`/`FIXME`/`XXX`/`HACK`/`stub`/`placeholder` markers were found in the in-scope source set. (The earlier loose regex matched substrings like `toDouble` — those are false positives and excluded from the table above.)

---

## 4. Summary Counts

- **Promised feature/platform rows audited:** 39
  - ✅ Implemented: 19
  - **GAP:** 20 (1 P3 documented limitation; 11 P2; 8 P1; 0 P0)
- **Source-level TODO/stub markers:** 3 (all **P1**)
- **Severity totals (gaps + bugs combined, deduplicated where the same item appears in both lists — BootReceiver, AlarmReceiver, and `NextAlarmTileService` are counted once):**

| Severity | Count |
|---|---:|
| P0 | 0 |
| P1 | 8 |
| P2 | 11 |
| P3 | 1 |
| **Total open items** | **20** |

### Top blockers for next release (P1)

1. Android — wire `AlarmReceiver` to a foreground notification + sound (`AlarmReceiver.kt:11`).
2. Android — implement `BootReceiver` reschedule from Room (`BootReceiver.kt:12`).
3. Wear OS — implement `NextAlarmTileService` layout from `AlarmRepository` (`NextAlarmTileService.kt:9-21`).
4. iOS — wire `AlarmView` to `AlarmService.shared.schedule(_:)` so saved alarms actually schedule notifications.
5. Android — build Clock subscreens (World, Alarms, Stopwatch, Timer, Bedtime); current `ClockScreen.kt:27` is a placeholder.
6. Android — Calculator scientific (landscape) keypad missing.
7. Android — Measure: `MeasureSession.kt` does not exist; ARCore is not actually wired despite the `arsceneview` dependency.

---

*Generated 2026-05-08 as part of Round-4 Phase-7a audit. Read-only audit — no source files were modified.*
