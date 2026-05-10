package com.americangroupllc.card.di

import android.content.Context
import androidx.room.Room
import com.americangroupllc.card.core.storage.CardRepository
import com.americangroupllc.card.data.CardDb
import com.americangroupllc.card.data.CardRepositoryImpl
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides @Singleton
    fun provideDb(@ApplicationContext ctx: Context): CardDb =
        Room.databaseBuilder(ctx, CardDb::class.java, "card.db").build()

    @Provides @Singleton
    fun provideDao(db: CardDb) = db.cardDao()

    @Provides @Singleton
    fun provideRepo(impl: CardRepositoryImpl): CardRepository = impl
}
