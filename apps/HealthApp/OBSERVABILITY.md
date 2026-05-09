# MyHealth — Observability & Analytics Stack

> **All free tier · all opt-in · all privacy-first**

A "full observability platform" usually means: **errors + logs + metrics + APM + replays + product analytics**. The big SaaS suites (Datadog, New Relic, Grafana Cloud) bundle these together but charge per host/user — out of reach for an early-stage app.

MyHealth uses a **pieced-together free stack** that gives you ~80% of the same capability for $0/month.

---

## 1. The chosen stack

| Concern | Tool | Free tier | Why |
|---|---|---|---|
| **Crash reporting** | [Sentry](https://sentry.io) | 5K errors/mo | Best-in-class stack-trace symbolication, 2024-grade SwiftPM/Gradle SDKs |
| **Performance / APM** | Sentry (same project) | included | We have `tracesSampleRate=0` by default; flip to 0.1 in prod when you want it |
| **Session replay** | Sentry Replay | 50/mo | Disabled in MyHealth on privacy grounds — easy to flip on |
| **Logs** | Sentry Logs (2024 GA) | included | Structured logs in same dashboard as errors |
| **Product analytics** | [PostHog](https://posthog.com) | **1M events/mo** | Open source, GDPR-friendly, EU region available, **self-hostable** if you outgrow free |
| **Feature flags** | PostHog (same project) | included | Roll out new features by % of users |
| **Heatmaps + funnels** | PostHog (same project) | included | See where users drop off in onboarding |
| **Server metrics** | [Grafana Cloud Free](https://grafana.com/products/cloud/) | 10K series + 50 GB logs | Optional — only when the backend grows beyond a single VM |
| **Uptime monitoring** | [UptimeRobot](https://uptimerobot.com) free | 50 monitors, 5-min checks | Pings `/api/health-check` |
| **Pages / status page** | [statuspage.io](https://www.atlassian.com/software/statuspage) free | 1 status page, 100 subs | Communicate incidents |

**Total cost: $0/month** for any pre-MVP / MVP product.

---

## 2. Where MyHealth currently lives on the spectrum

|  | Datadog | New Relic | Grafana Cloud | **MyHealth (Sentry + PostHog)** |
|---|:-:|:-:|:-:|:-:|
| Errors / crashes | ✅ | ✅ | ✅ (Faro) | ✅ Sentry |
| Performance / APM | ✅ | ✅ | ✅ (Tempo) | ✅ Sentry tracing |
| Logs (centralized) | ✅ | ✅ | ✅ (Loki) | ✅ Sentry Logs |
| Infrastructure metrics | ✅ | ✅ | ✅ (Prometheus) | ⚪ Grafana Cloud Free (optional) |
| Uptime monitoring | ✅ | ✅ | – | ⚪ UptimeRobot Free (optional) |
| Session replay | ✅ | ✅ | ✅ (Faro) | ✅ Sentry Replay (off by default) |
| Product analytics | – | – | – | ✅ PostHog |
| Feature flags | – | – | – | ✅ PostHog |
| Cohort funnels / heatmaps | – | – | – | ✅ PostHog |
| **Cost / month** | $$$ | $$$ | Free 10K | **$0** |

---

## 3. What's wired in this repo

### iOS / watchOS
- `shared/FitFusionCore/Package.swift` declares `posthog-ios` + `sentry-cocoa` SwiftPM deps
- `CrashReportingService.swift` → Sentry wrapper (opt-in via Settings → "Send crash reports")
- `AnalyticsService.swift` → PostHog wrapper (opt-in via Settings → "Share anonymous usage analytics")
- Booted from `FitFusionApp.init()` only when toggles are on

### Android phone (+ Wear)
- `android/app/build.gradle.kts` declares `io.sentry:sentry-android` + `com.posthog:posthog-android` deps
- `crash/CrashReportingService.kt` + `analytics/AnalyticsService.kt` mirror the iOS API
- Booted from `MyHealthApp.onCreate()` only when DataStore opt-in flags are true
- BuildConfig fields `SENTRY_DSN`, `POSTHOG_API_KEY`, `POSTHOG_HOST` injected from env vars at build time

### Backend (Express)
- `server/middleware/sentry.js` + `server/middleware/analytics.js` are graceful no-op shims when env vars are unset
- `server.js` calls `Sentry.init` + `Analytics.init` early, then attaches Sentry request/error handlers around the routes
- npm deps: `@sentry/node` + `posthog-node`

### Expo (React Native)
- `mobile/src/crash.js` (Sentry) + `mobile/src/analytics.js` (PostHog)
- Read DSN/key from `EXPO_PUBLIC_SENTRY_DSN` / `EXPO_PUBLIC_POSTHOG_API_KEY`
- Toggle stored under AsyncStorage key `crashReportsEnabled` / `analyticsEnabled`

---

## 4. Privacy contract — same on every platform

| Field | Sentry sends? | PostHog sends? |
|---|:-:|:-:|
| Stack trace (file, line, fn) | ✅ | – |
| Device model + OS version | ✅ | ✅ |
| App version | ✅ | ✅ |
| Anonymous installation_id | ✅ | ✅ |
| Email / name / account ID | ❌ never | ❌ never |
| HealthKit / Health Connect data | ❌ never | ❌ never |
| Medicine names, doses, mood entries | ❌ never | ❌ never |
| Photos / screen recordings / videos | ❌ never | ❌ never (replay disabled) |
| URL query strings, POST bodies | ❌ never | ❌ never |
| Feature-use events (e.g. "meal_logged") | – | ✅ name only, no contents |

Both wrappers strip `event.user` in `beforeSend` to belt-and-suspenders enforce zero-PII.

---

## 5. Event taxonomy (kept in sync across platforms)

```
onboarding_started              first launch screen rendered
onboarding_completed            user pressed "Enter MyHealth"
guest_mode_chosen               user tapped Continue as Guest
sign_in_completed               user signed in via the backend
workout_started                 timer began for any workout
workout_completed               timer ended (logged or aborted)
meal_logged                     a Meal entity was inserted
medicine_added                  a Medicine entity was inserted
medicine_dose_taken             user tapped Take on a reminder
bio_age_estimated               BiologicalAgeView was opened
data_export_triggered           Settings → Export pressed
data_erase_confirmed            Settings → Erase confirmed
```

Each of these is a single string defined in:
- `shared/FitFusionCore/Sources/FitFusionCore/AnalyticsService.swift` (`AnalyticsEvent`)
- `android/app/src/main/java/com/myhealth/app/analytics/AnalyticsService.kt` (`AnalyticsEvent`)
- `mobile/src/analytics.js` (`Events`)

Keep these three lists in sync when adding a new event.

---

## 6. Mixpanel / Amplitude alternative

If you'd rather use Mixpanel or Amplitude instead of PostHog:

| | Mixpanel | Amplitude | PostHog (default) |
|---|---|---|---|
| Free tier | 20M events/mo | 10M events/mo | **1M events/mo** + self-host |
| Open source | ❌ | ❌ | ✅ |
| GDPR-friendly defaults | ⚠️ | ⚠️ | ✅ |
| EU-region data residency | ✅ paid | ✅ paid | ✅ free |
| Feature flags included | ❌ paid | ❌ paid | ✅ free |
| Session replay included | ❌ paid | ❌ paid | ✅ free (50/mo) |
| Self-host option | ❌ | ❌ | ✅ |

To switch: replace the SDK call inside `AnalyticsService.{swift,kt,js}` with the Mixpanel/Amplitude equivalent. The public API (`track`, `identify`, `screen`, `reset`) is intentionally the same.

---

## 7. Optional: full Datadog/New Relic/Grafana setup

When the app + backend grow beyond single-host scale:

| Component | Free option | Path |
|---|---|---|
| Server metrics + dashboards | **Grafana Cloud Free** (10K active series, 50 GB logs, 14-day retention) | Add `prom-client` to `server/`, expose `/metrics`; configure Grafana Cloud agent |
| Centralized logs | **Grafana Loki** in Grafana Cloud Free | Wire `winston` + `winston-loki` transport in backend |
| Distributed tracing | Sentry Tracing (free w/ existing project) OR Grafana Tempo Free | Already wired; flip `tracesSampleRate` from 0 → 0.1 in `CrashReportingService` |
| Real User Monitoring | **Sentry Browser/RN** (already wired) OR Grafana Faro Free | – |
| Synthetic monitoring | UptimeRobot Free (50 monitors, 5-min cadence) | Point at `/api/health-check` |
| Status page | statuspage.io free (1 page, 100 subs) | Embed iframe on marketing site |

---

## 8. Setup checklist

1. **Sentry** — sign up at [sentry.io/signup](https://sentry.io/signup/) (free) → 5 projects → 5 DSN secrets in GitHub. See [`SENTRY.md`](./SENTRY.md).
2. **PostHog** — sign up at [posthog.com/signup](https://posthog.com/signup/) (free) → 1 project → 1 API key (used for both phone + watch since it's the same product). Add 5 secrets:
   - `POSTHOG_API_KEY_IOS`, `POSTHOG_API_KEY_ANDROID`, `POSTHOG_API_KEY_SERVER`, `POSTHOG_API_KEY_EXPO` (or share one key — both works)
   - `POSTHOG_HOST` (defaults to `https://eu.i.posthog.com`)
3. **UptimeRobot** (optional) — sign up free → add HTTP monitor on `https://api.myhealth.app/api/health-check`.
4. **Grafana Cloud Free** (only when needed) — sign up free → install agent on backend host → grab dashboards from grafana.com.

Until those secrets are wired, every wrapper in this repo is a **silent no-op** — nothing breaks, nothing leaks.

---

## 9. Honest limitations of this stack

- **No infrastructure-level monitoring** (CPU, memory, disk, network) without adding Grafana Cloud or Datadog. Sentry/PostHog see only your app's perspective.
- **No SLO tracking** — for that you'd want Grafana SLO or Sentry's paid SLO add-on
- **No PagerDuty / on-call rotation** integration — use Sentry's free Slack alert action and a free PagerDuty Developer plan
- Free tiers are **soft caps** — exceeding them means you stop getting new events, you don't get billed

For an early-stage app: this is more than enough. For a 100k MAU app with a paying SLA: graduate to Grafana Cloud Pro ($49/mo) + Sentry Team ($26/mo) + PostHog $0 (still free up to 1M events).
