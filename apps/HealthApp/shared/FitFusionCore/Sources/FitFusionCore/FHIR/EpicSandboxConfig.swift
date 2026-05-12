import Foundation

/// SMART-on-FHIR (Epic Sandbox) configuration. Hard-coded for week 1 because
/// it's a public sandbox client. Production credentials follow App Orchard
/// approval — at that point introduce a runtime config lookup that picks
/// `EpicProductionConfig` based on `Bundle.main.object(forInfoDictionaryKey:)`.
public enum EpicSandboxConfig {

    /// Epic's public sandbox FHIR base URL. Documented at
    /// https://fhir.epic.com/Documentation?docId=testpatients
    public static let issuer: String = "https://fhir.epic.com/interconnect-fhir-oauth"

    /// Authorization + token endpoints derived from the SMART
    /// configuration document at `<issuer>/.well-known/smart-configuration`.
    /// We hard-code them here so the first call doesn't require a discovery
    /// round trip; production code should fetch the well-known doc.
    public static let authorizationEndpoint: String =
        "https://fhir.epic.com/interconnect-fhir-oauth/oauth2/authorize"
    public static let tokenEndpoint: String =
        "https://fhir.epic.com/interconnect-fhir-oauth/oauth2/token"

    /// Public sandbox client ID. Safe to ship in source — Epic explicitly
    /// publishes this for testing. Production will be a per-tenant ID
    /// granted through App Orchard.
    public static let clientId: String =
        "d68b5f02-aae7-4b3a-9b10-a37a4c0a8c40"  // sandbox-only

    /// `myhealth://oauth/fhir/callback` — registered against this app's
    /// custom URL scheme in Info.plist (see `CFBundleURLSchemes`).
    public static let redirectURI: String = "myhealth://oauth/fhir/callback"

    /// SMART scopes — read-only patient data + identity. Matches the
    /// "exact-scope-list" surface on the MyChart connect screen.
    public static let scopes: [String] = [
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
    ]

    public static var scopeString: String { scopes.joined(separator: " ") }

    /// Sandbox patient set documented at
    /// https://fhir.epic.com/Documentation?docId=testpatients
    public static let sandboxPatients: [(label: String, login: String)] = [
        ("Camila Lopez (general)", "fhircamila / epicepic1"),
        ("Derrick Lin (cardio)",   "fhirderrick / epicepic1"),
        ("Desiree Powell (peds)",  "fhirdesiree / epicepic1"),
    ]
}
