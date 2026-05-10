package com.americangroupllc.drift.core.networking

import com.google.common.truth.Truth.assertThat
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import io.ktor.utils.io.ByteReadChannel
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import org.junit.Test

class SupabaseClientTest {

    @Serializable data class StubBody(val foo: String)

    @Test fun `request uses bearer of jwt when set, else anon key`() {
        var lastAuth: String? = null
        val engine = MockEngine { req ->
            lastAuth = req.headers["Authorization"]
            respond(content = ByteReadChannel("{}"),
                status  = HttpStatusCode.OK,
                headers = headersOf("Content-Type", "application/json"))
        }
        val client = SupabaseClient("http://localhost:54321/", anonKey = "anon-key", engine = engine)

        runBlocking { client.postJson("functions/v1/reply-suggest", StubBody("bar")) }
        assertThat(lastAuth).isEqualTo("Bearer anon-key")

        client.setJwt("jwt-token")
        runBlocking { client.postJson("functions/v1/reply-suggest", StubBody("bar")) }
        assertThat(lastAuth).isEqualTo("Bearer jwt-token")

        client.close()
    }

    @Test fun `apikey header is always present`() {
        var lastApiKey: String? = null
        val engine = MockEngine { req ->
            lastApiKey = req.headers["apikey"]
            respond(ByteReadChannel("{}"), HttpStatusCode.OK,
                headers = headersOf("Content-Type", "application/json"))
        }
        val client = SupabaseClient("http://localhost:54321/", anonKey = "anon-key", engine = engine)
        runBlocking { client.invokeFunction("reply-suggest", StubBody("z")) }
        assertThat(lastApiKey).isEqualTo("anon-key")
        client.close()
    }
}
