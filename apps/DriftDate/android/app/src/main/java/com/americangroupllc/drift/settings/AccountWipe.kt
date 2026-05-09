package com.americangroupllc.drift.settings

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.americangroupllc.drift.core.networking.SupabaseClient
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Erase-all-data orchestrator. Mirrors the iOS Account → Erase all data
 * flow:
 *
 *   1. POST /functions/v1/wipe-me with the user's JWT
 *   2. Clear every local DataStore (auth tokens, push tokens, prefs)
 *   3. Forget the in-memory JWT on the SupabaseClient (== sign-out)
 *
 * The caller (SettingsScreen) handles step 4 — navigating back to the
 * onboarding root — once this returns success.
 */
object AccountWipe {

    private val Context.authStore by preferencesDataStore(name = "drift_auth")
    private val Context.pushStore by preferencesDataStore(name = "drift_push")
    private val Context.prefStore by preferencesDataStore(name = "drift_prefs")

    val JWT_KEY = stringPreferencesKey("supabase_jwt")

    /**
     * Provider hook so a future Hilt-injected client can replace the
     * default. Keeps this object testable without dragging Hilt into
     * the unit-test classpath.
     */
    @Volatile
    var clientProvider: () -> SupabaseClient = {
        val url  = System.getenv("SUPABASE_URL")     ?: "http://10.0.2.2:54321"
        val anon = System.getenv("SUPABASE_ANON_KEY") ?: "anon-local"
        SupabaseClient(baseUrl = url, anonKey = anon)
    }

    suspend fun wipe(context: Context): Result<Unit> = withContext(Dispatchers.IO) {
        val client = clientProvider()
        try {
            // SupabaseClient pulls the JWT from its own setJwt(); when
            // that's null it falls back to the anon key. The auth
            // session manager (real impl in the iOS Auth feature) is
            // expected to have called setJwt() on sign-in. We pass an
            // empty body — wipe-me ignores it.
            val resp = client.invokeFunction("wipe-me", emptyMap<String, String>())
            if (!resp.status.isSuccessSafely()) {
                val body = runCatching { resp.bodyAsText() }.getOrDefault("")
                return@withContext Result.failure(
                    RuntimeException("wipe-me HTTP ${resp.status.value}: $body")
                )
            }

            // Wipe local stores. Any one failure shouldn't block the
            // others — the user is leaving.
            runCatching { context.authStore.edit { it.clear() } }
            runCatching { context.pushStore.edit { it.clear() } }
            runCatching { context.prefStore.edit { it.clear() } }

            // Drop the JWT from the in-memory client (== sign-out).
            client.setJwt(null)

            Result.success(Unit)
        } catch (t: Throwable) {
            Result.failure(t)
        } finally {
            runCatching { client.close() }
        }
    }

    private fun HttpStatusCode.isSuccessSafely() = value in 200..299
}
