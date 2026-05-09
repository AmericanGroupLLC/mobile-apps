package com.americangroupllc.buddyplay.games.racer

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.americangroupllc.buddyplay.core.domain.RacerInput
import com.americangroupllc.buddyplay.core.domain.RacerPhysics
import com.americangroupllc.buddyplay.core.domain.RacerState
import com.americangroupllc.buddyplay.core.models.Peer
import com.americangroupllc.buddyplay.core.models.Transport
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class RacerViewModel(host: Peer, guest: Peer, val localPlayerId: String, transport: Transport) : ViewModel() {
    val host = host
    val guest = guest

    var state: RacerState by mutableStateOf(RacerPhysics.initialState(host, guest))
        private set
    var rejectMessage: String? by mutableStateOf(
        if (transport == Transport.BLE)
            "Mini Racer needs Wi-Fi or Hotspot — BLE is too slow for real-time play. Pick a turn-based game (Chess or Dice Kingdom) or switch to Wi-Fi."
        else null
    )
        private set

    private var ticker: Job? = null
    private var localInput = RacerInput(localPlayerId, throttle = 0.0, brake = 0.0, steering = 0.0)

    fun startTicking() {
        if (rejectMessage != null) return
        stopTicking()
        ticker = viewModelScope.launch {
            while (true) {
                delay(33)
                state = RacerPhysics.tick(state, dtMillis = 33)
            }
        }
    }

    fun stopTicking() {
        ticker?.cancel(); ticker = null
    }

    fun setThrottle(v: Double) { localInput = localInput.copy(throttle = v); pushInput() }
    fun setBrake(v: Double)    { localInput = localInput.copy(brake = v);    pushInput() }
    fun setSteering(v: Double) { localInput = localInput.copy(steering = v); pushInput() }

    private fun pushInput() {
        val car = state.cars[localPlayerId] ?: return
        state.cars[localPlayerId] = car.copy(lastInput = localInput)
    }
}
