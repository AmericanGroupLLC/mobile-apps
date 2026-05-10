package com.americangroupllc.buddyplay.core.storage

import com.americangroupllc.buddyplay.core.models.GameKind
import com.americangroupllc.buddyplay.core.models.Rivalry
import com.google.common.truth.Truth.assertThat
import org.junit.After
import org.junit.Before
import org.junit.Test
import java.io.File
import java.util.UUID

class LocalRivalryStoreKtTest {

    private lateinit var dir: File

    @Before
    fun setup() {
        dir = File(System.getProperty("java.io.tmpdir"), "buddyplay-test-${UUID.randomUUID()}")
        dir.mkdirs()
    }

    @After
    fun teardown() {
        dir.deleteRecursively()
    }

    @Test
    fun emptyOnFirstLoad() {
        val store = LocalRivalryStore(dir)
        assertThat(store.loadAll()).isEmpty()
    }

    @Test
    fun writeReadIncrement() {
        val store = LocalRivalryStore(dir)
        val opp = UUID.randomUUID().toString()
        store.record(opp, "Sarah", GameKind.CHESS, Rivalry.Outcome.WIN)
        store.record(opp, "Sarah", GameKind.CHESS, Rivalry.Outcome.WIN)
        store.record(opp, "Sarah", GameKind.CHESS, Rivalry.Outcome.LOSS)

        val r = store.load(opp)
        assertThat(r).isNotNull()
        assertThat(r!!.perGame[GameKind.CHESS]?.wins).isEqualTo(2)
        assertThat(r.perGame[GameKind.CHESS]?.losses).isEqualTo(1)
        assertThat(r.perGame[GameKind.CHESS]?.draws).isEqualTo(0)
    }

    @Test
    fun differentGamesTallyIndependently() {
        val store = LocalRivalryStore(dir)
        val opp = UUID.randomUUID().toString()
        store.record(opp, "S", GameKind.CHESS, Rivalry.Outcome.WIN)
        store.record(opp, "S", GameKind.LUDO,  Rivalry.Outcome.LOSS)
        store.record(opp, "S", GameKind.RACER, Rivalry.Outcome.DRAW)
        val r = store.load(opp)!!
        assertThat(r.perGame[GameKind.CHESS]?.wins).isEqualTo(1)
        assertThat(r.perGame[GameKind.LUDO]?.losses).isEqualTo(1)
        assertThat(r.perGame[GameKind.RACER]?.draws).isEqualTo(1)
    }

    @Test
    fun eraseAllWipes() {
        val store = LocalRivalryStore(dir)
        store.record(UUID.randomUUID().toString(), "Sarah", GameKind.CHESS, Rivalry.Outcome.WIN)
        assertThat(store.loadAll()).isNotEmpty()
        store.eraseAll()
        assertThat(store.loadAll()).isEmpty()
    }

    @Test
    fun corruptJsonFallsBackToEmpty() {
        val store = LocalRivalryStore(dir)
        File(dir, "rivalries.json").writeText("{not valid json")
        assertThat(store.loadAll()).isEmpty()
    }
}
