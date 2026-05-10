package com.americangroupllc.pocket.alarm

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/** Lightweight, on-disk alarm row persisted in SharedPreferences as JSON. */
data class StoredAlarm(
    val id: String = UUID.randomUUID().toString(),
    val label: String = "Alarm",
    val hour: Int,
    val minute: Int,
    val enabled: Boolean = true
)

/**
 * Minimal SharedPreferences-backed alarm repository.
 *
 * The Compose UI is expected to call [save] whenever the alarm list changes;
 * BootReceiver re-hydrates from this store after the device reboots.
 */
class AlarmRepository(context: Context) {

    private val prefs = context.applicationContext
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun getAll(): List<StoredAlarm> {
        val raw = prefs.getString(KEY, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            buildList {
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    add(
                        StoredAlarm(
                            id = o.optString("id", UUID.randomUUID().toString()),
                            label = o.optString("label", "Alarm"),
                            hour = o.optInt("hour", 0),
                            minute = o.optInt("minute", 0),
                            enabled = o.optBoolean("enabled", true)
                        )
                    )
                }
            }
        } catch (_: Throwable) {
            emptyList()
        }
    }

    fun getEnabled(): List<StoredAlarm> = getAll().filter { it.enabled }

    fun save(alarms: List<StoredAlarm>) {
        val arr = JSONArray()
        alarms.forEach { a ->
            arr.put(
                JSONObject().apply {
                    put("id", a.id)
                    put("label", a.label)
                    put("hour", a.hour)
                    put("minute", a.minute)
                    put("enabled", a.enabled)
                }
            )
        }
        prefs.edit().putString(KEY, arr.toString()).apply()
    }

    companion object {
        private const val PREFS = "pocket_alarms"
        private const val KEY = "alarms_json"
    }
}
