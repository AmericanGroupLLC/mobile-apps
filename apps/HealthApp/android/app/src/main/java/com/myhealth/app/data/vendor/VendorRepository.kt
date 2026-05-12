package com.myhealth.app.data.vendor

import com.myhealth.app.network.ApiBaseUrl
import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * Vendor (meal-delivery) repository. Calls the backend `/api/vendor/menu`
 * endpoint. See iOS [shared/.../Vendor/VendorClient.swift].
 */
@Singleton
class VendorRepository @Inject constructor(
    private val http: HttpClient,
    private val json: Json,
    private val apiBaseUrl: ApiBaseUrl,
) {
    @Serializable
    data class Vendor(
        val id: String,
        val name: String,
        val cuisine: String? = null,
        val calories_per_meal_avg: Int? = null,
        val supports_conditions: List<String>? = null,
        val blurb: String? = null,
    )

    @Serializable
    private data class MenuResponse(val vendors: List<Vendor>)

    suspend fun menu(conditions: List<String>): List<Vendor> {
        val q = conditions.joinToString(",")
        val url = "${apiBaseUrl.value}/api/vendor/menu?conditions=$q"
        val raw = http.get(url).bodyAsText()
        return json.decodeFromString(MenuResponse.serializer(), raw).vendors
    }
}
