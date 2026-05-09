package com.myhealth.app.data.room

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(tableName = "profile")
data class ProfileEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String? = null,
    val birthDateISO: String? = null,
    val sex: String = "female",
    val heightCm: Double? = null,
    val weightKg: Double? = null,
    val goal: String = "maintain",
    val activityLevel: String? = null,
    val unitsImperial: Boolean = false,
    val themeMode: String = "system",
    val language: String = "en",
    val updatedAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "meals")
data class MealEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val kcal: Double,
    val protein: Double,
    val carbs: Double,
    val fat: Double,
    val barcode: String? = null,
    val consumedAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "activities")
data class ActivityEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val kind: String,
    val durationMin: Double,
    val kcalBurned: Double = 0.0,
    val notes: String? = null,
    val performedAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "medicines")
data class MedicineEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val dosage: String,
    val unit: String,
    val manufacturer: String? = null,
    val priceCents: Int = 0,
    val criticalLevel: String = "low",
    val eatWhen: String = "standalone",
    val scheduleJSON: String,
    val colorHex: String = "#5B8DEF",
    val notes: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val archivedAt: Long? = null,
)

@Entity(tableName = "dose_logs")
data class DoseLogEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val medicineId: String,
    val scheduledFor: Long,
    val takenAt: Long? = null,
    val snoozedAt: Long? = null,
    val skipped: Boolean = false,
)

@Entity(tableName = "mood_entries")
data class MoodEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val value: Int,
    val note: String? = null,
    val recordedAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "exercise_logs")
data class ExerciseLogEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val exerciseId: String,
    val performedAt: Long = System.currentTimeMillis(),
    val setsJSON: String,
    val notes: String? = null,
)

@Entity(tableName = "custom_meals")
data class CustomMealEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    @ColumnInfo(name = "components_json") val componentsJSON: String,
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "custom_workouts")
data class CustomWorkoutEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val exerciseIdsJSON: String,
    val createdAt: Long = System.currentTimeMillis(),
)
