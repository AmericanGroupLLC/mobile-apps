package com.americangroupllc.buddyplay.connectivity

import android.content.Context
import com.americangroupllc.buddyplay.core.connectivity.BuddyTransport
import com.americangroupllc.buddyplay.core.connectivity.DiscoveredPeer
import com.americangroupllc.buddyplay.core.models.Peer

/**
 * BLE GATT transport for Android. Mirrors the iOS `BleTransport`.
 *
 * Service UUID: `42554450-0000-1000-8000-00805F9B34FB` (BUDP).
 * Inbound  characteristic: `42554450-0001-...` (write-without-response).
 * Outbound characteristic: `42554450-0002-...` (notify).
 *
 * v1 ships the contract + scaffold so the Connect screen can fall back
 * gracefully. The full `BluetoothGattServer` / `BluetoothLeScanner` wiring
 * is straightforward but verbose; the Wi-Fi path covers the typical case
 * and BLE is the deep-fallback. Phase 9.x will fill in the delegate
 * plumbing for the BLE-only test scenario.
 */
class BleTransport(context: Context) : BuddyTransport {

    companion object {
        const val SERVICE_UUID  = "42554450-0000-1000-8000-00805F9B34FB"
        const val INBOUND_UUID  = "42554450-0001-1000-8000-00805F9B34FB"
        const val OUTBOUND_UUID = "42554450-0002-1000-8000-00805F9B34FB"
    }

    override var onHostsChanged: ((List<DiscoveredPeer>) -> Unit)? = null
    override var onPeerConnected: ((Peer) -> Unit)? = null
    override var onFrame: ((ByteArray) -> Unit)? = null
    override var onDisconnected: ((Throwable?) -> Unit)? = null

    override suspend fun startHosting(localPeer: Peer) {
        // BluetoothManager + BluetoothGattServer setup lands together with
        // the BLE-only smoke scenario. Until then, BLE is silently a no-op
        // fallback — Wi-Fi picks up the call.
    }

    override fun stopHosting() {}

    override suspend fun startScanning(localPeer: Peer) {
        // BluetoothLeScanner.startScan(filter on SERVICE_UUID).
    }

    override fun stopScanning() {}

    override suspend fun connect(host: DiscoveredPeer) {
        // BluetoothDevice.connectGatt(...).
    }

    override suspend fun send(frame: ByteArray) {
        // Chunk into MTU-sized writes, write to INBOUND_UUID.
    }

    override fun disconnect() {}
}
