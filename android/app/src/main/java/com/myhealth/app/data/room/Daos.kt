package com.myhealth.app.data.room

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface ProfileDao {
    @Query("SELECT * FROM profile LIMIT 1")
    fun observe(): Flow<ProfileEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(profile: ProfileEntity)
}

@Dao
interface MealDao {
    @Query("SELECT * FROM meals ORDER BY consumedAt DESC LIMIT :limit")
    fun observeRecent(limit: Int = 200): Flow<List<MealEntity>>

    @Query("SELECT * FROM meals WHERE consumedAt >= :sinceMillis ORDER BY consumedAt DESC")
    fun observeSince(sinceMillis: Long): Flow<List<MealEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(meal: MealEntity)

    @Update
    suspend fun update(meal: MealEntity)

    @Query("DELETE FROM meals WHERE id = :id")
    suspend fun delete(id: String)
}

@Dao
interface ActivityDao {
    @Query("SELECT * FROM activities ORDER BY performedAt DESC")
    fun observeAll(): Flow<List<ActivityEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(a: ActivityEntity)

    @Query("DELETE FROM activities WHERE id = :id")
    suspend fun delete(id: String)
}

@Dao
interface MedicineDao {
    @Query("SELECT * FROM medicines WHERE archivedAt IS NULL ORDER BY createdAt DESC")
    fun observeActive(): Flow<List<MedicineEntity>>

    @Query("SELECT * FROM medicines WHERE id = :id LIMIT 1")
    suspend fun get(id: String): MedicineEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(m: MedicineEntity)

    @Update
    suspend fun update(m: MedicineEntity)
}

@Dao
interface DoseLogDao {
    @Query("SELECT * FROM dose_logs WHERE medicineId = :medicineId ORDER BY scheduledFor DESC LIMIT :limit")
    fun observeFor(medicineId: String, limit: Int = 60): Flow<List<DoseLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(d: DoseLogEntity)
}

@Dao
interface MoodDao {
    @Query("SELECT * FROM mood_entries ORDER BY recordedAt DESC LIMIT :limit")
    fun observeRecent(limit: Int = 30): Flow<List<MoodEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(m: MoodEntity)
}

@Dao
interface ExerciseLogDao {
    @Query("SELECT * FROM exercise_logs WHERE exerciseId = :exerciseId ORDER BY performedAt DESC LIMIT :limit")
    fun observeFor(exerciseId: String, limit: Int = 50): Flow<List<ExerciseLogEntity>>

    @Query("SELECT * FROM exercise_logs ORDER BY performedAt DESC LIMIT :limit")
    fun observeRecent(limit: Int = 100): Flow<List<ExerciseLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(l: ExerciseLogEntity)
}

@Dao
interface CustomMealDao {
    @Query("SELECT * FROM custom_meals ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<CustomMealEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(m: CustomMealEntity)
}

@Dao
interface CustomWorkoutDao {
    @Query("SELECT * FROM custom_workouts ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<CustomWorkoutEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(w: CustomWorkoutEntity)
}
