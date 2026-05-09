package com.americangroupllc.offlineaibuddy.core.storage

import com.americangroupllc.offlineaibuddy.core.models.Profile
import com.google.common.truth.Truth.assertThat
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.util.UUID

class ProfilesStoreKtTest {

    @get:Rule val tmp = TemporaryFolder()

    @Test
    fun roundtrip_add_and_load() {
        val store = ProfilesStore(tmp.root)
        val p = Profile(id = UUID.randomUUID().toString(), name = "Sri", kind = Profile.Kind.ADULT)
        store.add(p)
        val all = store.loadAll()
        assertThat(all).hasSize(1)
        assertThat(all.first().name).isEqualTo("Sri")
    }

    @Test(expected = ProfilesStore.Duplicate::class)
    fun duplicate_throws() {
        val store = ProfilesStore(tmp.root)
        val p = Profile(id = UUID.randomUUID().toString(), name = "Sri", kind = Profile.Kind.ADULT)
        store.add(p)
        store.add(p)
    }

    @Test
    fun corrupt_json_falls_back_to_empty() {
        java.io.File(tmp.root, "profiles.json").writeText("not json")
        val store = ProfilesStore(tmp.root)
        assertThat(store.loadAll()).isEmpty()
    }

    @Test
    fun pin_hash_roundtrip() {
        val store = ProfilesStore(tmp.root)
        val salt = ProfilesStore.newSaltHex()
        val hash = ProfilesStore.pbkdf2Hex("1234", salt)
        val p = Profile(
            id = UUID.randomUUID().toString(),
            name = "Kid",
            kind = Profile.Kind.KID_SAFE,
            pinHash = hash,
            pinSalt = salt,
        )
        store.add(p)
        assertThat(store.verify("1234", p.id)).isTrue()
        assertThat(store.verify("0000", p.id)).isFalse()
    }
}
