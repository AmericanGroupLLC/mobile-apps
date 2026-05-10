# MyHealth — Privacy Policy

*Last updated: 2026-05-06*

## TL;DR

- **Optional account.** "Guest Mode" works without login on every platform. If
  you create an account, it lives on the MyHealth backend you (or your fork)
  control.
- **No tracking by default.** Crash reporting (Sentry) and product analytics
  (PostHog) ship as *off-by-default* and only run if you opt in via
  Settings → Privacy.
- **Health data is yours.** Apple HealthKit (iPhone, Apple Watch) and Android
  Health Connect (Android phone, Wear OS) are the source of truth. We never
  copy HealthKit/Health Connect data to our backend, never log it to Sentry,
  and never send it to PostHog.
- **Open source.** Every line is at <https://github.com/AmericanGroupLLC/HealthApp>
  under the MIT License. Audit anything; build it yourself if you don't trust
  us.

## What MyHealth stores

### On your device, in OS-private storage that's wiped if you uninstall:

- Your privacy preferences (which opt-in toggles you've enabled).
- Your last-viewed dashboard tab, theme, and unit preferences (kg/lb, ml/oz).
- Your local workout history (CoreData on iOS, Room on Android, Expo SQLite on
  the React Native build).
- A cache of media (workout GIFs, exercise illustrations) downloaded for
  offline use.
- Your AI coach conversation history (on-device only — the local LLM never
  leaves the device).

### In Apple HealthKit / Android Health Connect (you control via OS settings):

- Workouts, heart rate, steps, weight, water, mindfulness sessions,
  state-of-mind, sleep stages.
- We **read** these to show you trends and **write** new entries (e.g., a
  workout you finished). We never read more than is needed for the screen
  you're on. Permissions are granular: you can grant read-only, write-only,
  or both per data type.

### On the MyHealth backend (only if you create an account):

- Email + bcrypt-hashed password (or OAuth provider claim, if signed in via
  Apple/Google).
- Workout templates and challenges you create or join.
- Account-level preferences (display name, avatar URL, time zone).
- We **do not** store HealthKit/Health Connect data server-side. Workouts
  synced to the backend are summary records (`type`, `duration`, `kcal`,
  `start_at`); full sample data stays in HealthKit/Health Connect.

## What MyHealth sends off-device (only if you opt in)

### Crash reports — Sentry (off by default)

| Field | Sent? |
|---|---|
| OS version, device model, app version | ✅ yes |
| Stack trace, breadcrumbs (last ~30 user actions, sanitized) | ✅ yes |
| Anonymous installation ID | ✅ yes |
| User email, account ID | ❌ never — wrapper strips `event.user` |
| HealthKit / Health Connect data | ❌ never — never logged |
| Meal contents, medicine names, photos, screen recordings | ❌ never |
| AI coach conversation history | ❌ never |

Sentry is wired into iOS, watchOS, Android, Wear OS, the Expo build, and the
backend. See [`SENTRY.md`](./SENTRY.md) for the wrapper code and the exact
DSN-resolution order.

### Product analytics — PostHog (off by default)

We capture **screen views**, **feature taps** (e.g., "started workout"), and
**funnel events** (e.g., "completed onboarding"). We capture event names and
non-PII properties. We **never** capture: workout data values, meal contents,
medicine names, biometrics, HealthKit/Health Connect data, photos, or text you
type into the AI coach.

PostHog is self-hostable (EU region by default for the OSS option). See
[`OBSERVABILITY.md`](./OBSERVABILITY.md) for the full pipeline.

### Backend — your data, on a server you (or we) operate

When you sign in, your account credentials and the summary records described
above transit over HTTPS to the MyHealth backend. The backend itself is
open-source (see `server/`) and self-hostable.

## What MyHealth never sends, ever

- Your full HealthKit / Health Connect sample data.
- Photos taken in-app (form-check videos for AI analysis are processed
  on-device).
- AI coach conversation contents.
- Medicine names, dosages, or schedules.
- Meal photos or food log contents.

## Third-party SDKs

| SDK | Purpose | Default | Where it runs |
|---|---|---|---|
| `getsentry/sentry-cocoa` | Crash reporting (iOS, watchOS) | OFF | Device |
| `io.sentry:sentry-android` | Crash reporting (Android, Wear) | OFF | Device |
| `@sentry/node` | Crash reporting (backend) | OFF | Server |
| `@sentry/react-native` | Crash reporting (Expo build) | OFF | Device |
| `posthog-ios` | Product analytics (iOS) | OFF | Device |
| `posthog-android` | Product analytics (Android) | OFF | Device |
| `posthog-node` | Product analytics (backend) | OFF | Server |
| `posthog-react-native` | Product analytics (Expo) | OFF | Device |
| Apple HealthKit | Health data read/write | (user grants per-type) | Device only |
| Android Health Connect | Health data read/write | (user grants per-type) | Device only |
| Apple WorkoutKit | Workout suggestions / scheduling | OS-managed | Device |
| Apple SignIn / Google SignIn | Optional account creation | (user-initiated) | Device → backend |
| On-device LLM (`llama.cpp` family) | AI coach | (user-initiated) | Device only |

## Marketing site

The marketing site at <https://americangroupllc.github.io/HealthApp/> uses
**Google Analytics (GA4)** for visitor counts on the public landing page only.
This is independent of the app itself; once you install the app, GA4 is not
involved. Marketing-site analytics can be disabled by browser-level
do-not-track preferences and ad blockers.

## Children

MyHealth is rated 12+ in App Store and "Teen" in Play. Parts of the AI coach
discuss exercise intensity and nutrition that may not be appropriate for
younger users. We do not knowingly collect data from children under 13 (or the
local minimum age, where higher).

## Your rights

- **Access** — request an export of your account data via
  <mailto:privacy@americangroupllc.com>. We respond within 30 days.
- **Delete** — delete your account from Settings → Account → Delete Account,
  or email the address above. Local on-device data is wiped on uninstall.
- **Withdraw consent** — turn off Sentry / PostHog at any time in
  Settings → Privacy. Past events that were sent before you opted out are not
  retroactively deleted from Sentry/PostHog (we'll delete the entire project
  on request).
- **Data Subject Requests (GDPR/CCPA)** — same email; same 30-day SLA.

## Changes to this policy

We'll bump *Last updated* at the top and post a brief note in the in-app
What's New on any change that affects what we collect or how. Material changes
will require fresh consent.

## Contact

privacy@americangroupllc.com
