package com.myhealth.app.fhir

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContract
import com.myhealth.app.data.secure.SecureTokenStore
import dagger.hilt.android.qualifiers.ApplicationContext
import io.ktor.client.HttpClient
import io.ktor.client.request.forms.FormDataContent
import io.ktor.client.request.post
import io.ktor.client.statement.bodyAsText
import io.ktor.http.Parameters
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import net.openid.appauth.AuthorizationRequest
import net.openid.appauth.AuthorizationResponse
import net.openid.appauth.AuthorizationService
import net.openid.appauth.AuthorizationServiceConfiguration
import net.openid.appauth.ResponseTypeValues

/**
 * SMART-on-FHIR PKCE OAuth client backed by AppAuth-Android + Custom Tabs.
 * Mirrors iOS [`FHIROAuthClient`](shared/.../FHIR/FHIROAuthClient.swift).
 *
 * Tokens land in [SecureTokenStore] (EncryptedSharedPreferences).
 */
@Singleton
class FhirOAuthClient @Inject constructor(
    @ApplicationContext private val context: Context,
    private val secureTokens: SecureTokenStore,
    private val http: HttpClient,
    private val json: Json,
) {

    @Serializable
    data class TokenResponse(
        val access_token: String,
        val refresh_token: String? = null,
        val expires_in: Int? = null,
        val patient: String? = null,
        val scope: String? = null,
    )

    private val serviceConfig: AuthorizationServiceConfiguration =
        AuthorizationServiceConfiguration(
            Uri.parse(EpicSandboxConfig.AUTH_ENDPOINT),
            Uri.parse(EpicSandboxConfig.TOKEN_ENDPOINT),
        )

    /** Build the AppAuth `AuthorizationRequest` for the Epic sandbox. */
    fun buildAuthRequest(): AuthorizationRequest {
        return AuthorizationRequest.Builder(
            serviceConfig,
            EpicSandboxConfig.CLIENT_ID,
            ResponseTypeValues.CODE,
            Uri.parse(EpicSandboxConfig.REDIRECT_URI),
        )
            .setScopes(EpicSandboxConfig.SCOPES)
            .setAdditionalParameters(mapOf("aud" to EpicSandboxConfig.ISSUER))
            .build()
    }

    /**
     * Exchange the authorization code for tokens. Persists into the secure
     * store under [EpicSandboxConfig.ISSUER].
     */
    suspend fun exchangeCode(authResponse: AuthorizationResponse): TokenResponse {
        val codeVerifier = authResponse.request.codeVerifier
        val tokenRequestParams = Parameters.build {
            append("grant_type", "authorization_code")
            append("code", authResponse.authorizationCode ?: "")
            append("redirect_uri", EpicSandboxConfig.REDIRECT_URI)
            append("client_id", EpicSandboxConfig.CLIENT_ID)
            if (codeVerifier != null) append("code_verifier", codeVerifier)
        }
        val raw = http.post(EpicSandboxConfig.TOKEN_ENDPOINT) {
            setBody(FormDataContent(tokenRequestParams))
        }.bodyAsText()
        val parsed = json.decodeFromString(TokenResponse.serializer(), raw)
        secureTokens.setFhirTokens(
            issuer = EpicSandboxConfig.ISSUER,
            accessToken = parsed.access_token,
            refreshToken = parsed.refresh_token,
            expiresAtEpochMillis = parsed.expires_in?.let { System.currentTimeMillis() + it * 1000L }
        )
        return parsed
    }

    fun authorizationService() = AuthorizationService(context)
}

/** Convenience wrapper around AppAuth's `getAuthorizationRequestIntent`. */
fun AuthorizationService.intentFor(req: AuthorizationRequest): Intent =
    getAuthorizationRequestIntent(req)
