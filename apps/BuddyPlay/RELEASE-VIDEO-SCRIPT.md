# Release Video Script — BuddyPlay

This file drives the silent MP4 release video built by the umbrella's
`release-video.yml` reusable workflow at tag time.

Each `## Heading | <duration_seconds>` defines one scene. Within
the scene, list keys as bullets. Recognised keys:

- `viewport: WIDTHxHEIGHT` (default 1280x720)
- `scroll: <px|%|top|bottom>` (default 0)
- `wait: <seconds|ms>` (dwell time after navigation)
- `caption: <text>` (placeholders `{APP_NAME}` and `{VERSION}`)
- `duration: <seconds>` (override the heading-level duration)

The intro and outro cards (3 s each) are auto-generated from the
brand colour in `release.config.json`.

> **Tagline:** Play together, even when you're apart.

---

## Hero — top of marketing site | 4
- viewport: 1280x720
- scroll: top
- wait: 600ms
- caption: {APP_NAME} {VERSION}

## Features overview | 5
- viewport: 1280x720
- scroll: 25%
- wait: 600ms
- caption: New in {VERSION}

## Highlight reel | 5
- viewport: 1280x720
- scroll: 50%
- wait: 600ms
- caption: Built for everyone

## What's next | 5
- viewport: 1280x720
- scroll: 75%
- wait: 600ms
- caption: Available everywhere

## Call to action — bottom of page | 4
- viewport: 1280x720
- scroll: bottom
- wait: 800ms
- caption: Try {APP_NAME} today
