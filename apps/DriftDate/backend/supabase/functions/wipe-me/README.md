# wipe-me

GDPR-style "delete my account" Edge Function for Drift.

## Spec

| | |
|---|---|
| Method  | `POST` |
| Auth    | `Authorization: Bearer <user-jwt>` (required) |
| Body    | none (any body is ignored) |
| Success | `200 { deleted: true, user_id, tables: [...] }` |
| Failure | `401 { error: "missing_bearer" \| "invalid_jwt" }` <br> `500 { deleted: false, ..., auth_error }` |

## What it does

1. Verifies the bearer JWT against `auth.users` and extracts `user_id`.
   The body is **never** trusted for `user_id` — only the verified JWT
   subject can be deleted.
2. Sequentially deletes the user's rows from each public-schema table
   that holds user-owned data (`messages`, `conversations`, `waves`,
   `wave_aggregates`, `reports`, `blocked_users`, `photos`,
   `profile_prompts`, `profiles`). Each delete is wrapped in
   try/catch — a single table failure does not abort the rest.
3. Calls `auth.admin.deleteUser(user_id)` last. If this step fails the
   client should retry — the public rows are already gone, so the retry
   only needs to clear `auth.users`.

The schema (`backend/supabase/migrations/0001_init.sql`) declares
`ON DELETE CASCADE` on every FK, so deleting `profiles` alone would
also work. We delete explicitly anyway, both as a defence-in-depth
audit trail (the function returns the list of wiped tables) and so
that the behaviour is correct even if a future migration relaxes a
cascade.

## Local invoke

```sh
supabase functions serve wipe-me --no-verify-jwt   # local only
curl -X POST http://localhost:54321/functions/v1/wipe-me \
  -H "Authorization: Bearer $USER_JWT"
```

## Deploy

```sh
supabase functions deploy wipe-me --project-ref <ref>
```

The user-owner of the production Supabase project must run this once
against `drift.supabase.co` (see `PRODUCTION.md`).

## Required env vars

The Edge Function runtime injects these automatically when deployed
through `supabase functions deploy`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (privileged — used only inside this
  function for the admin-API delete; never echoed to the client)

## Callers

- iOS: `ios/Drift/Features/Settings/SettingsScreen.swift` — the
  "Erase all data" button in the Account section.
- Android: `android/app/src/main/java/com/americangroupllc/drift/settings/SettingsScreen.kt`
  — the "Erase all data" row at the bottom of the Settings list.
