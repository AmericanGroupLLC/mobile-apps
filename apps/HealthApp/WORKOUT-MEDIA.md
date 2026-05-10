# MyHealth — Workout Media + Condition-Aware Suggestions

> **Doctor's advice always wins.** This document covers how MyHealth shows
> exercise GIFs, filters workouts by user-declared health conditions, and
> serves diet suggestions tuned to those conditions — without ever being a
> medical device.

---

## 1. Where the medical-decision line is drawn

| Capability | What MyHealth does | Medical-device classification |
|---|---|---|
| Show a workout GIF | ✅ generic instructional content | wellness app |
| Skip "back squat" when user declared low-back pain | ✅ heuristic filter | wellness app |
| Show "DASH foods" when user declared hypertension | ✅ public-health guidance | wellness app |
| Diagnose hypertension from BP readings | ❌ never | would be SaMD |
| Recommend a specific medication or dosage | ❌ never | strictly regulated |
| Detect arrhythmia from heart-rate data | ❌ never | FDA-cleared territory |

Per the FDA Software-as-a-Medical-Device guidance, MyHealth stays firmly in
the **wellness** category by:
- Never producing a diagnosis
- Never recommending medication
- Never claiming clinical accuracy
- Showing a **doctor disclaimer** banner on every condition-driven screen

---

## 2. Health conditions the user can declare (opt-in)

Stored locally in UserDefaults / DataStore. Never sent to the server.
Never logged via analytics. Always editable from
**Settings → Health profile**.

| Category | Conditions |
|---|---|
| Cardiovascular | High BP · Low BP · Heart condition |
| Metabolic | Type-1 diabetes · Type-2 diabetes · Obesity (BMI ≥ 30) |
| Respiratory | Asthma |
| Musculoskeletal | Knee · Ankle · Shoulder · Lower back · Osteoporosis |
| Other | Pregnancy · Kidney issue · Liver issue · Anemia |
| Default | None — full library available |

---

## 3. Workout filtering rules

The shared `ExerciseMedia` map drives both platforms (iOS + Android use the
same exercise IDs and same condition rules).

```
ExerciseLibrary.recommended(for: userConditions)
   ↓
   filter out anything in ExerciseMedia.cautions[exerciseId] ∩ userConditions
   ↓
   sort by overlap with ExerciseMedia.benefits[exerciseId] ∩ userConditions
   ↓
   return safe + tailored list
```

### Examples

| User condition | Hidden exercise | Why |
|---|---|---|
| Hypertension | Back Squat, Deadlift, OHP | Valsalva manoeuvre causes BP spike |
| Knee injury | Walking Lunge, Goblet Squat | Heavy knee flexion |
| Pregnancy | Crunches, Pullup, Heavy Squat, Downward Dog | Inversions, abdominal compression, fall risk |
| Osteoporosis | Heavy Squat, Deadlift | Spinal compression risk |
| Heart condition | Treadmill Run, Jump Rope | Until cleared by cardiologist |

### Beneficial exercises (boosted to top)

| Condition | Exercises promoted |
|---|---|
| Lower back pain | Cat-Cow, Child's Pose, Hip Thrust, Hip Flexor Stretch |
| Hypertension | Rowing Machine (low-impact, controlled breathing) |
| Type-2 diabetes | Push-up, Dumbbell Press, Rowing Machine |
| Osteoporosis | Lateral Raise, Calf Raise (gentle weight-bearing) |
| Asthma | Neck Rolls, Doorway Pec Stretch (low-intensity) |

---

## 4. Workout media (GIFs / videos)

### Asset hosting

```
https://americangroupllc.github.io/HealthApp/assets/exercises/<exercise-id>.gif
https://americangroupllc.github.io/HealthApp/assets/exercises/<exercise-id>.jpg
```

Hosted on the existing **GitHub Pages** marketing site — zero extra
infrastructure cost. The repo's `marketing.yml` workflow already deploys
that site, so dropping new GIFs into `/assets/exercises/` ships them
worldwide for free.

### Why URLs instead of bundled assets

- **Lightweight install** — base APK / IPA stays under 25 MB
- **Updateable without app review** — fix a wrong GIF without shipping a new app version
- **Lazy-loaded** — only the exercises the user actually opens are downloaded
- **Graceful fallback** — if the GIF 404s, the SF Symbol / Material icon shows instead

### Override via env var

Set `EXERCISE_MEDIA_BASE_URL` at build time (Xcode / Gradle) to point at a
private CDN if you don't want to use GitHub Pages.

### Where to source GIFs (free / CC-licensed)

| Source | Licence | Quality |
|---|---|---|
| [Wger.de exercise database](https://wger.de/en/software/api) | CC-BY-SA 4.0 | Static images, decent coverage |
| [Wikimedia Commons](https://commons.wikimedia.org/wiki/Category:Exercise) | Various OSS | Mixed |
| [Pexels free workout videos](https://www.pexels.com/search/videos/workout/) | Pexels free licence | High quality, easy to convert to GIF |
| Record your own | – | Best fit for app brand |

A small `scripts/fetch-exercise-gifs.sh` could pull from wger.de's API and
drop the results into `assets/exercises/`. Not yet automated — manual upload works.

---

## 5. Diet suggestions

Pure on-device static map in `DietSuggestionsService`. For each condition,
returns:

- **Pattern** — Mediterranean, DASH, low-GI, low-sodium, etc.
- **Foods to favor** — 6-10 specific items
- **Foods to limit** — 4-6 specific items
- **Daily targets** — sodium / fiber / protein / etc. caps
- **Notes** — 1-2 sentence rationale

### Sources

The mappings are based on widely-published public-health dietary patterns:
- DASH (NIH / NHLBI) for hypertension
- Mediterranean (PREDIMED study) for heart + asthma
- ADA standards for diabetes
- KDOQI guidelines for kidney
- ACOG guidelines for pregnancy
- NIH ODS for osteoporosis

These are **public consensus guidance**, not personalized prescriptions.
The disclaimer banner on every screen makes that explicit.

---

## 6. iOS implementation

| File | Role |
|---|---|
| `shared/FitFusionCore/.../Health/HealthConditions.swift` | enum + ObservableObject store |
| `shared/FitFusionCore/.../Exercises/ExerciseMedia.swift` | URL catalogue + cautions/benefits maps |
| `shared/FitFusionCore/.../Diet/DietSuggestionsService.swift` | static catalogue |
| `ios/FitFusion/Views/More/HealthProfileView.swift` | Settings → Health profile screen |
| `ios/FitFusion/Views/Diary/DietSuggestionsView.swift` | Diary tab → Diet suggestions screen |

The existing exercise list views automatically benefit because
`ExerciseLibrary.recommended(for: conditions)` filters at the data layer.

To embed a GIF in any exercise detail view:

```swift
AsyncImage(url: ExerciseMedia.gifURL(for: exercise.id)) { phase in
    switch phase {
    case .success(let image): image.resizable().aspectRatio(contentMode: .fit)
    default: Image(systemName: exercise.equipment.systemImage)
    }
}
.frame(maxHeight: 240)
```

---

## 7. Android implementation

| File | Role |
|---|---|
| `android/core/.../health/HealthConditions.kt` | enum + medical map (mirrors Swift) |
| (Settings screen toggle) | TODO — wire same way as crash-reports toggle |
| (Compose Coil GIF loader) | `AsyncImage(model = ExerciseMedia.gifUrl(id))` |

To render a GIF in Compose:

```kotlin
val imageLoader = ImageLoader.Builder(LocalContext.current)
    .components { add(GifDecoder.Factory()) }
    .build()
AsyncImage(
    model = ExerciseMedia.gifUrl(exercise.id),
    contentDescription = null,
    imageLoader = imageLoader,
    placeholder = painterResource(R.drawable.ic_exercise_placeholder),
)
```

---

## 8. Doctor-disclaimer policy

**Every** screen that uses `HealthConditionsStore` data MUST display:

> ⚕️ This is general guidance — not medical advice. Always check with your
> doctor before starting a new workout or diet plan.

iOS implementation: a 12-pt orange banner at the top of the screen (see
`HealthProfileView` and `DietSuggestionsView`).

Android implementation: same banner using `MaterialTheme.colorScheme.tertiary`.

The store also tracks `lastDoctorReview` and prompts the user every 6 months
to re-confirm their condition list.

---

## 9. What this is NOT

- ❌ Not an insulin-dosing calculator
- ❌ Not a heart-arrhythmia detector
- ❌ Not an ECG interpreter
- ❌ Not a meal-planner with calorie totals (we don't auto-build menus)
- ❌ Not a replacement for a physician, dietitian, or PT

Stay on the wellness side of the regulatory line, ship freely on App Store
and Play Store as a fitness app, and clearly label every condition-driven
suggestion with the doctor banner.
