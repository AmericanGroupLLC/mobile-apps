# Drift — TESTING

## 1. Test gate matrix

| Layer | How to verify | Where it runs |
|---|---|---|
| Backend schema | `supabase db reset && supabase db diff` shows clean migration | CI `backend.yml` |
| Edge Function tests | `deno test backend/supabase/functions/**/_test.ts` | CI `backend.yml` |
| RLS test suite | hand-written SQL test that two distinct roles can/cannot see each other's profiles per layer | CI `backend.yml` |
| `DriftCore` Swift Package | `xcodebuild test -scheme DriftCore-Package -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'` | CI `ci.yml` + `ios.yml` |
| iOS app build | `xcodegen generate && xcodebuild build -sdk iphonesimulator` | CI `ios.yml` |
| iOS XCUITest smoke | mock Supabase → onboarding → discover → wave → chat → reply suggestion picker | CI `ios.yml` |
| watchOS build smoke | `xcodebuild build -sdk watchsimulator` | CI `ci.yml` + `ios.yml` |
| Android `:core` | `./gradlew :core:test` (Kotlin/JVM, **NOT** `:core:testDebugUnitTest`) | CI `ci.yml` |
| Android `:app` | `./gradlew :app:lintDebug :app:testDebugUnitTest :app:assembleDebug` | CI `ci.yml` |
| Wear `:wear` | `./gradlew :wear:testDebugUnitTest :wear:assembleDebug` | CI `ci.yml` |
| Android Compose UI smoke | `./gradlew :app:connectedDebugAndroidTest` walks discover → wave → chat | CI `android.yml` |
| Marketing site lint | `npx htmlhint`, `npx stylelint` | CI `ci.yml` |

## 2. The four pure-logic keystone tests (XCTest **and** JUnit, mirrored)

The same scenarios run on both `shared/DriftCore/Tests/DriftCoreTests/` and
`android/core/src/test/java/com/americangroupllc/drift/core/domain/`.

### `LayerScorer`

- Same-ZIP, both verified, both `.dating` intent → score ≥ 0.85.
- Different state, no shared interests → score < 0.30.
- Tied scores break by `recent_activity` recency.
- Weighting follows: 30% intent, 20% layer, 15% interests, 15% verification,
  10% recency, 10% conversation likelihood.

### `ToneClassifier`

- 5-min gap between messages → `.slow`.
- 10 messages within 5 min → `.energetic`.
- Average message length > 200 chars → `.deep`.
- Pattern *"want to grab"* / *"meet up"* / *"coffee"* → `.meetupReady`.

### `LocationFuzzer`

- Identical input never round-trips out of the function (no
  `Coordinate(lat:, lon:)` field on the output).
- ZIP prefix is always exactly 3 chars.
- Out-of-state coordinates resolve to a non-nil `stateCode`.
- Garbage input (e.g. lat=999) returns `nil` rather than throwing.

### `ReplyPromptBuilder`

- Golden-output snapshot test for fixed inputs.
- Both profiles' `display_name`, `intent`, top vibe tag appear in the system
  prompt.
- Last 5 messages appear in chronological order (oldest → newest).
- Tone-specific clause appears when `tone == .meetupReady`.

These four files must compile + test green on **both** Swift and Kotlin
before any UI work happens for that release.

## 3. Manual checks

### Selfie verification end-to-end (real device)

- [ ] Open onboarding → Photos → upload 6 photos.
- [ ] Tag one as the verification reference.
- [ ] Open Verification → live preview detects face → tap capture.
- [ ] Edge Function logs show `CompareFaces ≥ 0.9`.
- [ ] Profile gets verified-checkmark; chat unlocks on next match.

### Realtime chat (two devices)

- [ ] Device A and Device B match.
- [ ] A sends a message.
- [ ] B receives it via Realtime in **< 1 s**.

### Layer fuzzing

- [ ] Enable Location on the client.
- [ ] Inspect Edge Function logs → only `zipPrefix3 / countyFips / stateCode`
  is present in any incoming POST. **No raw `lat` / `lon`.**

### Push (iOS)

- [ ] Real iPhone receives a match notification.
- [ ] Rich-push preview shows the matched user's display name + thumbnail.
- [ ] Tap → opens to the conversation.

### Push (Android)

- [ ] Real Android receives a match notification.
- [ ] Expanded notification shows quick-reply input.
- [ ] Quick-reply types into a draft and lands as a real message.

### Watch complication (Apple Watch)

- [ ] Add complication to a watch face.
- [ ] Unread match count visible.
- [ ] Tap → quick-reply view.

### Wear OS tile

- [ ] Add tile from Tile Carousel.
- [ ] Unread match count visible.
- [ ] Tap → quick-reply.

## 4. Coverage targets

- `shared/DriftCore/Sources/DriftCore/Domain/` — **100%** branch coverage.
  Pure logic, zero excuses.
- `shared/DriftCore/Sources/DriftCore/Networking/` — ≥ 70% line coverage with
  URLSession mocks.
- `android/core/src/main/java/com/americangroupllc/drift/core/domain/` — **100%**.
- All other source ≥ 60% line coverage where reasonable; UI screens
  asserted by Compose UI / XCUITest smokes.
