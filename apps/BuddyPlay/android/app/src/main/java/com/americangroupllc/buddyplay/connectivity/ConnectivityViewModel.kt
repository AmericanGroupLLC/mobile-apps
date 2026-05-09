package com.americangroupllc.buddyplay.connectivity

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.americangroupllc.buddyplay.core.connectivity.ConnectivityBridge
import com.americangroupllc.buddyplay.core.connectivity.DiscoveredPeer
import com.americangroupllc.buddyplay.core.models.Peer
import com.americangroupllc.buddyplay.core.storage.DeviceIdProvider
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Compose-friendly wrapper around [ConnectivityBridge]. Surfaces the
 * `state` and `hosts` lists as `StateFlow` for SwiftUI-style observation.
 */
@HiltViewModel
class ConnectivityViewModel @Inject constructor(
    private val bridge: ConnectivityBridge,
    private val deviceIds: DeviceIdProvider,
) : ViewModel() {

    private val _state = MutableStateFlow<ConnectivityBridge.State>(ConnectivityBridge.State.Idle)
    val state: StateFlow<ConnectivityBridge.State> = _state.asStateFlow()

    private val _hosts = MutableStateFlow<List<DiscoveredPeer>>(emptyList())
    val hosts: StateFlow<List<DiscoveredPeer>> = _hosts.asStateFlow()

    init {
        bridge.onStateChanged = { _state.value = it }
        bridge.onHostsChanged = { _hosts.value = it }
    }

    fun localPeer(displayName: String): Peer = Peer(
        id = deviceIds.deviceId(),
        displayName = displayName,
        platform = Peer.Platform.ANDROID,
        lastSeenAt = System.currentTimeMillis(),
    )

    fun host(displayName: String) = viewModelScope.launch {
        bridge.host(localPeer(displayName))
    }

    fun scan(displayName: String) = viewModelScope.launch {
        bridge.scan(localPeer(displayName))
    }

    fun connectTo(host: DiscoveredPeer) = viewModelScope.launch {
        bridge.connect(host)
    }

    fun disconnect() = bridge.disconnect()
}
