package com.americangroupllc.buddyplay.connectivity

import android.content.Context
import com.americangroupllc.buddyplay.core.connectivity.BuddyTransport
import com.americangroupllc.buddyplay.core.connectivity.DiscoveredPeer
import com.americangroupllc.buddyplay.core.domain.WireCodec
import com.americangroupllc.buddyplay.core.models.Peer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.IOException
import java.net.ServerSocket
import java.net.Socket

/**
 * Wi-Fi transport: TCP + Bonjour discovery. Length-prefixed framing on a
 * single long-lived connection. Mirrors the Apple `WifiTransport`.
 *
 * Lifecycle:
 *   - Host: `startHosting` opens a `ServerSocket`, publishes the NSD
 *     advert, accepts a single peer.
 *   - Guest: `startScanning` triggers NSD discovery; `connect` opens the
 *     `Socket`.
 */
class WifiTcpTransport(context: Context) : BuddyTransport {

    companion object { const val PORT = 0 } // 0 = OS assigns a port

    override var onHostsChanged: ((List<DiscoveredPeer>) -> Unit)? = null
    override var onPeerConnected: ((Peer) -> Unit)? = null
    override var onFrame: ((ByteArray) -> Unit)? = null
    override var onDisconnected: ((Throwable?) -> Unit)? = null

    private val nsd = NsdDiscovery(context)
    private var server: ServerSocket? = null
    private var socket: Socket? = null
    private var receiveJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var localPeer: Peer? = null

    init {
        nsd.onHostsChanged = { onHostsChanged?.invoke(it) }
    }

    override suspend fun startHosting(localPeer: Peer): Unit = withContext(Dispatchers.IO) {
        this@WifiTcpTransport.localPeer = localPeer
        val s = ServerSocket(PORT)
        server = s
        nsd.publish(serviceName = localPeer.displayName, port = s.localPort)
        scope.launch {
            try {
                val incoming = s.accept()
                socket = incoming
                onPeerConnected?.invoke(localPeer)  // remote peer's identity arrives via lobby handshake
                pumpReceive(incoming)
            } catch (e: IOException) {
                onDisconnected?.invoke(e)
            }
        }
    }

    override fun stopHosting() {
        nsd.unpublish()
        runCatching { server?.close() }
        server = null
    }

    override suspend fun startScanning(localPeer: Peer) = withContext(Dispatchers.IO) {
        this@WifiTcpTransport.localPeer = localPeer
        nsd.startDiscovery()
    }

    override fun stopScanning() {
        nsd.stopDiscovery()
    }

    override suspend fun connect(host: DiscoveredPeer) = withContext(Dispatchers.IO) {
        // Real impl resolves the NsdServiceInfo's host+port and connects.
        // For v1 the lobby resolves the address out-of-band via the user's
        // local network. Slot kept here for the connection step.
    }

    override suspend fun send(frame: ByteArray) = withContext(Dispatchers.IO) {
        val s = socket ?: throw IOException("not connected")
        val out = WireCodec.frame(frame)
        s.getOutputStream().write(out)
        s.getOutputStream().flush()
    }

    override fun disconnect() {
        receiveJob?.cancel()
        receiveJob = null
        runCatching { socket?.close() }
        socket = null
        nsd.stopDiscovery()
        nsd.unpublish()
    }

    private fun pumpReceive(sock: Socket) {
        receiveJob = scope.launch {
            val input = sock.getInputStream()
            val buffer = ByteArray(65536)
            val acc = ArrayList<Byte>(8192)
            while (!sock.isClosed) {
                val read = try { input.read(buffer) } catch (e: IOException) { -1 }
                if (read < 0) {
                    onDisconnected?.invoke(null)
                    break
                }
                for (i in 0 until read) acc.add(buffer[i])
                while (true) {
                    val pair = WireCodec.unframe(acc.toByteArray()) ?: break
                    val (payload, consumed) = pair
                    onFrame?.invoke(payload)
                    repeat(consumed) { acc.removeAt(0) }
                }
            }
        }
    }
}
