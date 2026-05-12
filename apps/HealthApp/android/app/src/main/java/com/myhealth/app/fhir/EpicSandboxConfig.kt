package com.myhealth.app.fhir

/**
 * SMART-on-FHIR (Epic sandbox) configuration. Mirrors iOS
 * `EpicSandboxConfig.swift` — keep the two in sync. Production credentials
 * (different client_id, real BAA) follow App Orchard approval.
 */
object EpicSandboxConfig {
    const val ISSUER = "https://fhir.epic.com/interconnect-fhir-oauth"
    const val AUTH_ENDPOINT = "https://fhir.epic.com/interconnect-fhir-oauth/oauth2/authorize"
    const val TOKEN_ENDPOINT = "https://fhir.epic.com/interconnect-fhir-oauth/oauth2/token"
    const val CLIENT_ID = "d68b5f02-aae7-4b3a-9b10-a37a4c0a8c40" // sandbox-only
    const val REDIRECT_URI = "myhealth://oauth/fhir/callback"

    val SCOPES = listOf(
        "patient/Patient.read",
        "patient/Condition.read",
        "patient/MedicationStatement.read",
        "patient/AllergyIntolerance.read",
        "patient/Observation.read",
        "patient/Encounter.read",
        "patient/Immunization.read",
        "patient/Appointment.read",
        "launch/patient",
        "openid",
        "fhirUser",
        "offline_access",
    )
    val SCOPE_STRING = SCOPES.joinToString(" ")

    /** Sandbox patients documented at https://fhir.epic.com/Documentation?docId=testpatients */
    val SANDBOX_PATIENTS = listOf(
        "Camila Lopez (general) — fhircamila / epicepic1",
        "Derrick Lin (cardio)   — fhirderrick / epicepic1",
        "Desiree Powell (peds)  — fhirdesiree / epicepic1",
    )
}
