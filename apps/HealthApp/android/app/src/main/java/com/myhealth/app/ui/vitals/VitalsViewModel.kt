package com.myhealth.app.ui.vitals

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.myhealth.app.health.HealthConnectGateway
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class VitalsSnapshot(
    val restingHR: Double? = null,
    val vo2Max: Double? = null,
    val weightKg: Double? = null,
    val stepsToday: Long = 0,
    val lastNightSleepHrs: Double? = null,
)

@HiltViewModel
class VitalsViewModel @Inject constructor(
    private val gateway: HealthConnectGateway,
) : ViewModel() {

    private val _snapshot = MutableStateFlow(VitalsSnapshot())
    val snapshot: StateFlow<VitalsSnapshot> = _snapshot.asStateFlow()

    init { refresh() }

    fun refresh() {
        if (!gateway.isAvailable) return
        viewModelScope.launch {
            _snapshot.value = VitalsSnapshot(
                restingHR = runCatching { gateway.latestRestingHR() }.getOrNull(),
                vo2Max = runCatching { gateway.latestVo2Max() }.getOrNull(),
                weightKg = runCatching { gateway.latestWeight() }.getOrNull(),
                stepsToday = runCatching { gateway.stepsToday() }.getOrDefault(0),
                lastNightSleepHrs = runCatching { gateway.lastNightSleepHours() }.getOrNull(),
            )
        }
    }
}
