package com.americangroupllc.offlineaibuddy.onboarding

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.onboardingDataStore: DataStore<Preferences> by preferencesDataStore(
    name = "onboarding_prefs",
)

/**
 * Tiny wrapper around the onboarding DataStore. Persists a single
 * boolean — whether the user has finished the consent → profile →
 * model-download → permissions flow. RootNav reads this on startup to
 * decide whether to land on `consent` or `home`.
 */
object OnboardingPrefs {
    private val KEY_COMPLETE = booleanPreferencesKey("onboarding_complete")

    fun completedFlow(context: Context): Flow<Boolean> =
        context.applicationContext.onboardingDataStore.data.map { prefs ->
            prefs[KEY_COMPLETE] ?: false
        }

    suspend fun setCompleted(context: Context, completed: Boolean) {
        context.applicationContext.onboardingDataStore.edit { prefs ->
            prefs[KEY_COMPLETE] = completed
        }
    }
}
