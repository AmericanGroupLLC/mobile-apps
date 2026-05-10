# Drift — DESIGN

## 1. Product principles

1. **Layers, not "swipes."** The user picks the radius they want to be
   discovered in: Server (everyone), State, County, or ZIP-prefix. The same
   profile may show in multiple layers; the layer chip on the card tells you
   which layer surfaced it.
2. **Verification before chat unlocks.** No conversation happens before a
   live-selfie + reference-photo match. The reference is one of the user's six
   profile photos.
3. **No blank textbox.** Every chat screen-entry calls a server-side LLM via
   an Edge Function and surfaces three suggested first messages: **Casual**,
   **Context**, **Playful**.
4. **Public-meetup framing, not location share.** When the conversation tone
   becomes meetup-ready, suggestions point at coffee shops / public events,
   never "send my pin."
5. **Calm.** No haptic dopamine bait, no aggressive notifications, no super-like
   paywall.

## 2. Repo map

```
DriftDate/
├── README.md
├── DESIGN.md                         (you are here)
├── DRIFT-FEATURES.md / SAFETY.md / TESTING.md / PRIVACY.md / ...
├── codecov.yml / .gitignore / LICENSE
├── index.html / styles.css / script.js / robots.txt / sitemap.xml
├── distribution/whatsnew/...
├── .github/workflows/                7 GitHub Actions workflows
│   ├── ci.yml                        unit tests on every push
│   ├── ios.yml                       iOS / watchOS sim build + tests
│   ├── android.yml                   Android instrumented Compose tests
│   ├── marketing.yml                 GitHub Pages deploy of marketing site
│   ├── backend.yml                   Supabase migration + Edge Function tests
│   ├── pre-release-tests.yml         release gate
│   └── release.yml                   tag-push → all binaries + GitHub Release
├── scripts/                          local dev helpers
├── backend/supabase/                 Postgres schema + RLS + Edge Functions
│   ├── config.toml
│   ├── migrations/0001_init.sql      profiles / photos / waves / conversations / messages / reports
│   ├── migrations/0002_realtime.sql  Realtime publications
│   ├── migrations/0003_rls_helpers.sql is_layer_match / can_view_profile / can_send_message
│   ├── functions/reply-suggest/      Edge Function: 3 reply suggestions
│   ├── functions/verify-selfie/      Edge Function: AWS Rekognition CompareFaces
│   ├── functions/fuzz-location/      Edge Function: lat/lon → ZIP-prefix3
│   └── seed/seed.sql                 20 demo profiles for local dev
├── shared/DriftCore/                 Apple Swift Package (iOS + watchOS)
│   ├── Package.swift
│   ├── Sources/DriftCore/Models/     Profile, Photo, Wave, Conversation, Message, Tone, Intent, Layer, ReplySuggestion
│   ├── Sources/DriftCore/Domain/     LayerScorer, ToneClassifier, LocationFuzzer, ReplyPromptBuilder
│   ├── Sources/DriftCore/Networking/ thin URLSession SupabaseClient
│   ├── Sources/DriftCore/Observability/ Sentry + PostHog stubs
│   └── Tests/DriftCoreTests/         XCTest, mirrored case-for-case with Android
├── ios/                              iPhone app
│   ├── project.yml                   XcodeGen spec
│   ├── Drift/App/                    DriftApp + RootView
│   ├── Drift/Features/{Onboarding,Discover,Matches,Chat,Profile,Settings,Safety}
│   ├── Drift/Services/               AuthService, ProfileService, ChatService, DiscoverService, ReplyService, VerificationService, LocationService, PushService
│   ├── Drift/Resources/              Info.plist, Drift.entitlements, Assets, LaunchScreen
│   ├── DriftNotificationService/     rich-push extension (decrypts previews)
│   ├── DriftTests/                   view-model glue tests
│   └── DriftUITests/                 XCUITest smoke
├── watchos/                          Apple Watch app
│   ├── project.yml
│   ├── DriftWatch/App/               DriftWatchApp
│   ├── DriftWatch/Views/             MatchesListView, QuickReplyView
│   └── DriftWatchComplication/       WidgetKit complication (layer + unread)
└── android/
    ├── settings.gradle.kts           rootProject.name = Drift, includes :core, :app, :wear
    ├── build.gradle.kts              Kotlin 2.0, Hilt, Compose plugins
    ├── core/                         pure-Kotlin/JVM, no Android deps — :core:test (NOT testDebugUnitTest)
    │   └── src/main/java/com/americangroupllc/drift/core/{models,domain,networking,obs}/
    ├── app/                          phone app, applicationId com.americangroupllc.drift
    │   └── src/main/java/com/americangroupllc/drift/{auth,onboarding,discover,chat,matches,profile,settings,safety,verification,data,di,push}/
    └── wear/                         applicationId com.americangroupllc.driftwear
        └── src/main/java/com/americangroupllc/driftwear/{matches,quickreply,tile,complication}/
```

## 3. Layered architecture

```
┌──────────────────────────────────────────────────────────────┐
│ Presentation       SwiftUI (iOS + watchOS)                    │
│                    Jetpack Compose (phone + Wear)             │
├──────────────────────────────────────────────────────────────┤
│ Services           AuthService, ProfileService, ChatService,  │
│                    DiscoverService, ReplyService,             │
│                    VerificationService, LocationService,      │
│                    PushService                                │
├──────────────────────────────────────────────────────────────┤
│ Domain (shared)    Profile, Wave, Conversation, Message,      │
│                    Layer, Intent, Tone, ReplySuggestion       │
│                    + LayerScorer, ToneClassifier,             │
│                    LocationFuzzer, ReplyPromptBuilder         │
├──────────────────────────────────────────────────────────────┤
│ Networking         thin URLSession (Swift) / Ktor (Kotlin)    │
│                    over Supabase REST + Realtime websocket    │
├──────────────────────────────────────────────────────────────┤
│ Backend            Postgres + RLS + PostGIS centroids         │
│                    Realtime LISTEN/NOTIFY                     │
│                    Edge Functions (Deno):                     │
│                      reply-suggest  (LLM provider, env key)   │
│                      verify-selfie  (AWS Rekognition)         │
│                      fuzz-location  (lat/lon → ZIP-3)         │
└──────────────────────────────────────────────────────────────┘
```

## 4. Discovery layers

| Layer | Stored on profile | Resolution to client | Pool size |
|---|---|---|---|
| Server   | always discoverable | full pool                          | unbounded |
| State    | `state_code`        | "in California"                    | thousands |
| County   | `county_fips`       | "in Santa Clara County"            | hundreds  |
| ZIP-3    | `zip_prefix3`       | "same ZIP-3"                       | tens      |

The **client never sees a precise lat/lon**. The on-device `LocationFuzzer`
truncates to ZIP-3 before any network call. The Edge Function
`fuzz-location` exists as a defence-in-depth for a buggy client; the server
also strips lat/lon if it ever arrives.

## 5. Smart-reply pipeline

```
                  ┌──────────────────────────┐
 ChatScreen ───▶ │ ReplyService (Swift/Kotlin)│
                  └──────────────┬─────────────┘
                                 │ POST /functions/v1/reply-suggest
                                 │ {conversation_id}  + caller JWT
                                 ▼
                  ┌──────────────────────────┐
                  │ Edge Function: reply-suggest│
                  │  · loads profiles + last 5  │
                  │    messages + tone           │
                  │  · ReplyPromptBuilder        │
                  │  · LLM provider (env key)    │
                  │  · returns 3 suggestions     │
                  └──────────────────────────┘
```

The LLM provider key is held as a Supabase secret; the client only ever
sends `conversation_id`. The function fetches messages itself using the
caller's JWT, so RLS still gates everything.

## 6. Realtime

Postgres LISTEN/NOTIFY → Supabase Realtime → websocket → client. The
publication declared in `0002_realtime.sql` includes `messages`, `waves`,
`conversations`. Popular profiles use a `wave_aggregates` materialized view
to avoid backpressure (clients subscribe to the aggregate, not the raw
1000-wave/sec stream).

## 7. Why these tech choices

- **Native per platform** so we get full SwiftUI / Compose, real
  Sentry / PostHog SDKs, and idiomatic watch surfaces.
- **Supabase** so a tiny solo backend gets us Auth + Postgres + Storage +
  Realtime + Edge Functions in one bundle, with provider-portable Postgres
  dialect and standard JWTs.
- **Shared `:core` and `DriftCore`** so the keystone test files (`LayerScorer`,
  `ToneClassifier`, `LocationFuzzer`, `ReplyPromptBuilder`) live in
  pure-logic modules that compile on JVM and Apple — and stay green
  regardless of platform UI churn.
