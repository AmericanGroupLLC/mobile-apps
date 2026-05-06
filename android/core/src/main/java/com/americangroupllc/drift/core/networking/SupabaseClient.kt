package com.americangroupllc.drift.core.networking

import io.ktor.client.HttpClient
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.client.request.headers
import io.ktor.client.request.parameter
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.http.HttpStatusCode
import io.ktor.http.URLBuilder
import io.ktor.http.appendPathSegments
import io.ktor.http.contentType
import io.ktor.http.ContentType
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json

/**
 * Thin Ktor wrapper around the bits of the Supabase REST API Drift uses.
 * Mirrors the surface of `SupabaseClient.swift`.
 */
class SupabaseClient(
    val baseUrl: String,
    val anonKey: String,
    engine: HttpClientEngine = CIO.create(),
) {
    private var jwt: String? = null

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = false }

    private val client = HttpClient(engine) {
        install(ContentNegotiation) {
            json(json)
        }
        expectSuccess = false
    }

    fun setJwt(token: String?) { jwt = token }

    suspend fun rawGet(path: String, query: Map<String, String> = emptyMap()): HttpResponse =
        client.get(
            URLBuilder(baseUrl).apply {
                appendPathSegments(path.trim('/').split('/'))
                query.forEach { parameter(it.key, it.value) }
            }.build()
        ) { headers { applyHeaders(this) } }

    suspend inline fun <reified Body : Any> postJson(
        path: String, body: Body,
    ): HttpResponse = client.post(buildUrl(path)) {
        headers { applyHeaders(this) }
        contentType(ContentType.Application.Json)
        setBody(body)
    }

    suspend inline fun <reified Body : Any> invokeFunction(
        name: String, body: Body,
    ): HttpResponse = postJson("functions/v1/$name", body)

    @PublishedApi
    internal fun buildUrl(path: String): String =
        baseUrl.trimEnd('/') + "/" + path.trimStart('/')

    @PublishedApi
    internal fun applyHeaders(b: io.ktor.http.HeadersBuilder) {
        b.append("apikey", anonKey)
        b.append("Authorization", "Bearer ${jwt ?: anonKey}")
        b.append("Accept", "application/json")
    }

    fun close() { client.close() }
}

class SupabaseHttpException(val status: HttpStatusCode, val body: String) :
    RuntimeException("HTTP ${status.value}: $body")
