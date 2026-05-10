package com.americangroupllc.card.data

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [CardEntity::class], version = 1, exportSchema = false)
abstract class CardDb : RoomDatabase() {
    abstract fun cardDao(): CardDao
}
