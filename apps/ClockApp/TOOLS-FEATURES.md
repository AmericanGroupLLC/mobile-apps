# TOOLS-FEATURES — Pocket

Per-tool feature catalogue. Each tool here is shipped MVP-deep (the user
explicitly chose breadth-of-five-tools over depth-of-one).

---

## Cross-tool matrix

| Tool | iPhone | Apple Watch | Android | Wear OS |
|---|:---:|:---:|:---:|:---:|
| Clock | ✅ alarm + world + stop + timer + bedtime | ✅ alarm + world + stop + timer + bedtime | ✅ alarm + world + stop + timer + bedtime | ⚠️ no on-device alarm |
| Calculator | ✅ basic + scientific (landscape) | ✅ basic + tip-splitter | ✅ basic + scientific (landscape) | ✅ basic |
| Measure | ✅ ARKit + ruler fallback | — | ✅ ARCore + ruler fallback | — |
| Compass | ✅ heading + lat/lon | ✅ heading only | ✅ heading + lat/lon | ✅ heading only |
| Level | ✅ flat + tilted | ✅ flat | ✅ flat + tilted | ✅ flat |

---

## 1. Clock

| Capability | Notes |
|---|---|
| Alarms | Real OS scheduling. iOS via `UNUserNotificationCenter` (calendar trigger, repeating by weekday). Android via `AlarmManager.setAlarmClock()` + `BootReceiver` for reboot survival. |
| World Clock | Static `TimezoneCatalog` of ~440 IANA zones. UI lets user pin favourites. |
| Stopwatch | Lap times. Survives backgrounding via stored `start instant`. |
| Timer | Single timer. iOS notification + sound at completion. Android `AlarmManager.setExact` + foreground service for sound. |
| Bedtime | Sleep-window picker → schedules a wind-down + wake notification. Computes total hours via `BedtimeEngine`. |

Shared logic: `PocketCore/Clock/{Models, AlarmStore, TimezoneCatalog, BedtimeEngine}` and `:core/clock/...`.

---

## 2. Calculator

| Capability | Notes |
|---|---|
| Basic | `+ − × ÷ % . ±` and `=`. Live result preview. |
| Scientific (landscape) | Adds `sin cos tan ln log √ x² x^y π e ( )` and inverse trig. |
| History | Last 10 results, swipe to clear. |
| Watch | Basic + tip-splitter (Apple Watch). |

Shared logic:

- `PocketCore/Calculator/CalculatorEngine.swift` — pure-Swift shunting-yard.
- `:core/calculator/CalculatorEngine.kt` — Kotlin port.
- Same test-case set drives both: `2+3*4=14`, `(1+2)*(3+4)=21`, `sin(π/2)=1`, `2^10=1024`, `√2≈1.4142`, `÷0 → error`.

---

## 3. Measure

Phone-only.

| Capability | Notes |
|---|---|
| Single point-to-point | Two taps to set start + end; live distance overlay. Units toggle cm / inches. |
| Ruler fallback | On-screen ruler when ARKit/ARCore not available. |
| Out of scope (v1) | Multi-segment, area, volume, people-height. |

Implementation:

- iOS: `MeasureView` + `MeasureARViewController` (UIViewControllerRepresentable wrapping `ARSCNView`).
- Android: `MeasureScreen` + `MeasureSession` (host an `arsceneview` and react to `HitResult`).

---

## 4. Compass

| Capability | Notes |
|---|---|
| Magnetic heading | Direct sensor reading. |
| True heading | Magnetic + declination correction; uses location (when granted). |
| Cardinal label | N/NE/E/SE/S/SW/W/NW computed by `cardinalLabel(forDegrees:)`. |
| Lat/lon panel | Phone only. CoreLocation / `LocationManager.GPS_PROVIDER`. |
| Accuracy ring | Visual indicator from sensor accuracy heuristic. |

Shared logic:

- `PocketCore/Compass/HeadingMath.swift` — `magneticToTrue`, `bearingBetween(_:_:)`, `cardinalLabel(forDegrees:)`.
- `:core/compass/HeadingMath.kt` — same API.

Platform sensors:

- iOS: `CLLocationManager.startUpdatingHeading()` + `startUpdatingLocation()`.
- watchOS: `CLLocationManager.startUpdatingHeading()` only (no continuous location — battery).
- Android: `SensorManager.TYPE_ROTATION_VECTOR` fused via `getOrientation` + `LocationManager` (phone only).
- Wear OS: `SensorManager.TYPE_ROTATION_VECTOR` only.

---

## 5. Level

| Capability | Notes |
|---|---|
| Flat mode | Bullseye + degrees-off-axis. Auto-engages when device is roughly horizontal. |
| Tilted mode | Single-axis bubble with degree readout. Auto-engages when device is upright. |
| Calibration | Long-press to zero current attitude as the new "flat". |

Shared logic:

- `PocketCore/Level/LevelMath.swift` — `pitchRoll(fromAttitude:)`, `bubbleOffset(forPitch:roll:radius:)`. No platform deps.
- `:core/level/LevelMath.kt` — same API.

Platform sensors:

- iOS / watchOS: `CMMotionManager.deviceMotionUpdateInterval = 1.0/60` → `.attitude.pitch/roll`.
- Android / Wear OS: `SensorManager.TYPE_GRAVITY` listener → low-pass filter → derived pitch/roll.
