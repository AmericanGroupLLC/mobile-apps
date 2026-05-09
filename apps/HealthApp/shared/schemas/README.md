# MyHealth Cross-Platform Schema

Single canonical JSON shape for **every entity** that lives in the local DB on
both **iOS Core Data** and **Android Room**. Both apps export to (and import
from) this format via Settings → Export / Import, so users can move their
entire MyHealth profile between an iPhone and an Android device by AirDrop /
Files / Drive — **no backend account required**.

The schema lives in [`myhealth.schema.json`](./myhealth.schema.json) (JSON
Schema 2020-12).

## Mapping table

| Entity | iOS Core Data entity | Android Room entity | JSON key in backup file |
|---|---|---|---|
| Profile | `ProfileEntity` | `ProfileRoomEntity` | `profile` (single object) |
| Meal | `MealEntity` | `MealRoomEntity` | `meals[]` |
| Activity | `ActivityEntity` | `ActivityRoomEntity` | `activities[]` |
| Medicine | `MedicineEntity` | `MedicineRoomEntity` | `medicines[]` |
| Dose log | `MedicineDoseLogEntity` | `MedicineDoseLogRoomEntity` | `doseLogs[]` |
| Mood entry | `MoodEntryEntity` | `MoodRoomEntity` | `moodEntries[]` |
| State of Mind | `StateOfMindEntity` | `StateOfMindRoomEntity` | `stateOfMind[]` |
| Workout plan | `WorkoutPlanEntity` | `WorkoutPlanRoomEntity` | `workoutPlans[]` |
| Exercise log | `ExerciseLogEntity` | `ExerciseLogRoomEntity` | `exerciseLogs[]` |
| Custom workout | `CustomWorkoutEntity` | `CustomWorkoutRoomEntity` | `customWorkouts[]` |
| Custom meal | `CustomMealEntity` | `CustomMealRoomEntity` | `customMeals[]` |
| Friend | `FriendEntity` | `FriendRoomEntity` | `friends[]` |
| Challenge | `ChallengeEntity` | `ChallengeRoomEntity` | `challenges[]` |
| Badge | `BadgeEntity` | `BadgeRoomEntity` | `badges[]` |
| Streak | `StreakEntity` | `StreakRoomEntity` | `streaks[]` |

## Conventions

- All `id` fields are RFC 4122 UUIDs (lowercase, hyphenated). They MUST be
  stable across export/import — re-importing the same backup is a no-op.
- All timestamps are ISO 8601 with timezone (`2026-05-02T14:30:00Z`). Apps
  parse these in the user's local timezone for display.
- Numeric fields default to 0. Strings default to empty.
- Optional fields are simply omitted when absent — importers must tolerate
  missing keys.
- "Stringified JSON" fields (`scheduleJSON`, `setsJSON`, `componentsJSON`,
  `exerciseIdsJSON`) are kept as strings for storage simplicity. The shape
  inside is defined in the matching subschema (`MedicineSchedule`) or in the
  app's own model layer (`LoggedSet`, `MealComponent`).
- Backup files are **not encrypted** by default — they leave the device in
  the same trust boundary as the photo / file the user shares them as. iOS
  ShareSheet and Android Intent.ACTION_SEND respect the user's choice of
  destination.

## Migration

Bumping `schemaVersion` is reserved for **breaking** changes (renaming or
removing a field). Adding a new optional field is **non-breaking** and does
not require a version bump. When loading a backup with an older
`schemaVersion`, the importer fills in defaults for any newly-required
fields.

## Implementations

- iOS exporter: [`ios/FitFusion/Services/PortabilityService.swift`](../../ios/FitFusion/Services/PortabilityService.swift)
- iOS importer: same file (via `importBackup(from:)` — TODO once the file
  picker is wired in Settings).
- Android exporter / importer: `android/app/.../data/portability/PortabilityService.kt`
- Reference test data: `shared/schemas/sample-backup.json` (not committed
  yet; produced by exporting from a fresh simulator).
