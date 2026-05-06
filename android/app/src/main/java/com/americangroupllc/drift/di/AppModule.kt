package com.americangroupllc.drift.di

import com.americangroupllc.drift.core.networking.SupabaseClient
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides @Singleton
    fun provideSupabaseClient(): SupabaseClient {
        // BuildConfig fields are populated from env in :app/build.gradle.kts.
        // Default to the local Supabase emulator.
        val url  = System.getenv("SUPABASE_URL")     ?: "http://10.0.2.2:54321"
        val anon = System.getenv("SUPABASE_ANON_KEY") ?: "anon-local"
        return SupabaseClient(baseUrl = url, anonKey = anon)
    }
}
