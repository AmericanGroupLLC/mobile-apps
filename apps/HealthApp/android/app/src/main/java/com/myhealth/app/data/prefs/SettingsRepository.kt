package com.myhealth.app.data.prefs

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore("myhealth_settings")

@Singleton
class SettingsRepository @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private object Keys {
        val DID_ONBOARD = booleanPreferencesKey("did_onboard")
        val THEME_MODE = stringPreferencesKey("theme_mode")
        val LANGUAGE = stringPreferencesKey("language")
        val UNITS_IMPERIAL = booleanPreferencesKey("units_imperial")
        val API_BASE_URL = stringPreferencesKey("api_base_url")
        val IS_GUEST = booleanPreferencesKey("is_guest")
        // Set of HealthCondition.name values the user has declared. Mirrors
        // iOS HealthConditionsStore (storageKey = "healthConditions.v1") in
        // intent: on-device only, never sent off-device.
        val HEALTH_CONDITIONS = stringSetPreferencesKey("health_conditions_v1")
    }

    val didOnboard: Flow<Boolean> = context.dataStore.data.map { it[Keys.DID_ONBOARD] ?: false }
    val themeMode: Flow<String> = context.dataStore.data.map { it[Keys.THEME_MODE] ?: "system" }
    val language: Flow<String> = context.dataStore.data.map { it[Keys.LANGUAGE] ?: "en" }
    val unitsImperial: Flow<Boolean> = context.dataStore.data.map { it[Keys.UNITS_IMPERIAL] ?: false }
    val apiBaseURL: Flow<String> = context.dataStore.data.map { it[Keys.API_BASE_URL] ?: "" }
    val isGuest: Flow<Boolean> = context.dataStore.data.map { it[Keys.IS_GUEST] ?: true }
    val healthConditions: Flow<Set<String>> = context.dataStore.data.map {
        it[Keys.HEALTH_CONDITIONS] ?: setOf("none")
    }

    suspend fun setDidOnboard(v: Boolean) = context.dataStore.edit { it[Keys.DID_ONBOARD] = v }
    suspend fun setThemeMode(v: String) = context.dataStore.edit { it[Keys.THEME_MODE] = v }
    suspend fun setLanguage(v: String) = context.dataStore.edit { it[Keys.LANGUAGE] = v }
    suspend fun setUnitsImperial(v: Boolean) = context.dataStore.edit { it[Keys.UNITS_IMPERIAL] = v }
    suspend fun setApiBaseURL(v: String) = context.dataStore.edit { it[Keys.API_BASE_URL] = v }
    suspend fun setGuest(v: Boolean) = context.dataStore.edit { it[Keys.IS_GUEST] = v }
    suspend fun setHealthConditions(v: Set<String>) =
        context.dataStore.edit { it[Keys.HEALTH_CONDITIONS] = v }
}
