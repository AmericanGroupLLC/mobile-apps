package com.myhealth.core.exercises

import kotlinx.serialization.Serializable

@Serializable enum class MuscleGroup {
    chest, back, lats, traps, shoulders, biceps, triceps, forearms,
    core, obliques, lowerBack,
    glutes, quads, hamstrings, calves, adductors, abductors;

    val label: String get() = when (this) {
        chest -> "Chest"; back -> "Back"; lats -> "Lats"; traps -> "Traps"
        shoulders -> "Shoulders"; biceps -> "Biceps"; triceps -> "Triceps"
        forearms -> "Forearms"; core -> "Core"; obliques -> "Obliques"
        lowerBack -> "Lower Back"; glutes -> "Glutes"; quads -> "Quads"
        hamstrings -> "Hamstrings"; calves -> "Calves"
        adductors -> "Adductors"; abductors -> "Abductors"
    }
}

@Serializable enum class Equipment {
    bodyweight, dumbbell, barbell, kettlebell, cable, machine, band, cardio, other;

    val label: String get() = when (this) {
        bodyweight -> "Bodyweight"; dumbbell -> "Dumbbell"; barbell -> "Barbell"
        kettlebell -> "Kettlebell"; cable -> "Cable"; machine -> "Machine"
        band -> "Band"; cardio -> "Cardio"; other -> "Other"
    }
}

@Serializable enum class ExerciseDifficulty {
    beginner, intermediate, advanced;

    val label: String get() = name.replaceFirstChar { it.uppercase() }
}

@Serializable
data class Exercise(
    val id: String,
    val name: String,
    val primaryMuscles: List<MuscleGroup>,
    val secondaryMuscles: List<MuscleGroup> = emptyList(),
    val equipment: Equipment,
    val difficulty: ExerciseDifficulty,
    val instructions: List<String>,
    val formTips: List<String> = emptyList(),
    val videoURL: String? = null,
    val isStretch: Boolean = false,
)

object ExerciseLibrary {
    val exercises: List<Exercise> = listOf(
        Exercise(
            id = "bench-press", name = "Bench Press",
            primaryMuscles = listOf(MuscleGroup.chest),
            secondaryMuscles = listOf(MuscleGroup.triceps, MuscleGroup.shoulders),
            equipment = Equipment.barbell, difficulty = ExerciseDifficulty.intermediate,
            instructions = listOf(
                "Lie flat on a bench, eyes under the bar.",
                "Grip slightly wider than shoulder width.",
                "Unrack and lower the bar to mid-chest.",
                "Press up explosively without locking out.",
            ),
            formTips = listOf("Keep shoulder blades retracted.", "Feet planted firmly.")
        ),
        Exercise(
            id = "push-up", name = "Push-Up",
            primaryMuscles = listOf(MuscleGroup.chest),
            secondaryMuscles = listOf(MuscleGroup.triceps, MuscleGroup.core),
            equipment = Equipment.bodyweight, difficulty = ExerciseDifficulty.beginner,
            instructions = listOf(
                "Plank position, hands shoulder width.",
                "Lower chest to within an inch of the floor.",
                "Press back up keeping a straight body line.",
            )
        ),
        Exercise(
            id = "incline-db-press", name = "Incline Dumbbell Press",
            primaryMuscles = listOf(MuscleGroup.chest), secondaryMuscles = listOf(MuscleGroup.shoulders),
            equipment = Equipment.dumbbell, difficulty = ExerciseDifficulty.intermediate,
            instructions = listOf("Bench at 30°.", "Press dumbbells from shoulder to lockout.")
        ),
        Exercise(
            id = "deadlift", name = "Deadlift",
            primaryMuscles = listOf(MuscleGroup.back, MuscleGroup.hamstrings, MuscleGroup.glutes),
            secondaryMuscles = listOf(MuscleGroup.lowerBack, MuscleGroup.forearms),
            equipment = Equipment.barbell, difficulty = ExerciseDifficulty.advanced,
            instructions = listOf(
                "Bar over mid-foot.",
                "Hinge at hips, grip the bar.",
                "Drive through heels, keep bar close to body.",
                "Stand tall, then reverse the motion.",
            )
        ),
        Exercise(
            id = "pull-up", name = "Pull-Up",
            primaryMuscles = listOf(MuscleGroup.lats),
            secondaryMuscles = listOf(MuscleGroup.biceps, MuscleGroup.back),
            equipment = Equipment.bodyweight, difficulty = ExerciseDifficulty.advanced,
            instructions = listOf("Dead hang, palms away.", "Pull chest to bar.", "Lower with control.")
        ),
        Exercise(
            id = "barbell-row", name = "Barbell Row",
            primaryMuscles = listOf(MuscleGroup.back, MuscleGroup.lats),
            secondaryMuscles = listOf(MuscleGroup.biceps),
            equipment = Equipment.barbell, difficulty = ExerciseDifficulty.intermediate,
            instructions = listOf("Hinge at hips.", "Row to lower chest.", "Lower under control.")
        ),
        Exercise(
            id = "squat", name = "Back Squat",
            primaryMuscles = listOf(MuscleGroup.quads, MuscleGroup.glutes),
            secondaryMuscles = listOf(MuscleGroup.hamstrings, MuscleGroup.core),
            equipment = Equipment.barbell, difficulty = ExerciseDifficulty.intermediate,
            instructions = listOf("Bar across upper traps.", "Sit hips down between heels.", "Drive up through mid-foot.")
        ),
        Exercise(
            id = "lunge", name = "Walking Lunge",
            primaryMuscles = listOf(MuscleGroup.quads, MuscleGroup.glutes),
            equipment = Equipment.bodyweight, difficulty = ExerciseDifficulty.beginner,
            instructions = listOf("Step forward.", "Drop knee to inch above floor.", "Drive forward to next lunge.")
        ),
        Exercise(
            id = "run-easy", name = "Easy Run",
            primaryMuscles = listOf(MuscleGroup.quads, MuscleGroup.calves),
            equipment = Equipment.cardio, difficulty = ExerciseDifficulty.beginner,
            instructions = listOf("Conversational pace.", "Land mid-foot.", "Relax shoulders.")
        ),
        Exercise(
            id = "row-erg", name = "Rowing Erg",
            primaryMuscles = listOf(MuscleGroup.back, MuscleGroup.lats),
            equipment = Equipment.cardio, difficulty = ExerciseDifficulty.intermediate,
            instructions = listOf("Drive legs first.", "Then back, then arms.", "Reverse smoothly.")
        ),
        Exercise(
            id = "childs-pose", name = "Child's Pose",
            primaryMuscles = listOf(MuscleGroup.lowerBack),
            equipment = Equipment.bodyweight, difficulty = ExerciseDifficulty.beginner,
            instructions = listOf("Knees wide.", "Hips to heels.", "Reach forward, breathe."),
            isStretch = true
        ),
        Exercise(
            id = "pigeon", name = "Pigeon Pose",
            primaryMuscles = listOf(MuscleGroup.glutes),
            equipment = Equipment.bodyweight, difficulty = ExerciseDifficulty.intermediate,
            instructions = listOf("Front shin parallel to mat.", "Lower chest to floor.", "Hold 60s per side."),
            isStretch = true
        ),
        Exercise(
            id = "couch-stretch", name = "Couch Stretch",
            primaryMuscles = listOf(MuscleGroup.quads),
            equipment = Equipment.bodyweight, difficulty = ExerciseDifficulty.intermediate,
            instructions = listOf("Back foot up on couch.", "Hips forward.", "Hold 60s per side."),
            isStretch = true
        ),
    )

    fun byId(id: String) = exercises.firstOrNull { it.id == id }
    fun search(query: String) = exercises.filter { it.name.contains(query, ignoreCase = true) }
    fun filter(
        muscle: MuscleGroup? = null,
        equipment: Equipment? = null,
        difficulty: ExerciseDifficulty? = null,
        includeStretches: Boolean = true
    ): List<Exercise> = exercises.filter { e ->
        (muscle == null || e.primaryMuscles.contains(muscle) || e.secondaryMuscles.contains(muscle)) &&
        (equipment == null || e.equipment == equipment) &&
        (difficulty == null || e.difficulty == difficulty) &&
        (includeStretches || !e.isStretch)
    }
}

@Serializable
data class ProgramDay(
    val name: String,
    val exerciseIds: List<String>,
    val sets: Int,
    val repRange: String,
    val restSeconds: Int,
)

@Serializable
data class WorkoutProgram(
    val id: String,
    val name: String,
    val summary: String,
    val weeks: Int,
    val daysPerWeek: Int,
    val split: String,
    val level: ExerciseDifficulty,
    val days: List<ProgramDay>,
)

object WorkoutPrograms {
    val all: List<WorkoutProgram> = listOf(
        WorkoutProgram(
            id = "ppl", name = "Push / Pull / Legs",
            summary = "Classic 6-day split that hits every muscle twice a week.",
            weeks = 8, daysPerWeek = 6, split = "PPL",
            level = ExerciseDifficulty.intermediate,
            days = listOf(
                ProgramDay("Push A", listOf("bench-press", "incline-db-press", "push-up"),
                    sets = 4, repRange = "6-10", restSeconds = 120),
                ProgramDay("Pull A", listOf("deadlift", "pull-up", "barbell-row"),
                    sets = 4, repRange = "6-10", restSeconds = 120),
                ProgramDay("Legs A", listOf("squat", "lunge"),
                    sets = 4, repRange = "8-12", restSeconds = 120),
            )
        ),
        WorkoutProgram(
            id = "upper-lower", name = "Upper / Lower",
            summary = "Balanced 4-day split, great for busy weeks.",
            weeks = 8, daysPerWeek = 4, split = "Upper/Lower",
            level = ExerciseDifficulty.intermediate,
            days = listOf(
                ProgramDay("Upper A", listOf("bench-press", "barbell-row", "pull-up"),
                    sets = 4, repRange = "6-10", restSeconds = 120),
                ProgramDay("Lower A", listOf("squat", "lunge"),
                    sets = 4, repRange = "6-10", restSeconds = 120),
            )
        ),
        WorkoutProgram(
            id = "full-body", name = "Full Body 3x",
            summary = "Whole-body sessions three days a week.",
            weeks = 6, daysPerWeek = 3, split = "Full Body",
            level = ExerciseDifficulty.beginner,
            days = listOf(
                ProgramDay("Day A", listOf("squat", "bench-press", "barbell-row"),
                    sets = 3, repRange = "8-12", restSeconds = 90),
            )
        ),
        WorkoutProgram(
            id = "beginner-strength", name = "Beginner Strength",
            summary = "12-week linear progression for new lifters.",
            weeks = 12, daysPerWeek = 3, split = "Linear",
            level = ExerciseDifficulty.beginner,
            days = listOf(
                ProgramDay("A", listOf("squat", "bench-press", "deadlift"),
                    sets = 3, repRange = "5", restSeconds = 180),
            )
        ),
    )

    fun byId(id: String) = all.firstOrNull { it.id == id }
}
