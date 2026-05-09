package com.americangroupllc.pocket.core.clock

object BedtimeEngine {
    /** Hours of sleep between bedtime and wake, wrapping past midnight. */
    fun sleepHours(bedtimeH: Int, bedtimeM: Int, wakeH: Int, wakeM: Int): Double {
        val b = bedtimeH * 60 + bedtimeM
        val w = wakeH * 60 + wakeM
        val delta = if (w >= b) w - b else (24 * 60 - b) + w
        return delta / 60.0
    }

    /** True if the current minute falls in [bedtime - windDownMin, bedtime). */
    fun isWinddown(nowH: Int, nowM: Int, bedtimeH: Int, bedtimeM: Int, windDownMin: Int = 30): Boolean {
        val n = nowH * 60 + nowM
        val b = bedtimeH * 60 + bedtimeM
        val start = ((b - windDownMin) + 24 * 60) % (24 * 60)
        return if (start <= b) n in start until b
        else n >= start || n < b
    }
}
