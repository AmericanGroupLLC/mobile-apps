package com.myhealth.app.data.secure

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * PHI-grade secret store backed by [EncryptedSharedPreferences] (AES-256-GCM
 * for values, AES-256-SIV for keys; master key in the Android Keystore).
 *
 * Use this for OAuth tokens (JWT, FHIR access/refresh), insurance card OCR
 * raw text, and any other small secret. Do NOT use the regular DataStore
 * (`SettingsRepository`) — DataStore writes plaintext to
 * `/data/data/com.myhealth.app/files/datastore/`.
 *
 * One file per "issuer" — auth backend, Epic sandbox, etc. — keeps blast
 * radius of a corrupted store small (a single file rebuild instead of all
 * tokens being lost).
 */
@Singleton
class SecureTokenStore @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    companion object {
        const val FILE_AUTH = "myhealth_secure_auth"
        const val FILE_FHIR = "myhealth_secure_fhir"
        const val FILE_INSURANCE = "myhealth_secure_insurance"

        const val KEY_JWT = "jwt"
        const val KEY_FHIR_ACCESS_TOKEN_PREFIX = "access_token."
        const val KEY_FHIR_REFRESH_TOKEN_PREFIX = "refresh_token."
        const val KEY_FHIR_EXPIRES_AT_PREFIX = "expires_at."

        private const val TAG = "SecureTokenStore"
    }

    private val masterKey: MasterKey by lazy {
        MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
    }

    private fun open(file: String): SharedPreferences = try {
        EncryptedSharedPreferences.create(
            context,
            file,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    } catch (e: Exception) {
        // EncryptedSharedPreferences will throw if the keystore-backed master
        // key was rotated (e.g. after a device PIN reset). Wipe and re-create
        // so the user can re-auth instead of crashing.
        Log.w(TAG, "EncryptedSharedPreferences open failed for $file; wiping and retrying.", e)
        context.deleteSharedPreferences(file)
        EncryptedSharedPreferences.create(
            context, file, masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    private val authPrefs by lazy { open(FILE_AUTH) }
    private val fhirPrefs by lazy { open(FILE_FHIR) }
    private val insurancePrefs by lazy { open(FILE_INSURANCE) }

    // ─── Backend JWT ────────────────────────────────────────────────────────

    var jwt: String?
        get() = authPrefs.getString(KEY_JWT, null)
        set(value) {
            authPrefs.edit().apply {
                if (value == null) remove(KEY_JWT) else putString(KEY_JWT, value)
            }.apply()
        }

    fun clearJwt() { jwt = null }

    // ─── FHIR (per-issuer) ──────────────────────────────────────────────────

    fun setFhirTokens(issuer: String, accessToken: String, refreshToken: String?, expiresAtEpochMillis: Long?) {
        fhirPrefs.edit().apply {
            putString(KEY_FHIR_ACCESS_TOKEN_PREFIX + issuer, accessToken)
            if (refreshToken != null) putString(KEY_FHIR_REFRESH_TOKEN_PREFIX + issuer, refreshToken)
            if (expiresAtEpochMillis != null) putLong(KEY_FHIR_EXPIRES_AT_PREFIX + issuer, expiresAtEpochMillis)
        }.apply()
    }

    fun fhirAccessToken(issuer: String): String? =
        fhirPrefs.getString(KEY_FHIR_ACCESS_TOKEN_PREFIX + issuer, null)

    fun fhirRefreshToken(issuer: String): String? =
        fhirPrefs.getString(KEY_FHIR_REFRESH_TOKEN_PREFIX + issuer, null)

    fun fhirExpiresAt(issuer: String): Long? =
        if (fhirPrefs.contains(KEY_FHIR_EXPIRES_AT_PREFIX + issuer))
            fhirPrefs.getLong(KEY_FHIR_EXPIRES_AT_PREFIX + issuer, 0L)
        else null

    fun clearFhir(issuer: String) {
        fhirPrefs.edit().apply {
            remove(KEY_FHIR_ACCESS_TOKEN_PREFIX + issuer)
            remove(KEY_FHIR_REFRESH_TOKEN_PREFIX + issuer)
            remove(KEY_FHIR_EXPIRES_AT_PREFIX + issuer)
        }.apply()
    }

    // ─── Insurance card raw OCR (sensitive) ─────────────────────────────────
    //
    // Stored encrypted because raw OCR text often includes the full member
    // ID, group #, and BIN/PCN. Parsed structured fields go into the Room
    // PHI database via `InsuranceCardEntity`.

    fun setInsuranceRawText(text: String) {
        insurancePrefs.edit().putString("raw_text", text).apply()
    }
    fun insuranceRawText(): String? = insurancePrefs.getString("raw_text", null)
    fun clearInsurance() { insurancePrefs.edit().clear().apply() }
}
