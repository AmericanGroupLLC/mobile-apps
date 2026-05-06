# Drift — SAFETY

Verification, reporting, abuse, location fuzzing.

## 1. Verification (live-selfie + reference photo)

1. During onboarding the user uploads six profile photos. They tag exactly
   one as the **reference selfie** (auto-suggested: most recent face-on
   photo per `Vision`/`MLKit` face detection).
2. The user opens `VerificationCamera` (live preview, head must occupy
   ≥ 30% of frame, eyes detected). One frame is captured and uploaded as
   the **comparison selfie**.
3. The Edge Function `verify-selfie/index.ts` calls
   AWS Rekognition `CompareFaces` with similarity threshold **≥ 90**.
4. On match, `profiles.verified_at = now()`. The comparison selfie is
   deleted from Storage immediately; only the boolean result is persisted.
   No facial-feature embeddings are stored.
5. Until verification passes, **chat is locked**. The match exists, but the
   reply suggestions UI shows a "Verify to chat" call-to-action instead of
   the keyboard.

## 2. Reporting + blocking

Every profile and every chat surface has a **Report** and a **Block** affordance.

- `Report` writes a row in `reports (reporter_id, target_id, reason, note,
  created_at)`. Operators see this in a private Supabase view.
  Reporter sees a confirmation: *"Thanks — we'll review within 24 hours."*
- `Block` writes a row in `blocked_users (blocker_id, blocked_id, created_at)`.
  RLS prevents either party from `SELECT`-ing the other's profile or
  conversations after that point.
- Mute is a per-conversation setting (`conversations.muted_by_a / muted_by_b`)
  that suppresses push notifications.

## 3. Anonymous display name

Until two users have a mutual Wave **and** verification on both sides, the
name shown on the card is the chosen `display_name` (not real name). The
`profiles.legal_name` column is read-only to ops, never to clients.

## 4. Location fuzzing math

`shared/DriftCore/Sources/DriftCore/Domain/LocationFuzzer.swift` (and the
mirrored Kotlin file in `:core`) implements:

```
lat, lon  →  zipPrefix3   (first 3 digits of the ZIP code at that point)
          →  countyFips   (5-digit FIPS code from a static state→county polygon table)
          →  stateCode    (USPS 2-letter)
```

The function is **pure**: same input, same output, no I/O. The lat/lon
never leaves the device:

- The client truncates **before** any HTTP call.
- The server's `fuzz-location` Edge Function exists only as a defence in
  depth — if a buggy client somehow sends `{lat, lon}`, the function
  truncates and discards.
- The Postgres schema has **no `lat` or `lon` column**. There is only a
  PostGIS centroid for the **county**, used by `is_layer_match()` and never
  exposed via REST.

## 5. Public-meetup framing

When `ToneClassifier` returns `.meetupReady`, `ReplyPromptBuilder`
adds a system-prompt clause that biases the LLM toward suggestions like
*"Coffee at Equator on University Ave Saturday?"* and away from
*"send me your address."*

There is no in-app private location share. No "Tonight Mode."
No "Drop a Pin." If users want to share a place they're meeting, they do it
through their existing maps/messaging apps — Drift never sees those coordinates.

## 6. Screenshot detection (best-effort)

- iOS uses `UIScreen.userDidTakeScreenshotNotification` to surface a one-time
  toast: *"Screenshots may be reported. Be respectful."* This does not
  prevent the screenshot.
- Android has no screenshot-detection API. A one-time disclosure on first
  chat screen says: *"Photos and chats may be screenshot. Be careful what
  you share."*
- Neither platform attempts FLAG_SECURE — false sense of security and breaks
  legitimate accessibility tools.

## 7. Bot / spam mitigation

- Phone OTP via Supabase Auth, **per-IP and per-phone rate limit** (default
  Supabase config; raise limits only after measuring real volume).
- `reCAPTCHA v3` wrapper on the OTP request endpoint (gated by env
  `RECAPTCHA_SITE_KEY`).
- Verification gate (no chat without selfie match) raises the bar from
  "make 1000 fake accounts" to "make 1000 fake accounts that pass live-selfie
  matching against a reference photo." Not impossible, but considerably
  harder than the alternative.

## 8. Erase-all-data + delete-account

- Settings → Erase all data → confirms and calls `DELETE /functions/v1/wipe-me`
  which removes profile, photos, waves, messages, and conversations.
- Settings → Delete account → also closes the Supabase auth.user row.

Both are irreversible. The client also flushes its local Room/JSON cache.

## 9. Operator playbook

See `OBSERVABILITY.md` for dashboards.

| Signal | Where | Action |
|---|---|---|
| Spike in `reports` per hour | Supabase SQL view | Triage by reporter trust score; suspend repeat offenders. |
| Failed selfie-verification rate > 30% | PostHog event | Check Rekognition latency; lower threshold by 1 point if false-negative spike. |
| Edge Function `reply-suggest` 5xx > 1% | Sentry | Provider outage; serve canned suggestions. |
| Phone OTP cost > budget | Twilio dashboard | Tighten reCAPTCHA threshold; add `accept-language` heuristics. |
