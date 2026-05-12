package com.myhealth.app.data.secure

import android.content.Context
import androidx.room.Database
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import net.sqlcipher.database.SQLiteDatabase
import net.sqlcipher.database.SupportFactory
import java.security.SecureRandom
import java.util.UUID

// ─── PHI entities ───────────────────────────────────────────────────────────

@Entity(tableName = "insurance_card")
data class InsuranceCardEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val payer: String? = null,
    val memberId: String? = null,
    val groupNumber: String? = null,
    val bin: String? = null,
    val pcn: String? = null,
    val rxGrp: String? = null,
    val capturedAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "provider")
data class ProviderEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val npi: String,
    val name: String,
    val specialty: String? = null,
    val phone: String? = null,
    val addressLine: String? = null,
    val zip: String? = null,
    val favoritedAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "rpe_log")
data class RpeLogEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val workoutSessionId: String? = null,
    val rating: Int,
    val loggedAt: Long = System.currentTimeMillis(),
    val notes: String? = null,
)

@Entity(tableName = "mychart_issuer")
data class MyChartIssuerEntity(
    @PrimaryKey val issuer: String,
    val displayName: String,
    val patientId: String? = null,
    val connectedAt: Long = System.currentTimeMillis(),
)

// ─── DAOs ───────────────────────────────────────────────────────────────────

@Dao
interface InsuranceCardDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(card: InsuranceCardEntity)

    @Query("SELECT * FROM insurance_card ORDER BY capturedAt DESC LIMIT 1")
    suspend fun latest(): InsuranceCardEntity?

    @Query("DELETE FROM insurance_card") suspend fun clear()
}

@Dao
interface ProviderDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(p: ProviderEntity)

    @Query("SELECT * FROM provider ORDER BY favoritedAt DESC")
    fun observeFavorites(): Flow<List<ProviderEntity>>

    @Query("DELETE FROM provider WHERE npi = :npi")
    suspend fun unfavorite(npi: String)

    @Query("DELETE FROM provider") suspend fun clear()
}

@Dao
interface RpeLogDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(log: RpeLogEntity)

    @Query("SELECT * FROM rpe_log ORDER BY loggedAt DESC LIMIT :limit")
    suspend fun recent(limit: Int = 20): List<RpeLogEntity>

    @Query("SELECT * FROM rpe_log ORDER BY loggedAt DESC")
    fun observeAll(): Flow<List<RpeLogEntity>>
}

@Dao
interface MyChartIssuerDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(issuer: MyChartIssuerEntity)

    @Query("SELECT * FROM mychart_issuer")
    fun observeAll(): Flow<List<MyChartIssuerEntity>>

    @Query("DELETE FROM mychart_issuer WHERE issuer = :issuer")
    suspend fun disconnect(issuer: String)
}

// ─── Database ───────────────────────────────────────────────────────────────

@Database(
    entities = [
        InsuranceCardEntity::class,
        ProviderEntity::class,
        RpeLogEntity::class,
        MyChartIssuerEntity::class,
    ],
    version = 1,
    exportSchema = false,
)
abstract class MyHealthPhiDatabase : RoomDatabase() {
    abstract fun insuranceCardDao(): InsuranceCardDao
    abstract fun providerDao(): ProviderDao
    abstract fun rpeLogDao(): RpeLogDao
    abstract fun myChartIssuerDao(): MyChartIssuerDao
}

/**
 * Provides the SQLCipher-backed PHI database. Passphrase is stored in
 * EncryptedSharedPreferences (`PHI_PASSPHRASE_FILE`); first call generates
 * a 32-byte random passphrase, every call after that re-uses the same one.
 *
 * If the EncryptedSharedPreferences file is wiped (PIN reset), the
 * passphrase is regenerated and the existing PHI DB becomes unreadable.
 * The user must re-link MyChart, re-snap their insurance card, etc. We
 * intentionally fail closed rather than risk leaking data.
 */
@Singleton
class PhiDatabaseProvider @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    companion object {
        private const val PHI_PASSPHRASE_FILE = "myhealth_phi_passphrase"
        private const val KEY_PASSPHRASE = "passphrase"
        private const val DB_NAME = "myhealth_phi.db"
    }

    private fun passphrase(): ByteArray {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build()
        val prefs = androidx.security.crypto.EncryptedSharedPreferences.create(
            context, PHI_PASSPHRASE_FILE, masterKey,
            androidx.security.crypto.EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            androidx.security.crypto.EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
        val existing = prefs.getString(KEY_PASSPHRASE, null)
        if (existing != null) return existing.toByteArray()
        val bytes = ByteArray(32).also { SecureRandom().nextBytes(it) }
        val str = bytes.joinToString("") { "%02x".format(it) }
        prefs.edit().putString(KEY_PASSPHRASE, str).apply()
        return str.toByteArray()
    }

    @Volatile private var db: MyHealthPhiDatabase? = null

    fun get(): MyHealthPhiDatabase {
        db?.let { return it }
        synchronized(this) {
            db?.let { return it }
            SQLiteDatabase.loadLibs(context)
            val factory = SupportFactory(passphrase())
            val instance = Room.databaseBuilder(context, MyHealthPhiDatabase::class.java, DB_NAME)
                .openHelperFactory(factory)
                .build()
            db = instance
            return instance
        }
    }
}
