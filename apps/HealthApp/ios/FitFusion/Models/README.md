# Bundled Core ML models

The on-device AI features expect two `.mlmodel` (or `.mlpackage`) assets in this
folder. They are **not** committed to git because:

1. Training data + Create ML license decisions are out of scope for the codebase.
2. Binary model files bloat the repo and don't diff cleanly.

When the files are missing, `AdaptivePlanner` and `MealPhotoRecognizer` **fall
back gracefully** — `AdaptivePlanner` uses a deterministic heuristic, and
`MealPhotoRecognizer.classify(image:)` returns an empty array (the UI falls
back to manual text search). So the app builds and runs without the models.

---

## `AdaptivePlanner.mlmodel`

A small Create ML **tabular regressor** that picks the next workout. Expected
shape:

| Input feature | Type | Range |
|---|---|---|
| `readiness`      | Double | 0 … 100 |
| `hrv`            | Double | -1 (missing) … ~100 ms |
| `sleep`          | Double | -1 (missing) … 12 h |
| `weekly_minutes` | Double | -1 (missing) … 600 min |
| `rpe`            | Double | -1 (missing) … 10 |

| Output feature | Type | Notes |
|---|---|---|
| `template_id`  | String | Must be one of `WorkoutLibrary.templates[*].id` |
| `confidence`   | Double | 0 … 1 (optional; defaults to 0.6) |
| `rationale`    | String | Free-form text shown on the Home dashboard (optional) |

**How to produce it:**

1. Open Create ML on macOS → choose **Tabular Regression** (or Classification).
2. Train on synthetic + open fitness data (e.g. OpenWorkout, public HRV/sleep
   sets) using the columns above.
3. Export → `AdaptivePlanner.mlmodel` → drop here → re-run `xcodegen generate`.

`PersonalFineTuner` then runs nightly via `BGTaskScheduler` to personalize the
model on the user's recent data — **never leaves the device**.

---

## `FoodClassifier.mlmodel`

A small image classifier (~3-5 MB) that returns a top-N labeled food list.
Acceptable sources:

- **Food-101** Apple Create ML pretrained classifier (academic license)
- **Apple's "Food Classifier" sample model** in the Core ML Models gallery
- A custom Create ML Image Classifier trained on a subset of Food-101 / Open
  Images

Drop it here as `FoodClassifier.mlmodel` (or `FoodClassifier.mlpackage`).
The class labels can be free-form (e.g. `"Banana"`, `"Cheeseburger"`,
`"Caesar salad"`) — `MealPhotoSheet` will pass each label as a search query
to the existing `NutritionService` (Open Food Facts) for ground-truth macros.

---

## XcodeGen integration

When the files are present, the iOS target's `sources:` already picks up
everything in `ios/FitFusion/`, so no `project.yml` change is needed — just
drop the file in and rebuild.

If you want Xcode to compile the model into a `.mlmodelc` resource (recommended
for production), add a Run Script build phase or use Xcode's automatic Core ML
compilation by including the file in the target's "Compile Sources" phase
(default behavior for `.mlmodel` files).
