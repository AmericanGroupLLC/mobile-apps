package com.americangroupllc.buddyplay.core.storage

import java.util.UUID

/**
 * Stable device UUID. Generated once on first access; rotatable from
 * Settings → Reset device ID.
 *
 * `:core` declares the interface so domain code can depend on it; `:app`
 * provides the SharedPreferences-backed implementation.
 */
interface DeviceIdProvider {
    fun deviceId(): String
    fun reset(): String
}

/** In-memory test/JVM implementation. */
class InMemoryDeviceIdProvider(initial: String = UUID.randomUUID().toString()) : DeviceIdProvider {
    private var id: String = initial
    override fun deviceId(): String = id
    override fun reset(): String { id = UUID.randomUUID().toString(); return id }
}
