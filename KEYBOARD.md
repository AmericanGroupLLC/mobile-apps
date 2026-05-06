# KEYBOARD.md

How the system smart-reply keyboard works on each platform.

## §1 — Why a custom keyboard at all

The product promise is "AI smart replies in any chat app". The only way
to reach **every** chat app (Messages, WhatsApp, Slack, Telegram,
Signal, Reddit, …) without those apps integrating with us is by
becoming the user's system keyboard. Both iOS (Keyboard Extension) and
Android (`InputMethodService`) expose this affordance.

## §2 — Why the keyboard is a thin client

Both platforms cap keyboard memory hard:
- **iOS Keyboard Extension** — soft cap ~70 MB resident; OOM kill above
  ~120 MB. A 1 GB GGUF + the llama.cpp arena (~3 GB peak) blows past
  this by 25×.
- **Android InputMethodService** — runs in-process to the keyboard's
  own application sandbox; theoretically unlimited but the IME is
  expected to be lightweight (the IME picker and switching latency
  presume <100 ms cold start).

Therefore the keyboard does NOT host the LLM. The keyboard is a
**thin client** that hands the chat context off to the **main app**
process, which holds the long-lived `LlamaRunner` and streams 3
suggestions back.

## §3 — IPC: iOS

```
Keyboard Extension                       Main app
─────────────────                       ─────────
1. User opens keyboard
   in some chat app
2. Read context from
   `UIInputViewController.
    textDocumentProxy`
3. Write {context, requestId} to
   shared file URL inside
   `group.com.americangroupllc.
        offlineaibuddy`
4. Post Darwin notification
   `com.americangroupllc.
        offlineaibuddy.kb.request`
                                        5. KeyboardBridgeListener
                                           wakes up (if main app
                                           is running)
                                        6. LlamaRunner generates
                                           3 suggestions
                                        7. Write {requestId,
                                           suggestions[3]} to a
                                           shared file
                                        8. Post Darwin notification
                                           `com.americangroupllc.
                                                offlineaibuddy.kb.reply`
9. Read shared file,
   render 3 chips
10. User taps a chip → insert
    into `textDocumentProxy`
```

`Info.plist` of the keyboard sets `RequestsOpenAccess = false` — the
keyboard does NOT need full network. App Group shared storage is
sufficient.

## §4 — IPC: Android

```
InputMethodService                       Main app
──────────────────                       ─────────
1. IME displays
2. Read context from
   `getCurrentInputConnection()`
3. Send Intent to
   InferenceContentProvider
   with {context, requestId}
                                        4. ContentProvider routes to
                                           bound `InferenceService`
                                        5. LlamaService generates
                                           3 suggestions
                                        6. Write back via the same
                                           ContentProvider's
                                           `update()` URI
7. Query the `replies/<requestId>`
   URI, render 3 chips
8. User taps a chip → commitText()
```

`InferenceContentProvider` is exported with
`android:exported="true"` BUT protected by a signature-level
permission so only the main app's IME (signed with the same cert) can
read replies. Documented in `AndroidManifest.xml`.

## §5 — Fallback when the main app isn't running

iOS keyboard extensions **cannot launch the host app
programmatically** (rejected by App Review since iOS 8). When the
main app's `KeyboardBridgeListener` does NOT respond within 800 ms, the
keyboard renders an **"Open Offline AI Buddy"** chip in the candidate
strip. Tapping it opens the main app via a `URL`-scheme handler the OS
allows for any user-initiated tap. The user then returns to the chat
app and the suggestions appear a few seconds later.

Android does not have this restriction — the IME can `startActivity()`
the main app directly with `Intent.FLAG_ACTIVITY_NEW_TASK`.

## §6 — Privacy guarantees

- The keyboard reads ONLY the input field of the currently-focused chat
  app. It cannot see other apps' content.
- The chat context never leaves the device.
- The keyboard does NOT persist context — it is read from
  `UITextDocumentProxy` / `InputConnection` on each keystroke and
  discarded after the suggestion round.
- The main app's `LlamaRunner` runs the suggestion request in the
  same isolated profile context as the user's last-active in-app chat
  (so kid-safe filtering applies if the active profile is Kid-safe).

## §7 — Latency budget

| Step | Target |
|---|---|
| Keystroke → IPC roundtrip start | < 50 ms |
| LLM 3-suggestion generation | < 700 ms (8 t/s × ~30 tokens × 3) |
| IPC reply → chip render | < 50 ms |
| **Total keystroke → chip update** | **< 800 ms** |

If the user is typing faster than 0.8 s/keystroke, we debounce and only
fire on a 250 ms typing pause.

## §8 — Failure modes + UX

| Failure | UX |
|---|---|
| Main app not running (iOS) | "Open Offline AI Buddy" chip. |
| Model not yet downloaded | "Open Offline AI Buddy to finish setup" chip. |
| Quota exhausted (free tier) | "Watch ad to keep getting smart replies" chip. |
| LLM error (rare) | Empty candidate strip, no error toast — silently fall back to system suggestions. |

## §9 — Disable + uninstall

The keyboard can be disabled at any time from system Settings → Keyboard
→ Keyboards. Uninstalling the main app also removes the keyboard
extension on iOS; on Android the IME is unregistered as part of app
removal.
