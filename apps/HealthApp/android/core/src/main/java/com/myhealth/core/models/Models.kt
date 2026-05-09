package com.myhealth.core.models

import kotlinx.serialization.Serializable

// MARK: - Profile

@Serializable enum class Sex { female, male, other }

@Serializable enum class HealthGoal {
    lose_weight, maintain, build_muscle, endurance, general_wellness
}

@Serializable
data class Profile(
    val id: String,
    val name: String? = null,
    val birthDateISO: String? = null,
    val sex: Sex = Sex.female,
    val heightCm: Double? = null,
    val weightKg: Double? = null,
    val goal: HealthGoal = HealthGoal.maintain,
    val activityLevel: String? = null,
    val unitsImperial: Boolean = false,
    val themeMode: String = "system",
    val language: String = "en",
    val updatedAt: String? = null,
)

// MARK: - Meal & nutrition

@Serializable
data class Meal(
    val id: String,
    val name: String,
    val kcal: Double,
    val protein: Double,
    val carbs: Double,
    val fat: Double,
    val barcode: String? = null,
    val consumedAt: String? = null,
)

@Serializable
data class MealComponent(
    val foodId: String,
    val name: String,
    val grams: Double,
)

@Serializable
data class CustomMeal(
    val id: String,
    val name: String,
    val components: List<MealComponent> = emptyList(),
    val createdAt: String? = null,
)

// MARK: - Activity

@Serializable
data class Activity(
    val id: String,
    val kind: String,
    val durationMin: Double,
    val kcalBurned: Double = 0.0,
    val notes: String? = null,
    val performedAt: String? = null,
)

// MARK: - Medicine

@Serializable enum class CriticalLevel { low, medium, high }
@Serializable enum class EatWhen { standalone, before, with_food, after }

@Serializable
data class TimeOfDay(val hour: Int, val minute: Int)

@Serializable
data class MedicineSchedule(
    val times: List<TimeOfDay> = listOf(TimeOfDay(9, 0)),
    val weekdays: Set<Int> = (1..7).toSet(),
    val startISO: String? = null,
    val endISO: String? = null,
)

@Serializable
data class Medicine(
    val id: String,
    val name: String,
    val dosage: String = "",
    val unit: String = "tablet",
    val manufacturer: String? = null,
    val priceCents: Int = 0,
    val criticalLevel: CriticalLevel = CriticalLevel.low,
    val eatWhen: EatWhen = EatWhen.standalone,
    val schedule: MedicineSchedule = MedicineSchedule(),
    val colorHex: String = "#5B8DEF",
    val notes: String? = null,
    val createdAt: String? = null,
    val archivedAt: String? = null,
)

@Serializable
data class DoseLog(
    val id: String,
    val medicineId: String,
    val scheduledFor: String,
    val takenAt: String? = null,
    val snoozedAt: String? = null,
    val skipped: Boolean = false,
)

// MARK: - Mood / state of mind

@Serializable
data class MoodEntry(
    val id: String,
    val value: Int,    // 1-5
    val note: String? = null,
    val recordedAt: String? = null,
)

@Serializable
data class StateOfMind(
    val id: String,
    val label: String? = null,
    val valence: Double,        // -1..1
    val arousal: Double = 0.0,  //  0..1
    val context: String? = null,
    val recordedAt: String? = null,
)

// MARK: - Workouts

@Serializable
data class WorkoutPlan(
    val id: String,
    val templateId: String,
    val scheduledFor: String,
    val notes: String? = null,
    val createdAt: String? = null,
)

@Serializable
data class LoggedSet(val reps: Int, val weight: Double)

@Serializable
data class ExerciseLog(
    val id: String,
    val exerciseId: String,
    val performedAt: String,
    val sets: List<LoggedSet>,
    val notes: String? = null,
)

@Serializable
data class CustomWorkout(
    val id: String,
    val name: String,
    val exerciseIds: List<String>,
    val createdAt: String? = null,
)

// MARK: - Social

@Serializable
data class Friend(
    val id: String,
    val name: String,
    val handle: String,
    val recordID: String? = null,
    val addedAt: String? = null,
)

@Serializable
data class Challenge(
    val id: String,
    val title: String,
    val kind: String, // steps / distance_km / minutes / workouts
    val startsAt: String,
    val endsAt: String,
    val target: Double,
    val joinedAt: String? = null,
)

@Serializable
data class Badge(
    val id: String,
    val slug: String,
    val title: String,
    val subtitle: String,
    val awardedAt: String,
)

@Serializable
data class Streak(
    val id: String,
    val kind: String,
    val currentDays: Int,
    val longestDays: Int,
    val lastDay: String?,
)
