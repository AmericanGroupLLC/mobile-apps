package com.americangroupllc.buddyplay.connectivity

import com.americangroupllc.buddyplay.core.connectivity.BuddyTransport
import com.americangroupllc.buddyplay.core.connectivity.DiscoveredPeer
import com.americangroupllc.buddyplay.core.models.Peer

/**
 * No-op transport used as the placeholder until Phase 8 lands the real
 * Android `WifiTcpTransport` + `BleTransport`. Lets the rest of the app
 * compile + run without a connection.
 */
class NoopBuddyTransport : BuddyTransport {
    override var onHostsChanged: ((List<DiscoveredPeer>) -> Unit)? = null
    override var onPeerConnected: ((Peer) -> Unit)? = null
    override var onFrame: ((ByteArray) -> Unit)? = null
    override var onDisconnected: ((Throwable?) -> Unit)? = null

    override suspend fun startHosting(localPeer: Peer) {}
    override fun stopHosting() {}
    override suspend fun startScanning(localPeer: Peer) {}
    override fun stopScanning() {}
    override suspend fun connect(host: DiscoveredPeer) {}
    override suspend fun send(frame: ByteArray) {}
    override fun disconnect() {}
}
