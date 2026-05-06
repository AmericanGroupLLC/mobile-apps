# Drift — PRODUCTION

Operational notes for running Drift in production.

## 1. Environments

| Env | Supabase project | Bundle suffix | Notes |
|---|---|---|---|
| local      | `supabase start` (Docker)               | `com.americangroupllc.drift.dev` | seeded with 20 demo profiles |
| staging    | `drift-staging.supabase.co`              | `com.americangroupllc.drift.staging` | TestFlight + Play Internal |
| production | `drift.supabase.co`                      | `com.americangroupllc.drift` | App Store + Play Production |

Each env has its own Supabase secret bundle (`LLM_API_KEY`, AWS keys,
Sentry DSNs). The clients pick the env via build-time
`SUPABASE_URL` + `SUPABASE_ANON_KEY` — read from `Info.plist` on Apple,
from `BuildConfig` on Android.

## 2. Backend infra (Supabase)

- **Postgres**: 15.x, single primary, point-in-time recovery enabled.
- **PostGIS**: enabled in `0001_init.sql`, used only for the county
  centroid table; no lat/lon at row level.
- **Auth**: phone OTP provider (Twilio integration in Supabase). Email
  OTP also enabled for accounts that signed up before phone was
  configured.
- **Storage**: two buckets — `photos` (public-read after RLS) and
  `selfies` (private, deleted after Edge Function CompareFaces returns).
- **Realtime**: publication declared in `0002_realtime.sql` includes
  `messages`, `waves`, `conversations`, `wave_aggregates`.
- **Edge Functions**: `reply-suggest`, `verify-selfie`, `fuzz-location`.
  Each one is deployed via `supabase functions deploy <name>` from CI.

## 3. Capacity & scaling

- Initial sizing: Supabase Pro tier is plenty for the alpha (≤ 10k MAU).
- The wave fan-out for popular profiles uses the `wave_aggregates`
  materialised view — clients subscribe to the aggregate channel, not the
  raw insert stream. Refresh interval: every 5 s, set in
  `0001_init.sql` via `pg_cron`.
- Edge Function cold-start budget: 800 ms p95 for `reply-suggest`.
  Beyond that the client falls back to canned suggestions
  (`ReplySuggestion.fallback`).

## 4. Incident response

| Symptom | Triage | Mitigation |
|---|---|---|
| Edge Function 5xx > 1% in 5 min | Sentry release alert | Roll forward with cached canned suggestions. |
| Realtime websocket drops > 10% | PostHog event `realtime_disconnected` | Increase ping interval; surface "reconnecting…" in UI. |
| LLM provider outage | Edge Function logs | Switch `LLM_API_KEY` to fallback provider; redeploy `reply-suggest`. |
| Selfie-verify CompareFaces 5xx | AWS Rekognition status | Lower the similarity threshold by 1 point and queue retry. |
| Phone OTP cost spike | Twilio dashboard | Tighten reCAPTCHA threshold. |
| Sudden spike in `reports` | Supabase SQL view | Manual triage. Consider IP-based suspension. |

## 5. Backups

- Postgres PITR is on by default at the Supabase Pro tier (7-day window).
- Storage objects are versioned for 30 days.
- The schema migrations are the source of truth — a fresh restore with
  `supabase db reset` always reproduces the live schema.

## 6. Watch surfaces — minimalism by design

The watch app is **deliberately minimal** in v1: notification, layer
indicator, quick-reply tile/complication. No discover, no profile-edit,
no deep chat composition.

This keeps watch test surface tiny and avoids the 30%-file-count tax for
marginal user value. The plan for watch v2 (full discover) is gated on
real adoption telemetry first.

## 7. Audit log

A read-only Postgres view `audit.user_actions` aggregates every
report, block, profile edit, and verification result for ops review. Not
exposed via the client REST API.
