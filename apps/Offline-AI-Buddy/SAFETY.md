# SAFETY.md

How Offline AI Buddy handles content safety, kid-safe mode, and the PIN
lock.

## §1 — Two profiles

Every install has up to two profiles:

| Profile | Default | System prompt | Modes available | Voice preset |
|---|---|---|---|---|
| **Adult** | yes | "You are a friendly, helpful, honest assistant…" | All 6 (Chat, Roast, Daily, Party, Game Coach, Translate) | User-selectable |
| **Kid-Safe** | optional | strict refusal preamble (see §3) | 5 (Roast disabled) | Forced "calm" |

Profiles share the same model weights — kid-safe is purely a
prompt + filter layer.

## §2 — PIN lock

Switching from **Kid → Adult** requires a 4-digit PIN, set once during
onboarding when the user first selects Kid-safe.

- PIN is stored as **PBKDF2-SHA256** (100,000 rounds, 16-byte random
  salt) in `profiles.json`. Never stored in plaintext.
- Failed PIN attempts: after 5 failures, the PIN prompt locks for 60
  seconds.
- PIN reset: only by deleting and re-creating the Kid-safe profile from
  the Adult profile (which itself requires the PIN). No "forgot PIN"
  email — there's no email, there's no server.

Implementation: `BuddyAICore.ProfilesStore.verify(pin:for:)` /
`ProfilesStore.kt#verify`.

## §3 — Kid-safe system prompt

Prepended to every Kid-safe chat session, in the chat language:

> "You are talking with a child. Refuse anything involving violence,
> weapons, drugs, alcohol, gambling, romance, profanity, self-harm, or
> dangerous activities. If asked about any of these, say 'Let's pick a
> different topic — how about [age-appropriate suggestion]?' Always be
> kind, encouraging, and curious. Keep answers short."

Translated equivalents for hi/zh/fr/es live in `PromptTemplates`.

## §4 — Output filter (`ContentPolicy`)

Every assistant token passes through `ContentPolicy.filter(text:)`,
which:

1. Maintains a rolling 80-character buffer (regex matches across token
   boundaries).
2. Applies a curated regex deny-list, cased per-language, covering:
   - Violence keywords (kill, weapon, blood, …)
   - Romance keywords (kiss, naked, sex, …)
   - Profanity (full per-language lists)
   - Drugs / gambling / dangerous activities
3. On match, the assistant turn is **truncated** (not edited mid-word
   — the regex engine returns the offset; we drop everything from the
   first match onward) and replaced with: "Let's pick a different topic
   — how about something fun?".

The filter is **idempotent**: filtering already-filtered output is a
no-op.

The regex catalogue is in:
- `shared/BuddyAICore/Sources/BuddyAICore/Domain/ContentPolicy.swift`
- `android/core/src/main/.../core/domain/ContentPolicy.kt`

…both fed by `Tests/.../ContentPolicyTests.swift` /
`ContentPolicyKtTest.kt` with 30 cases per language.

## §5 — Disabled features in Kid-safe

- **Roast Mode** — entire feature is hidden from the home grid.
- **Daily Challenges** that touch flagged categories — filtered out at
  template-selection time (`PromptTemplates` knows whether a template
  is kid-safe).
- **Party Question Generator** — runs against a kid-safe template
  variant only (no romance/dating themes).
- **Voice TTS** — locked to a "calm" voice (no upbeat / sarcastic
  presets).

## §6 — Audit trail (App Store / Play Store rating questionnaires)

When the App Review or Play Console asks "Does your app contain
user-generated open text?" the answer is yes and we link them to this
document. Specifically:

- **App Store age rating questionnaire** → "Frequent/Intense Cartoon or
  Fantasy Violence" = No; "Frequent/Intense Realistic Violence" = No;
  "Frequent/Intense Sexual Content or Nudity" = No; "Unrestricted Web
  Access" = No.
- **Google Play content rating** → matches the IARC questionnaire to a
  Teen rating with the Kid-safe profile noted.

The Kid-safe profile is positioned as a **parental control**, not a
substitute for adult supervision. The Consent screen on first launch
explicitly says so.

## §7 — Why not classifier-based moderation?

A Llama-Guard-style classifier model would be ~500 MB extra on disk and
~2× slower per-token. Regex deny-list + strict system prompt is the
right tradeoff for v1; v1.1 may revisit if false-positives are
unacceptably high.

## §8 — Reporting harmful output

Users can long-press an assistant message → **Report**. The report:

- Stores a local copy of the offending exchange in
  `Documents/offlineaibuddy/reports/<timestamp>.json`.
- Pre-fills a system mail compose to `safety@americangroupllc.com`
  (user can edit + send or cancel).
- Never sends without user action.
- Locally displays a "Thanks — we'll review this in the next app
  update" toast.

We do not collect telemetry on reports. The local file is the only
artifact.
