// BedtimeEngine — pure-logic helpers for bedtime/wake math.
import Foundation

public enum BedtimeEngine {
    /// Hours of sleep between bedtime and wake, treating wake-time-before-bedtime
    /// as wrapping to the next morning.
    public static func sleepHours(bedtime: (h: Int, m: Int), wake: (h: Int, m: Int)) -> Double {
        let bMin = bedtime.h * 60 + bedtime.m
        let wMin = wake.h * 60 + wake.m
        let delta = wMin >= bMin ? wMin - bMin : (24 * 60 - bMin) + wMin
        return Double(delta) / 60.0
    }

    /// Returns true when the bedtime windsdown has begun for `now` relative to bedtime.
    /// Windown begins `windDownMinutes` before bedtime.
    public static func isWinddown(now: (h: Int, m: Int), bedtime: (h: Int, m: Int), windDownMinutes: Int = 30) -> Bool {
        let nMin = now.h * 60 + now.m
        let bMin = bedtime.h * 60 + bedtime.m
        let start = (bMin - windDownMinutes + 24 * 60) % (24 * 60)
        if start <= bMin {
            return nMin >= start && nMin < bMin
        } else {
            return nMin >= start || nMin < bMin
        }
    }
}
