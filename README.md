# mobile-apps

Consolidated monorepo for AmericanGroupLLC's eight mobile products.
Each app lives under `apps/<name>/` with its full git history
preserved via subtree merges from the original per-app repos.

## Apps

| App | Stack | Build |
|---|---|---|
| `BuddyPlay` | Native Android (Kotlin DSL) | `cd apps/BuddyPlay && ./gradlew assembleDebug` |
| `Card` | Native Android (+ Wear OS) | `cd apps/Card && ./gradlew assembleDebug` |
| `ClockApp` | Native Android (+ Wear OS) | `cd apps/ClockApp && ./gradlew assembleDebug` |
| `DriftDate` | Native Android (+ Wear + backend) | `cd apps/DriftDate && ./gradlew assembleDebug` |
| `HealthApp` | Native Android (+ Wear OS) | `cd apps/HealthApp && ./gradlew assembleDebug` |
| `Offline-AI-Buddy` | Native Android (+ desktop) | `cd apps/Offline-AI-Buddy && ./gradlew assembleDebug` |
| `UrbanNeeds` | React Native (Android + iOS) | `cd apps/UrbanNeeds && yarn install && yarn android` |
| `Finoapp` | React Native (Android + iOS) — modern (RN 0.85, TS) | `cd apps/Finoapp && npm install && npm run android` |

## History

Full per-file history from before consolidation:

```bash
git log --follow -- apps/<app>/path/to/file
```

## Layout

```
apps/
  BuddyPlay/
  Card/
  ClockApp/
  DriftDate/
  Finoapp/
  HealthApp/
  Offline-AI-Buddy/
  UrbanNeeds/
```

## License

Proprietary. See [LICENSE](LICENSE).
