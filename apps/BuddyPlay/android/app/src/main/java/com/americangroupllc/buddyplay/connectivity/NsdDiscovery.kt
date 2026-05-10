package com.americangroupllc.buddyplay.connectivity

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import com.americangroupllc.buddyplay.core.connectivity.DiscoveredPeer
import com.americangroupllc.buddyplay.core.models.Transport

/**
 * Bonjour / NSD scan + advertise on `_buddyplay._tcp`. Used by
 * `WifiTcpTransport` to discover peers without an internet round-trip.
 *
 * Both peers should publish-then-scan with a ~1 s debounce — see
 * `CONNECTIVITY.md §3` for why.
 */
class NsdDiscovery(context: Context) {

    companion object {
        const val SERVICE_TYPE = "_buddyplay._tcp."
    }

    private val nsd = context.getSystemService(Context.NSD_SERVICE) as NsdManager

    private var registrationListener: NsdManager.RegistrationListener? = null
    private var discoveryListener: NsdManager.DiscoveryListener? = null

    private val discovered = LinkedHashMap<String, DiscoveredPeer>()
    var onHostsChanged: ((List<DiscoveredPeer>) -> Unit)? = null

    fun publish(serviceName: String, port: Int) {
        val info = NsdServiceInfo().apply {
            this.serviceName = serviceName
            this.serviceType = SERVICE_TYPE
            this.port = port
        }
        val l = object : NsdManager.RegistrationListener {
            override fun onServiceRegistered(serviceInfo: NsdServiceInfo) {}
            override fun onRegistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {}
            override fun onServiceUnregistered(serviceInfo: NsdServiceInfo) {}
            override fun onUnregistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {}
        }
        registrationListener = l
        nsd.registerService(info, NsdManager.PROTOCOL_DNS_SD, l)
    }

    fun unpublish() {
        registrationListener?.let { runCatching { nsd.unregisterService(it) } }
        registrationListener = null
    }

    fun startDiscovery() {
        val l = object : NsdManager.DiscoveryListener {
            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {}
            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {}
            override fun onDiscoveryStarted(serviceType: String) {}
            override fun onDiscoveryStopped(serviceType: String) {}
            override fun onServiceFound(serviceInfo: NsdServiceInfo) {
                val key = serviceInfo.serviceName
                discovered[key] = DiscoveredPeer(
                    id = key, peerId = null,
                    displayName = serviceInfo.serviceName,
                    transport = Transport.WIFI,
                )
                onHostsChanged?.invoke(discovered.values.toList())
            }
            override fun onServiceLost(serviceInfo: NsdServiceInfo) {
                discovered.remove(serviceInfo.serviceName)
                onHostsChanged?.invoke(discovered.values.toList())
            }
        }
        discoveryListener = l
        nsd.discoverServices(SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, l)
    }

    fun stopDiscovery() {
        discoveryListener?.let { runCatching { nsd.stopServiceDiscovery(it) } }
        discoveryListener = null
        discovered.clear()
    }
}
