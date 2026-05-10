package com.americangroupllc.pocket.core.clock

import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
enum class Weekday(val isoIndex: Int, val label: String) {
    SUN(1, "Sun"), MON(2, "Mon"), TUE(3, "Tue"), WED(4, "Wed"),
    THU(5, "Thu"), FRI(6, "Fri"), SAT(7, "Sat")
}

@Serializable
data class Alarm(
    val id: String = UUID.randomUUID().toString(),
    val label: String = "Alarm",
    val hour: Int,         // 0..23
    val minute: Int,       // 0..59
    val repeatOn: Set<Weekday> = emptySet(),
    val soundName: String = "default",
    val enabled: Boolean = true
) {
    init {
        require(hour in 0..23) { "hour must be 0..23, was $hour" }
        require(minute in 0..59) { "minute must be 0..59, was $minute" }
    }
}

@Serializable
data class WorldClockPin(
    val id: String = UUID.randomUUID().toString(),
    val timeZoneId: String,
    val sortIndex: Int
)

@Serializable
data class BedtimeSchedule(
    val bedtimeHour: Int,
    val bedtimeMinute: Int,
    val wakeHour: Int,
    val wakeMinute: Int,
    val enabledOn: Set<Weekday> = emptySet()
)
