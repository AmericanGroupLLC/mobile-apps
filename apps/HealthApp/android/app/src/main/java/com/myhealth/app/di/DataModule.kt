package com.myhealth.app.di

import android.content.Context
import androidx.room.Room
import com.myhealth.app.data.room.ActivityDao
import com.myhealth.app.data.room.CustomMealDao
import com.myhealth.app.data.room.CustomWorkoutDao
import com.myhealth.app.data.room.DoseLogDao
import com.myhealth.app.data.room.ExerciseLogDao
import com.myhealth.app.data.room.MealDao
import com.myhealth.app.data.room.MedicineDao
import com.myhealth.app.data.room.MoodDao
import com.myhealth.app.data.room.MyHealthDatabase
import com.myhealth.app.data.room.ProfileDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DataModule {

    @Provides @Singleton
    fun provideDatabase(@ApplicationContext context: Context): MyHealthDatabase =
        Room.databaseBuilder(context, MyHealthDatabase::class.java, "myhealth.db")
            .fallbackToDestructiveMigration()
            .build()

    @Provides fun provideProfileDao(db: MyHealthDatabase): ProfileDao = db.profileDao()
    @Provides fun provideMealDao(db: MyHealthDatabase): MealDao = db.mealDao()
    @Provides fun provideActivityDao(db: MyHealthDatabase): ActivityDao = db.activityDao()
    @Provides fun provideMedicineDao(db: MyHealthDatabase): MedicineDao = db.medicineDao()
    @Provides fun provideDoseLogDao(db: MyHealthDatabase): DoseLogDao = db.doseLogDao()
    @Provides fun provideMoodDao(db: MyHealthDatabase): MoodDao = db.moodDao()
    @Provides fun provideExerciseLogDao(db: MyHealthDatabase): ExerciseLogDao = db.exerciseLogDao()
    @Provides fun provideCustomMealDao(db: MyHealthDatabase): CustomMealDao = db.customMealDao()
    @Provides fun provideCustomWorkoutDao(db: MyHealthDatabase): CustomWorkoutDao = db.customWorkoutDao()
}
