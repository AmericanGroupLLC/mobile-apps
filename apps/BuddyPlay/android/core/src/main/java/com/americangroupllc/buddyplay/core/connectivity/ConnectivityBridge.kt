package com.americangroupllc.buddyplay.core.connectivity

import com.americangroupllc.buddyplay.core.models.Peer
import com.americangroupllc.buddyplay.core.models.Transport

/**
 * State machine for the failover ladder. The UI's Connect screen listens
 * to [state] and renders accordingly.
 *
 * Mirrors `shared/BuddyCore/Sources/BuddyCore/Connectivity/ConnectivityBridge.swift`.
 */
class ConnectivityBridge(
    private val wifi: BuddyTransport,
    private val ble: BuddyTransport,
) {
    sealed class State {
        object Idle : State()
        data class Advertising(val via: Transport) : State()
        data class Scanning(val via: Transport) : State()
        data class Connecting(val to: DiscoveredPeer) : State()
        data class Connected(val peer: Peer, val via: Transport) : State()
        data class Failed(val reason: String) : State()
    }

    enum class Preference { AUTO, WIFI_ONLY, BLE_ONLY }

    var state: State = State.Idle
        private set(value) { field = value; onStateChanged?.invoke(value) }

    var preference: Preference = Preference.AUTO

    var onStateChanged: ((State) -> Unit)? = null
    var onHostsChanged: ((List<DiscoveredPeer>) -> Unit)? = null
    var onFrame: ((ByteArray) -> Unit)? = null

    private var lastWifi: List<DiscoveredPeer> = emptyList()
    private var lastBle:  List<DiscoveredPeer> = emptyList()

    init { wireObservers() }

    suspend fun host(localPeer: Peer) {
        when (preference) {
            Preference.AUTO, Preference.WIFI_ONLY -> {
                try {
                    wifi.startHosting(localPeer)
                    state = State.Advertising(Transport.WIFI)
                    if (preference == Preference.AUTO) {
                        runCatching { ble.startHosting(localPeer) }
                    }
                    return
                } catch (e: Throwable) {
                    if (preference == Preference.WIFI_ONLY) {
                        state = State.Failed("Wi-Fi advertising failed: ${e.message}")
                        throw e
                    }
                }
                ble.startHosting(localPeer)
                state = State.Advertising(Transport.BLE)
            }
            Preference.BLE_ONLY -> {
                ble.startHosting(localPeer)
                state = State.Advertising(Transport.BLE)
            }
        }
    }

    suspend fun scan(localPeer: Peer) {
        when (preference) {
            Preference.AUTO, Preference.WIFI_ONLY -> {
                wifi.startScanning(localPeer)
                state = State.Scanning(Transport.WIFI)
                if (preference == Preference.AUTO) {
                    runCatching { ble.startScanning(localPeer) }
                }
            }
            Preference.BLE_ONLY -> {
                ble.startScanning(localPeer)
                state = State.Scanning(Transport.BLE)
            }
        }
    }

    suspend fun connect(host: DiscoveredPeer) {
        state = State.Connecting(host)
        val t = if (host.transport == Transport.BLE) ble else wifi
        t.connect(host)
    }

    suspend fun send(frame: ByteArray) {
        val s = state
        if (s !is State.Connected) throw NotConnectedException()
        val t = if (s.via == Transport.BLE) ble else wifi
        t.send(frame)
    }

    fun disconnect() {
        wifi.disconnect()
        ble.disconnect()
        state = State.Idle
    }

    private fun wireObservers() {
        wifi.onHostsChanged = { lastWifi = it; onHostsChanged?.invoke(lastWifi + lastBle) }
        ble.onHostsChanged  = { lastBle  = it; onHostsChanged?.invoke(lastWifi + lastBle) }
        wifi.onFrame = { onFrame?.invoke(it) }
        ble.onFrame  = { onFrame?.invoke(it) }
        wifi.onPeerConnected = { state = State.Connected(it, Transport.WIFI) }
        ble.onPeerConnected  = { state = State.Connected(it, Transport.BLE) }
        wifi.onDisconnected = { state = State.Idle }
        ble.onDisconnected  = { state = State.Idle }
    }

    class NotConnectedException : RuntimeException("not connected")
}
