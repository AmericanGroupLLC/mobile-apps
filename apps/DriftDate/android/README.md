# Drift — Android

Multi-module Gradle: `:core` (pure-Kotlin/JVM, shared logic), `:app` (phone),
`:wear` (Wear OS).

## Build

```sh
cd android
./gradlew :core:test                # pure-Kotlin/JVM tests — NOT testDebugUnitTest
./gradlew :app:lintDebug :app:testDebugUnitTest :app:assembleDebug
./gradlew :wear:testDebugUnitTest :wear:assembleDebug
./gradlew :app:connectedDebugAndroidTest    # Compose UI smoke (needs emulator)
```

Or use the shell helper:

```sh
../scripts/run-android-emulator.sh
./gradlew :app:installDebug :wear:installDebug
```

## Application IDs

- `com.americangroupllc.drift` (phone)
- `com.americangroupllc.driftwear` (Wear OS)

## Permissions

`:app/AndroidManifest.xml` declares:

- `INTERNET`
- `POST_NOTIFICATIONS`
- `RECEIVE_BOOT_COMPLETED`
- `CAMERA` (selfie + profile photos)
- `RECORD_AUDIO` (voice prompt)
- `ACCESS_COARSE_LOCATION` (only requested when user opts in to ZIP
  detection during onboarding)

**No Bluetooth permissions, no `ACCESS_FINE_LOCATION`.**

`:wear/AndroidManifest.xml` declares:

- `WAKE_LOCK`
- `POST_NOTIFICATIONS`

## Where things live

```
android/core/                     pure-Kotlin/JVM (NO Android deps)
  src/main/java/com/americangroupllc/drift/core/
    models/                       Profile, Photo, Wave, Conversation, Message, Tone, Intent, Layer, ReplySuggestion
    domain/                       LayerScorer, ToneClassifier, LocationFuzzer, ReplyPromptBuilder
    networking/                   Ktor SupabaseClient
    obs/                          AnalyticsService, CrashReportingService

android/app/                      phone app
  src/main/java/com/americangroupllc/drift/
    auth/      onboarding/  discover/  matches/  chat/
    profile/   settings/    safety/    verification/
    data/      di/          push/

android/wear/                     Wear OS
  src/main/java/com/americangroupllc/driftwear/
    matches/  quickreply/  tile/  complication/
```

## Module rules

- `:core` is **JVM-only**. No Android dependencies. Unit tests run via
  `:core:test`, **not** `:core:testDebugUnitTest`.
- `:app` and `:wear` both depend on `:core` and apply the Compose plugin.
- The Compose BOM is applied to **both** `implementation(...)` and
  `androidTestImplementation(...)` so `compose.ui:ui-test-junit4` resolves
  with a matching version. Removing it from one breaks the
  Compose smoke test.
- `:wear` pins `com.google.guava:guava:33.2.1-android` because the Wear
  Tiles + Complications APIs require `Futures.immediateFuture(...)`.

## Hilt + Room

- DI: Hilt. The `:app` `AppModule.kt` provides `SupabaseClient`,
  `AuthService`, `ChatService`, etc. Hilt-Compose integration via
  `androidx.hilt:hilt-navigation-compose`.
- Local cache: Room. `:app` uses Room only for **conversation drafts** and
  the **Realtime resync queue**. The source of truth is Supabase.
