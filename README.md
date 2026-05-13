# mobile-apps

> 🏛 **Hub repo** — index, frozen historical snapshot, and umbrella for AmericanGroupLLC's eight mobile products. Each product is now also published as a **standalone repo** with its own CI, issue templates, license, and changelog.

The `apps/<name>/` snapshot below is preserved for in-place history browsing (`git log --follow -- apps/<app>/path/to/file` works back to each app's pre-consolidation origin). Active development happens in the per-app standalone repos.

## Standalone repos

Each app has been extracted via `git subtree split --prefix=apps/<name>` (full git history preserved) into its own repo on `master`. CI / issue templates / changelog scaffolded in each.

| App | Standalone repo | Stack | Quickstart |
|---|---|---|---|
| **BuddyPlay** | [`AmericanGroupLLC/BuddyPlay`](https://github.com/AmericanGroupLLC/BuddyPlay) | Android (Kotlin DSL) | `cd android && ./gradlew :app:assembleDebug` |
| **Card** | [`AmericanGroupLLC/Card`](https://github.com/AmericanGroupLLC/Card) | Android + Wear OS | `cd android && ./gradlew :app:assembleDebug :wear:assembleDebug` |
| **ClockApp** (*Pocket*) | [`AmericanGroupLLC/ClockApp`](https://github.com/AmericanGroupLLC/ClockApp) | Android + Wear OS | `cd android && ./gradlew :app:assembleDebug :wear:assembleDebug` |
| **DriftDate** (*Drift*) | [`AmericanGroupLLC/DriftDate`](https://github.com/AmericanGroupLLC/DriftDate) | Android + Wear + Supabase backend | `cd android && ./gradlew :app:assembleDebug :wear:assembleDebug` |
| **HealthApp** (*MyHealth*) | [`AmericanGroupLLC/HealthApp`](https://github.com/AmericanGroupLLC/HealthApp) | Android + Wear OS | `cd android && ./gradlew :app:assembleDebug :wear:assembleDebug` |
| **Offline-AI-Buddy** | [`AmericanGroupLLC/Offline-AI-Buddy`](https://github.com/AmericanGroupLLC/Offline-AI-Buddy) | Android + on-device LLM (`vendor/llama.cpp`) | `cd android && ./gradlew :app:assembleDebug` |
| **Finoapp** | [`AmericanGroupLLC/Finoapp`](https://github.com/AmericanGroupLLC/Finoapp) | React Native (RN 0.85, TypeScript) | `npm install && npm run android` |
| **UrbanNeeds** | [`AmericanGroupLLC/UrbanNeeds`](https://github.com/AmericanGroupLLC/UrbanNeeds) | React Native (Android + iOS) | `yarn install && yarn android` |

> 🚦 For day-to-day work — open a PR in the **standalone repo**. This umbrella is updated only on rare cross-app refactors.

## Frozen `apps/` snapshot (in-repo)

The `apps/` tree below is the snapshot at the time of split (2026-05-13). It is **not kept in sync** with the standalone repos. To browse history of any file from before the consolidation:

```bash
git log --follow -- apps/<app>/path/to/file
```

This works for every file in every app back to its pre-consolidation origin (preserved via the original subtree merges).

## Layout

```
apps/                        # frozen snapshot — see standalone repos for active dev
  BuddyPlay/
  Card/
  ClockApp/
  DriftDate/
  Finoapp/
  HealthApp/
  Offline-AI-Buddy/
  UrbanNeeds/
```

## When to use this repo vs a standalone repo

| Need | Where |
|---|---|
| Daily app development, PRs, issues | **Standalone repo** (links above) |
| Cross-app refactor (e.g., shared lint rule, shared CI snippet) | This umbrella |
| Browse pre-split history (`git log --follow`) | This umbrella |
| Ship a release / cut a tag | **Standalone repo** |
| Watch CI for one app | **Standalone repo** Actions tab |

## Re-extracting a standalone repo

If a standalone repo is ever lost or needs re-creation from scratch, the umbrella's `apps/<name>/` snapshot is the source of truth. The split tool is at `C:\Users\spatchava\.llms\plans\tools\split-mobile-apps.ps1` (run with `-DryRun` first).

## License

Proprietary. See [LICENSE](LICENSE). Each standalone repo carries its own MIT license for its source code.
