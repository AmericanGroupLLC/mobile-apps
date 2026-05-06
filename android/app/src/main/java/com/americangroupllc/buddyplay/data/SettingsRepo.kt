package com.americangroupllc.buddyplay.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.americangroupllc.buddyplay.core.connectivity.ConnectivityBridge
import com.americangroupllc.buddyplay.core.models.GameKind
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore by preferencesDataStore("buddyplay.settings")

@Singleton
class SettingsRepo @Inject constructor(@ApplicationContext private val ctx: Context) {

    private object Keys {
        val displayName    = stringPreferencesKey("displayName")
        val defaultGame    = stringPreferencesKey("defaultGame")
        val connectivity   = stringPreferencesKey("connectivity")
        val theme          = stringPreferencesKey("theme")
        val sound          = booleanPreferencesKey("sound")
        val haptics        = booleanPreferencesKey("haptics")
    }

    val displayName: Flow<String> = ctx.dataStore.data.map { it[Keys.displayName] ?: "Player" }

    val defaultGame: Flow<GameKind> = ctx.dataStore.data.map {
        runCatching { GameKind.valueOf(it[Keys.defaultGame] ?: "CHESS") }.getOrDefault(GameKind.CHESS)
    }

    val connectivityPreference: Flow<ConnectivityBridge.Preference> = ctx.dataStore.data.map {
        runCatching { ConnectivityBridge.Preference.valueOf(it[Keys.connectivity] ?: "AUTO") }
            .getOrDefault(ConnectivityBridge.Preference.AUTO)
    }

    val theme: Flow<String>   = ctx.dataStore.data.map { it[Keys.theme] ?: "system" }
    val soundEnabled: Flow<Boolean>   = ctx.dataStore.data.map { it[Keys.sound] ?: true }
    val hapticsEnabled: Flow<Boolean> = ctx.dataStore.data.map { it[Keys.haptics] ?: true }

    suspend fun setDisplayName(name: String) =
        ctx.dataStore.edit { it[Keys.displayName] = name }

    suspend fun setDefaultGame(kind: GameKind) =
        ctx.dataStore.edit { it[Keys.defaultGame] = kind.name }

    suspend fun setConnectivityPreference(p: ConnectivityBridge.Preference) =
        ctx.dataStore.edit { it[Keys.connectivity] = p.name }

    suspend fun setTheme(t: String) =
        ctx.dataStore.edit { it[Keys.theme] = t }

    suspend fun setSoundEnabled(enabled: Boolean) =
        ctx.dataStore.edit { it[Keys.sound] = enabled }

    suspend fun setHapticsEnabled(enabled: Boolean) =
        ctx.dataStore.edit { it[Keys.haptics] = enabled }
}
