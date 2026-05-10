package com.americangroupllc.pocket.core.clock

/**
 * AlarmRepository — interface only here in :core (no Android storage deps).
 * The :app module wires a Room-backed implementation; tests can use
 * InMemoryAlarmRepository.
 */
interface AlarmRepository {
    suspend fun all(): List<Alarm>
    suspend fun upsert(alarm: Alarm)
    suspend fun delete(id: String)
}

class InMemoryAlarmRepository(initial: List<Alarm> = emptyList()) : AlarmRepository {
    private val byId: MutableMap<String, Alarm> = initial.associateBy { it.id }.toMutableMap()
    override suspend fun all(): List<Alarm> = byId.values.sortedWith(compareBy({ it.hour }, { it.minute }))
    override suspend fun upsert(alarm: Alarm) { byId[alarm.id] = alarm }
    override suspend fun delete(id: String) { byId.remove(id) }
}
