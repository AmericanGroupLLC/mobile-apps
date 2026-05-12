# Care+ — PHI privacy, security & audit policy

> **Status:** Week 1 of the Care+ 8-week MVP. Treat this document as the
> source of truth for which fields are PHI, where they may be stored, who
> can access them, and how access is audited.
>
> This sits alongside (and supersedes for any Care+ surface) the original
> consumer-fitness `PRIVACY.md` at the repo root. `PRIVACY.md` continues to
> govern the FitFusion-side fitness data (workouts, runs, sleep stages,
> mood) that was already shipping pre-Care+.

---

## 1. Scope of PHI in the Care+ surfaces

The features added in week 1 — MyChart connect, insurance card OCR, doctor
finder, vendor browse, RPE rating — bring **Protected Health Information
(PHI)** under HIPAA into the app for the first time. The fields below are
considered PHI and must follow the storage / transmission rules in
sections 2–4.

| Category | Field examples | Source |
|---|---|---|
| Patient identifiers | name, DOB, address, MRN, member ID, group #, NPI | MyChart, insurance card OCR, NPPES lookup |
| Clinical | conditions, medications, allergies, immunizations, lab observations | MyChart `Patient`/`Condition`/`MedicationStatement`/`AllergyIntolerance`/`Observation` |
| Encounters | appointment dates, encounter notes, ordering provider | MyChart `Encounter`/`Appointment` |
| Insurance | payer name, member ID, group #, BIN, PCN, RxGrp | Insurance card OCR |
| Provider | NPI, taxonomy/specialty, address, phone | NPPES (public) — only PHI when paired with a patient identifier |
| Self-reported clinical | RPE rating per workout (when joined to identity) | RPE sheet → `RPELogEntity` |

Conditions list (`HealthConditionsStore`) was already in the app pre-Care+
and remains on-device only; for week 1 we treat it as PHI for any code
path that *also* touches a real MyChart Patient record.

---

## 2. Storage rules

### iOS

* **OAuth tokens** (JWT for our backend; FHIR access + refresh tokens per
  issuer): Keychain only via `KeychainStore` — `kSecClassGenericPassword`
  with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. No iCloud
  Keychain sync, no device-restore migration. `UserDefaults` is forbidden
  for tokens — `KeychainStore.migrateLegacyJWTIfNeeded()` runs at cold
  start to evict any pre-Care+ plaintext copies.
* **PHI Core Data entities** (`InsuranceCardEntity`, `ProviderEntity`,
  `RPELogEntity`, future MyChart-derived entities): live in the secondary
  `PHIStore` persistent store (`shared/FitFusionCore/.../PHIStore.swift`)
  with `NSPersistentStoreFileProtectionKey = .complete` (data unavailable
  while device is locked). Never CloudKit-synced.
* **Insurance card raw OCR text**: Keychain (`KeychainStore.Service.insurance`)
  — never written to Core Data.

### Android

* **OAuth tokens**: `SecureTokenStore` (EncryptedSharedPreferences) — three
  files (`myhealth_secure_auth`, `myhealth_secure_fhir`,
  `myhealth_secure_insurance`). Master key in Android Keystore
  (`MasterKey.KeyScheme.AES256_GCM`). Plain DataStore
  (`SettingsRepository`) is forbidden for tokens.
* **PHI Room entities** (`InsuranceCardEntity`, `ProviderEntity`,
  `RpeLogEntity`, future MyChart-derived entities): live in
  `MyHealthPhiDatabase` (SQLCipher-backed,
  `data/secure/PhiDatabase.kt`) with passphrase derived from the Android
  Keystore master key. Backed up via the regular Room API but the
  on-disk file is encrypted at rest.
* **Insurance card raw OCR text**: EncryptedSharedPreferences
  (`SecureTokenStore.setInsuranceRawText`).

### Backend

* PHI columns (`audit_log`, `insurance_card`, `provider_favorite`,
  `rpe_log`, `mychart_issuer`) live in the same SQLite DB for week 1
  development convenience. **Production**: must move to a HIPAA-grade
  datastore behind a signed BAA before a single PHI-storing endpoint
  ships outside the staging environment (Render/Fly.io/AWS BAA review
  pending — tracked in vendor approval list).

  > **Care+ rule (added late v1.5.0):** the FHIR `patient` claim is a
  > clinical identifier and is therefore **never stored server-side**.
  > The `mychart_issuer` table records only `(user_id, issuer, display_name,
  > connected_at)`. The patient ID lives on-device in the iOS PHIStore
  > (`PHIMyChartIssuerEntity`) and the Android SQLCipher Room
  > `MyHealthPhiDatabase` (`MyChartIssuerEntity.patientId`).

### Forbidden everywhere

* Logging PHI fields to Sentry, PostHog, console, or any analytics sink.
  Crash reporters scrub HTTP bodies via existing `Sentry.beforeSend` hooks.
* Sending PHI to any third party that has not signed a BAA. NPPES is OK
  (a public registry; no patient identifier is sent — only ZIP/specialty).
  Open Food Facts / USDA FDC are OK (ingredient lookup, no PHI sent).

### On-device LLM / vision policy (v1.5.1+)

The app may load a small on-device LLM (Apple Intelligence Foundation Models
on iOS 18.1+ A17 Pro / M-series, MediaPipe LLM Inference / Google AI Edge
Gemini Nano on Android) to extract structured fields from photos
(insurance card, lab report, prescription bottle, meal label). Two firm
rules:

1. **Inference must run fully on-device.** No image, OCR text, or
   LLM-generated structured output may be sent to any backend or
   third-party API for the inference step itself. Network calls happen
   only after the user explicitly approves a "Save to my profile" action,
   and even then only the structured fields land in `/api/profile/metrics`
   (audit-logged) — never the raw image or the model's verbatim output.
2. **Schema-pinning required.** Models receive a fixed JSON schema and
   must produce values for that schema only. Free-form LLM output is not
   stored. Today the default `StructuredExtractor` is regex-based; an LLM
   impl swaps in via `StructuredExtractorRegistry.shared` without
   touching call sites in `LabReportOCR`, `PrescriptionBottleOCR`, or
   `InsuranceCardOCR`.

---

## 3. Audit log

Every backend route that reads or writes PHI **must** be mounted behind
the `auditLog` middleware (`server/middleware/auditLog.js`). The
middleware writes one row per request to the `audit_log` table:

| Column | Type | Notes |
|---|---|---|
| id | INTEGER PRIMARY KEY |  |
| user_id | INTEGER | FK into `users.id`. NULL only for unauthenticated routes; never for PHI routes. |
| method | TEXT | HTTP method |
| path | TEXT | URL path; query string included |
| status | INTEGER | HTTP status code |
| ip | TEXT | `req.ip` (X-Forwarded-For honoured) |
| user_agent | TEXT | best-effort |
| created_at | TEXT | ISO-8601 |

The middleware is `await`-safe — it never blocks the request — and writes
through `db.prepare(...).run(...)` so a write failure doesn't fail the
upstream call. Unit-tested in `server/tests/auditLog.test.js`.

---

## 4. BAA status (TBD — week 1 placeholders)

| Vendor | Purpose | BAA status |
|---|---|---|
| Epic / MyChart (sandbox) | SMART-on-FHIR sandbox calls | N/A — sandbox does not contain real PHI |
| Epic / MyChart (production) | SMART-on-FHIR production calls | **Submitted week 1** — App Orchard registration in flight |
| Backend hosting (Render/Fly.io/AWS) | API + DB | **TBD — required before any production PHI endpoint** |
| Sentry (crash reporting) | error telemetry | **Already opt-in & body-scrubbed**; no PHI ever sent |
| PostHog (analytics) | product telemetry | **Already opt-in & PHI-blocked**; only screen names + button taps |
| Ribbon Health (doctor finder v1.1) | provider data | **Submitted week 1** — week 1 ships against NPPES (public, no BAA needed) |
| Meal vendor (TBD) | menu / order forwarding | **Submitted week 1** — vendor identity to be chosen |

Until each "TBD" / "Submitted" line is closed out, the related production
endpoint must remain feature-flagged off in release builds.

---

## 5. Breach plan (placeholder)

* Discovery → file `Care+ PHI breach` task in compliance Jira (TBD project
  key — link in repo root after compliance bootstrap).
* 24h: identify scope (which `audit_log` rows show data access by the
  affected actor; which `users.id` values are involved).
* 60-day clock for HIPAA breach notification begins on discovery date.
* All breach communications go through the company's HIPAA Privacy
  Officer; engineering supplies the audit trail.

---

## 6. User rights

* **Access**: `GET /api/profile` returns the user's identifying fields. A
  Care+ "Download my data" surface (deferred to week 4) will return a ZIP
  of all PHI tables for the requesting user.
* **Erasure**: `DELETE /api/profile` cascades to PHI tables via the FK
  `ON DELETE CASCADE` declared on each. iOS / Android also wipe the local
  PHI store + Keychain on logout via `KeychainStore.deleteAll(service:)`
  / `SecureTokenStore.clearJwt()` + `clearFhir(...)`.

---

*Last updated: Care+ week 1.*
