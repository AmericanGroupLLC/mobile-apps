package com.americangroupllc.buddyplay.core.connectivity

import com.americangroupllc.buddyplay.core.models.Peer
import com.americangroupllc.buddyplay.core.models.Transport

/**
 * The transport-agnostic interface every connectivity adapter implements.
 * The Android `:app` module provides `WifiTcpTransport` and `BleTransport`
 * implementations; this interface is what the bridge wires together.
 */
interface BuddyTransport {
    suspend fun startHosting(localPeer: Peer)
    fun stopHosting()

    suspend fun startScanning(localPeer: Peer)
    fun stopScanning()

    suspend fun connect(host: DiscoveredPeer)

    suspend fun send(frame: ByteArray)

    fun disconnect()

    var onHostsChanged: ((List<DiscoveredPeer>) -> Unit)?
    var onPeerConnected: ((Peer) -> Unit)?
    var onFrame: ((ByteArray) -> Unit)?
    var onDisconnected: ((Throwable?) -> Unit)?
}

/**
 * A peer that the local discovery layer has surfaced but not yet connected
 * to. [peerId] is parsed from the host's advertised metadata.
 */
data class DiscoveredPeer(
    val id: String,
    val peerId: String?,
    val displayName: String,
    val transport: Transport,
)
