package com.myhealth.app.data.room

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [
        ProfileEntity::class,
        MealEntity::class,
        ActivityEntity::class,
        MedicineEntity::class,
        DoseLogEntity::class,
        MoodEntity::class,
        ExerciseLogEntity::class,
        CustomMealEntity::class,
        CustomWorkoutEntity::class,
    ],
    version = 1,
    exportSchema = false,
)
abstract class MyHealthDatabase : RoomDatabase() {
    abstract fun profileDao(): ProfileDao
    abstract fun mealDao(): MealDao
    abstract fun activityDao(): ActivityDao
    abstract fun medicineDao(): MedicineDao
    abstract fun doseLogDao(): DoseLogDao
    abstract fun moodDao(): MoodDao
    abstract fun exerciseLogDao(): ExerciseLogDao
    abstract fun customMealDao(): CustomMealDao
    abstract fun customWorkoutDao(): CustomWorkoutDao
}
