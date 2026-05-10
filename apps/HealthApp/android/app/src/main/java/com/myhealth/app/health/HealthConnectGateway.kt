package com.myhealth.app.health

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.OxygenSaturationRecord
import androidx.health.connect.client.records.RestingHeartRateRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.Vo2MaxRecord
import androidx.health.connect.client.records.WeightRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import dagger.hilt.android.qualifiers.ApplicationContext
import java.time.Instant
import java.time.temporal.ChronoUnit
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Thin wrapper around `HealthConnectClient`. No-op gracefully when Health
 * Connect is not installed (Android < 14 / unsupported devices).
 */
@Singleton
class HealthConnectGateway @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    val isAvailable: Boolean
        get() = HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE

    private val client: HealthConnectClient? by lazy {
        if (isAvailable) HealthConnectClient.getOrCreate(context) else null
    }

    val readPermissions: Set<String> = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
        HealthPermission.getReadPermission(HeartRateRecord::class),
        HealthPermission.getReadPermission(RestingHeartRateRecord::class),
        HealthPermission.getReadPermission(OxygenSaturationRecord::class),
        HealthPermission.getReadPermission(SleepSessionRecord::class),
        HealthPermission.getReadPermission(WeightRecord::class),
        HealthPermission.getReadPermission(Vo2MaxRecord::class),
    )

    suspend fun stepsToday(): Long {
        val c = client ?: return 0
        val start = Instant.now().truncatedTo(ChronoUnit.DAYS)
        val end = Instant.now()
        val resp = c.readRecords(
            ReadRecordsRequest(StepsRecord::class, TimeRangeFilter.between(start, end))
        )
        return resp.records.sumOf { it.count }
    }

    suspend fun latestRestingHR(): Double? {
        val c = client ?: return null
        val resp = c.readRecords(
            ReadRecordsRequest(
                RestingHeartRateRecord::class,
                TimeRangeFilter.between(Instant.now().minus(7, ChronoUnit.DAYS), Instant.now())
            )
        )
        return resp.records.lastOrNull()?.beatsPerMinute?.toDouble()
    }

    suspend fun latestVo2Max(): Double? {
        val c = client ?: return null
        val resp = c.readRecords(
            ReadRecordsRequest(
                Vo2MaxRecord::class,
                TimeRangeFilter.between(Instant.now().minus(30, ChronoUnit.DAYS), Instant.now())
            )
        )
        return resp.records.lastOrNull()?.vo2MillilitersPerMinuteKilogram
    }

    suspend fun latestWeight(): Double? {
        val c = client ?: return null
        val resp = c.readRecords(
            ReadRecordsRequest(
                WeightRecord::class,
                TimeRangeFilter.between(Instant.now().minus(180, ChronoUnit.DAYS), Instant.now())
            )
        )
        return resp.records.lastOrNull()?.weight?.inKilograms
    }

    suspend fun lastNightSleepHours(): Double? {
        val c = client ?: return null
        val resp = c.readRecords(
            ReadRecordsRequest(
                SleepSessionRecord::class,
                TimeRangeFilter.between(Instant.now().minus(36, ChronoUnit.HOURS), Instant.now())
            )
        )
        val total = resp.records.sumOf { java.time.Duration.between(it.startTime, it.endTime).toMinutes() }
        return if (total > 0) total / 60.0 else null
    }
}
