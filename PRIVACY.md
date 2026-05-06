# Drift — PRIVACY

Drift is a dating app. The privacy stakes are high. This doc is the
single source of truth for what we collect, why, and how to delete it.

## 1. What we collect

| Data | Purpose | Storage | Retention |
|---|---|---|---|
| Phone number  | Auth (OTP)            | Supabase Auth (encrypted at rest) | until account deletion |
| Email (optional) | Auth fallback      | Supabase Auth                     | until account deletion |
| Display name | Shown on profile cards | Postgres `profiles.display_name`  | until account deletion |
| Date of birth | Age range computation | Postgres `profiles.dob`           | until account deletion |
| Profile photos (≤ 6) | Profile UI       | Supabase Storage `photos/`        | until account deletion |
| Reference selfie | Verification matching | Supabase Storage `selfies/`     | **deleted within 60s** of Edge Function CompareFaces returning |
| Voice prompt (≤ 30s) | Profile UI      | Supabase Storage `voice/`         | until account deletion |
| Intent + vibe tags + prompts | Discovery + matching | Postgres                  | until account deletion |
| ZIP-prefix-3 / countyFips / stateCode | Discovery layers | Postgres `profiles.*` | until account deletion |
| Wave events | Match graph | Postgres `waves`                              | until account deletion |
| Messages | Realtime chat | Postgres `messages`                              | until account deletion or per-conversation deletion |
| Reports | Trust & Safety | Postgres `reports`                            | indefinite (legal hold) |

## 2. What we explicitly do NOT collect

- **No precise lat / lon.** The on-device `LocationFuzzer` truncates
  before any HTTP call. The schema has no `lat`/`lon` columns.
- **No facial-feature embeddings.** AWS Rekognition CompareFaces returns
  a similarity float; we persist only the boolean threshold result.
- **No browsing history or contact list.**
- **No advertising IDs.** No `ATT` prompt on iOS, no
  `AdvertisingIdClient` on Android.
- **No third-party trackers in the marketing site.** Static HTML, no
  analytics.

## 3. Verification image lifecycle

1. User taps Capture on `VerificationCamera`.
2. Image is uploaded to `selfies/<userId>/<uuid>.jpg`.
3. Edge Function `verify-selfie/index.ts` is invoked with
   `{selfie_image_id, comparison_photo_id}` (the comparison photo is
   one of the user's six tagged photos).
4. Edge Function calls AWS Rekognition `CompareFaces` with similarity
   threshold ≥ 90.
5. On success, `profiles.verified_at = now()` is set.
6. **The selfie image is deleted from `selfies/` immediately** (TTL = 60s).
7. **No facial-features metadata is persisted.**

This flow is documented for App Store / Play Store reviewers in
`STORE-PACKAGING.md` §5.

## 4. Telemetry opt-ins

- Sentry crash reports — **off by default**. Toggleable in
  Settings → Telemetry.
- PostHog product analytics — **off by default**. Same toggle.
- Both wrappers PII-scrub before upload (display_name, phone, email,
  any lat/lon-shaped strings) — see `SENTRY.md` §4.

## 5. User rights

| Right | How |
|---|---|
| Access (download my data) | Settings → Account → "Email me my data". A signed link to a JSON export is emailed within 24h. |
| Correction               | Edit Profile screen.                          |
| Erasure                  | Settings → Account → "Erase all data".  Deletes profile + photos + voice + messages immediately. **Reports cannot be erased** (legal hold). |
| Account deletion         | Settings → Account → "Delete account".  Closes the auth.user row in addition to the data wipe above. |
| Portability              | The "Email me my data" export is JSON, machine-readable. |

## 6. Where it lives

- **All persistent data** lives in the Drift Supabase project
  (US-East by default; EU project for users in EU when launched).
- **Verification selfies** transit AWS Rekognition `us-east-1` in-flight.
  No image bytes are persisted in AWS — only the API call result.
- **No CDN cache** of the photos URLs (signed URLs, 5-minute TTL).
- **No raw SQL access from clients** — every query goes through PostgREST
  with RLS enforced.

## 7. Children

Drift is **18+** (matches Tinder / Hinge). Onboarding asks for date of
birth, refuses signups with computed age < 18, and the verification step
serves as an additional liveness check.

## 8. Legal & contact

- Operator: American Group LLC
- Contact for privacy: privacy@americangroupllc.com
- DPO (when in EU jurisdictions): TBD before EU launch.

This document is updated atomically with the schema. Diff
`PRIVACY.md` against `0001_init.sql` to see if changes are out of sync.
