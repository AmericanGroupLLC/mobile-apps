package com.myhealth.wear.health

import android.content.Context
import androidx.health.services.client.HealthServices
import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.ExerciseType
import androidx.health.services.client.data.ExerciseUpdate
import androidx.health.services.client.ExerciseUpdateCallback
import androidx.health.services.client.endExercise
import androidx.health.services.client.prepareExercise
import androidx.health.services.client.startExercise
import androidx.health.services.client.data.ExerciseConfig
import androidx.health.services.client.data.WarmUpConfig
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Wear OS Health Services gateway — kicks off live workout sessions and
 * funnels HR / calories updates back via callback. Symmetric with the
 * watchOS WorkoutController.
 */
class HealthServicesGateway(context: Context) {
    private val client = HealthServices.getClient(context).exerciseClient

    suspend fun startRun(onUpdate: (ExerciseUpdate) -> Unit) {
        val warmUp = WarmUpConfig(
            exerciseType = ExerciseType.RUNNING,
            dataTypes = setOf(DataType.HEART_RATE_BPM, DataType.LOCATION)
        )
        client.prepareExercise(warmUp)

        client.setUpdateCallback(object : ExerciseUpdateCallback {
            override fun onExerciseUpdateReceived(update: ExerciseUpdate) { onUpdate(update) }
            override fun onLapSummaryReceived(lapSummary: androidx.health.services.client.data.ExerciseLapSummary) {}
            override fun onAvailabilityChanged(
                dataType: androidx.health.services.client.data.DataType<*, *>,
                availability: androidx.health.services.client.data.Availability
            ) {}
            override fun onRegistered() {}
            override fun onRegistrationFailed(throwable: Throwable) {}
        })

        val config = ExerciseConfig(
            exerciseType = ExerciseType.RUNNING,
            dataTypes = setOf(
                DataType.HEART_RATE_BPM,
                DataType.DISTANCE,
                DataType.CALORIES,
                DataType.SPEED,
                DataType.LOCATION,
            ),
            isAutoPauseAndResumeEnabled = true,
            isGpsEnabled = true
        )
        client.startExercise(config)
    }

    suspend fun stop() { client.endExercise() }
}
