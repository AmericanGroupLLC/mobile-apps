# Drift — OBSERVABILITY

## 1. Stack

| Concern | Tool | Drift event surface |
|---|---|---|
| Crash reporting | Sentry (`canImport`-gated) | `CrashReportingService.shared.capture(...)` |
| Product analytics | PostHog (opt-in) | `AnalyticsService.shared.track(...)` |
| Backend logging | Supabase Logflare | `select * from logs.events where service='reply-suggest'` |
| Backend metrics | Supabase + Grafana Cloud | `pg_stat_*`, Edge Function p50/p95 latency |

All client SDKs are **opt-in** by default. The user toggles them in
**Settings → Telemetry**. The first build of a new install ships with
both toggles **off** so we never collect anything from a user who hasn't
seen the toggle.

## 2. Event taxonomy (canonical)

The same names fire from Apple and Android via the shared `AnalyticsEvent`
sealed type / enum.

| Event | Properties | Fired from |
|---|---|---|
| `onboarding_completed`        | `{phone_otp: bool, photos_count, selfie_verified}` | end of onboarding |
| `wave_sent`                   | `{layer, surface}`                                  | DiscoverScreen |
| `wave_matched`                | `{layer, time_to_match_seconds}`                    | server-pushed |
| `chat_screen_open`            | `{conversation_id, tone}`                           | ChatScreen on appear |
| `reply_suggestion_used`       | `{tone, kind: casual|context|playful}`              | ReplySuggestionsBar tap |
| `reply_suggestion_dismissed`  | `{tone}`                                            | user typed instead |
| `verification_started`        | `{}`                                                | VerificationCamera open |
| `verification_succeeded`      | `{similarity_pct}`                                  | Edge Function 200 |
| `verification_failed`         | `{reason}`                                          | Edge Function 4xx/5xx |
| `report_filed`                | `{reason}`                                          | ReportSheet submit |
| `block_user`                  | `{}`                                                | profile / chat menu |
| `settings_toggled`            | `{name, enabled}`                                   | SettingsScreen |
| `layer_switched`              | `{from_layer, to_layer}`                            | DiscoverScreen tabs |
| `app_opened_from_push`        | `{push_type: match|message}`                        | PushService didReceive |

## 3. Surface

The `Surface` enum (Swift) / `Surface` (Kotlin) labels which capture
surface produced an event. For Drift v1:

```
.app                 // main iPhone / Android app
.notificationExtension // iOS Notification Service Extension
.watch               // Apple Watch
.complication        // WidgetKit complication
.tile                // Wear OS tile
```

## 4. Dashboards

- **Funnel — onboarding**: `phone_otp_sent` → `phone_otp_verified` →
  `photos_uploaded` → `verification_succeeded` → `onboarding_completed`.
- **Funnel — first match**: `wave_sent` → `wave_matched` →
  `chat_screen_open` → first message sent.
- **Reply suggestions**: `reply_suggestion_used / total reply_suggestions`.
- **Verification fail rate** by reason.
- **Edge Function p50/p95 latency** (Supabase dashboard → Functions).

## 5. Sentry release naming

```
drift@<MARKETING_VERSION>+<CURRENT_PROJECT_VERSION>
e.g. drift@1.1.0+42
```

Same string on Apple and Android, so a single release marker covers both.

## 6. Logging hygiene

- **Never log message text.** `ChatService.send` logs only the hash and
  length.
- **Never log lat/lon.** `LocationService` logs only the resolved
  `zipPrefix3` etc.
- **Never log selfie image bytes.** Only the comparison-similarity score.
- Crash reports scrub usernames before upload via Sentry's `before-send` hook.
