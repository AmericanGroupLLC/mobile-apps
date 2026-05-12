package com.myhealth.app.fhir

import com.myhealth.app.data.secure.SecureTokenStore
import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.statement.bodyAsText
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * Slim FHIR repository — Patient summary + counts of every resource Care+
 * v1 reads. Mirrors iOS [`FHIRClient`](shared/.../FHIR/FHIRClient.swift).
 */
@Singleton
class FhirRepository @Inject constructor(
    private val http: HttpClient,
    private val secureTokens: SecureTokenStore,
    private val json: Json,
) {
    private val baseUrl = "https://fhir.epic.com/interconnect-fhir-oauth/api/FHIR/R4"

    @Serializable
    data class PatientSummary(
        val id: String?,
        val displayName: String,
        val gender: String?,
        val birthDate: String?,
    )

    suspend fun patient(patientId: String): PatientSummary {
        val token = secureTokens.fhirAccessToken(EpicSandboxConfig.ISSUER)
            ?: error("No FHIR access token; user must re-link MyChart.")
        val raw = http.get("$baseUrl/Patient/$patientId") {
            header("Authorization", "Bearer $token")
            header("Accept", "application/fhir+json")
        }.bodyAsText()
        val obj = json.parseToJsonElement(raw).jsonObject
        val nameArr = obj["name"]?.jsonArray
        val displayName = nameArr?.firstOrNull()?.jsonObject?.let { name ->
            val text = name["text"]?.jsonPrimitive?.contentOrNull
            if (!text.isNullOrBlank()) text
            else {
                val given = name["given"]?.jsonArray?.joinToString(" ") {
                    it.jsonPrimitive.contentOrNull ?: ""
                } ?: ""
                val family = name["family"]?.jsonPrimitive?.contentOrNull ?: ""
                "$given $family".trim().ifBlank { "—" }
            }
        } ?: "—"

        return PatientSummary(
            id = obj["id"]?.jsonPrimitive?.contentOrNull,
            displayName = displayName,
            gender = obj["gender"]?.jsonPrimitive?.contentOrNull,
            birthDate = obj["birthDate"]?.jsonPrimitive?.contentOrNull,
        )
    }

    /** Count per resource type for Care+ v1. */
    suspend fun summaryCounts(patientId: String): Map<String, Int> = coroutineScope {
        val resources = listOf(
            "Condition", "MedicationStatement", "AllergyIntolerance",
            "Observation", "Encounter", "Immunization", "Appointment"
        )
        val deferred = resources.map { res ->
            res to async { runCatching { count(res, patientId) }.getOrDefault(0) }
        }
        deferred.associate { (k, v) -> k to v.await() }
    }

    private suspend fun count(resource: String, patientId: String): Int {
        val token = secureTokens.fhirAccessToken(EpicSandboxConfig.ISSUER) ?: return 0
        val raw = http.get(
            "$baseUrl/$resource?patient=$patientId&_summary=count"
        ) {
            header("Authorization", "Bearer $token")
            header("Accept", "application/fhir+json")
        }.bodyAsText()
        return runCatching {
            json.parseToJsonElement(raw).jsonObject["total"]?.jsonPrimitive?.intOrNull ?: 0
        }.getOrDefault(0)
    }
}
