package com.americangroupllc.buddyplay.connectivity

import android.content.Context
import androidx.core.content.edit
import com.americangroupllc.buddyplay.core.storage.DeviceIdProvider
import java.util.UUID

/**
 * SharedPreferences-backed stable device UUID. Generated once on first
 * launch; rotatable from Settings → Reset device ID.
 */
class AndroidDeviceIdProvider(context: Context) : DeviceIdProvider {

    companion object {
        const val PREFS = "buddyplay.device"
        const val KEY = "deviceId"
    }

    private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    override fun deviceId(): String {
        prefs.getString(KEY, null)?.let { return it }
        val new = UUID.randomUUID().toString()
        prefs.edit { putString(KEY, new) }
        return new
    }

    override fun reset(): String {
        val new = UUID.randomUUID().toString()
        prefs.edit { putString(KEY, new) }
        return new
    }
}
