# Card — Product spec

A single page on what the product is, what the loop is, and what every quick-
capture surface does. For architecture see [`DESIGN.md`](DESIGN.md). For the
manual checklist see [`TESTING.md`](TESTING.md).

---

## 1. The promise

> Nothing you write gets forgotten or ignored.

A user opens Card and types or dictates anything. It becomes a Card. With one
tap, the same Card is a note, a task, or a reminder. The app gets out of the
way; the OS handles the firing.

---

## 2. The single loop

```
   ┌────────────┐    ┌──────────────┐    ┌──────────────┐    ┌─────────────┐
   │  Capture   │ →  │  Stored as   │ →  │  (optional)  │ →  │  OS fires   │
   │            │    │   a Card     │    │  Convert →   │    │  reminder   │
   └────────────┘    └──────────────┘    │ task/reminder│    └─────────────┘
                                          └──────────────┘
```

Every screen in the app is a stop on this loop:

- **Composer** is the entry to "Capture".
- **Feed** is the home for "Stored".
- **Action sheet** is the home for "Convert".
- The OS notification stack is the home for "Fires".

There is no fifth concept.

---

## 3. The Card kinds

Every Card has exactly one kind.

| Kind         | UI affordance                       | Persistence rule                                |
|--------------|-------------------------------------|-------------------------------------------------|
| `.note`      | Plain row                           | Just text + timestamps                          |
| `.task`      | Row with leading checkbox           | Adds `completedAt: Date?`                       |
| `.reminder`  | Row with date chip                  | Adds `reminderAt: Date` (must be in the future) |

Conversions are reversible: `note → task → reminder → note` is legal and
clears the irrelevant fields each step. See `CardKindTransitions` in
`shared/CardCore/Sources/CardCore/Domain/`.

---

## 4. The four quick-capture surfaces

| Surface                          | Trigger                                  | What happens                                                                 |
|----------------------------------|------------------------------------------|------------------------------------------------------------------------------|
| **iOS Share Extension**          | Share sheet → "Card – Save"             | Selected text is wrapped in a Card and written to the App Group's `CardStore`. The main app is **not** launched. |
| **Apple Watch complication**     | Tap "Card – Quick capture" complication  | Launches the watch composer with `SFSpeechRecognizer` already armed.         |
| **Android Quick Settings tile**  | Pull down twice → tap **Card** tile      | Launches `QuickCaptureActivity`, a single-screen voice composer.             |
| **Wear OS tile**                 | Tap the Card tile in the tile carousel   | Launches the wear composer with dictation already armed.                     |

The point of all four is the same: **the user does not have to open the main
app to write something down**. Friction tax = zero.

---

## 5. Settings (one screen, six controls)

1. **Time format** — 12-hour ↔ 24-hour. Affects the reminder picker and the
   reminder chip on each row.
2. **Theme** — System ↔ Light ↔ Dark. Wraps SwiftUI's `.preferredColorScheme`
   and Compose's `MaterialTheme`.
3. **Send crash reports** (off by default). When on, Sentry initializes and
   captures uncaught exceptions and explicit `CrashReportingService.capture(...)`
   calls.
4. **Send anonymous usage data** (off by default). When on, PostHog initializes
   and `AnalyticsService.track(event)` calls flow.
5. **About** — version + GitHub link.
6. **Erase all data** — confirm dialog → wipes the local store. Done. No
   server hand-shake; the cards are gone.

---

## 6. What is deliberately missing

The product is brutal about scope. Every "what about…?" gets the same answer:
*not in v1*.

- Tags, folders, projects, categories.
- Search.
- Cloud sync, account login, multi-device sync of any kind.
- Sharing or collaboration.
- AI auto-classification, summarization, or rewording.
- Recurring reminders.
- Themes beyond System / Light / Dark.
- iOS WidgetKit home-screen widget.
- Android Glance home-screen widget.
- Multiple feeds (Today / Done / etc.).
- IAP / subscription scaffolding.

Rationale: every one of those is a category where Apple Notes / Google Keep /
Things / Bear / Any.do already wins. Card's only job is to be **the lowest-
friction capture-and-convert primitive on every device you own**.
