package com.myhealth.app.network

import com.myhealth.app.data.prefs.SettingsRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

/**
 * Resolves the API base URL. Reads from [SettingsRepository] so the user
 * can override at runtime via Settings, falling back to the dev default.
 */
@Singleton
class ApiBaseUrl @Inject constructor(
    private val settings: SettingsRepository,
) {
    val value: String
        get() {
            val stored = runBlocking { settings.apiBaseURL.first() }
            return if (stored.isNotBlank()) stored else "http://10.0.2.2:4000" // emulator → host
        }
}

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    // ApiBaseUrl is @Singleton-annotated and constructor-injectable;
    // exposed here for clarity/discoverability.
}
