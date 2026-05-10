# Drift — watchOS

The Apple Watch app + WidgetKit complication.

## Generate the Xcode project

```sh
brew install xcodegen
cd watchos
xcodegen generate
open DriftWatch.xcodeproj
```

## Targets

- **DriftWatch** — Apple Watch app (watchOS 10+).
- **DriftWatchComplication** — WidgetKit complication that shows the
  current discovery layer + unread match count.

## What ships in v1

- **MatchesListView** — recent matches, tap → `QuickReplyView`.
- **QuickReplyView** — three suggested replies (Casual / Context /
  Playful) and a 1-tap "Wave back" on a pending Wave.
- **MatchesComplication** — small dot + count for the active layer.

The watch app is intentionally minimal in v1 — no discover, no profile
edit, no deep chat composition. See `../PRODUCTION.md` § "Watch
surfaces".

## Embedding into the iOS .ipa for App Store

The Apple Watch project is currently a **separate Xcode project** for
faster development. App Store submission requires it to be embedded in
the iOS app's `.ipa`. Migration plan: see
[`../STORE-PACKAGING.md`](../STORE-PACKAGING.md) § 1.
