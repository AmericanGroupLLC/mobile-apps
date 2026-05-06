package com.americangroupllc.buddyplay.core.domain

import com.americangroupllc.buddyplay.core.models.Peer
import com.google.common.truth.Truth.assertThat
import org.junit.Test
import java.util.UUID

class HostElectionKtTest {

    private fun peer(id: String, platform: Peer.Platform = Peer.Platform.IOS, name: String = "p") =
        Peer(id, name, platform, 0L)

    @Test
    fun lexicographicallySmallerIdWins() {
        val a = peer("00000000-0000-0000-0000-000000000001")
        val b = peer("00000000-0000-0000-0000-000000000002")
        assertThat(HostElection.host(a, b).id).isEqualTo(a.id)
        assertThat(HostElection.host(b, a).id).isEqualTo(a.id) // symmetric
        assertThat(HostElection.guest(a, b).id).isEqualTo(b.id)
    }

    @Test
    fun platformTiebreakOnSameUUID() {
        val id = UUID.randomUUID().toString()
        val ios = Peer(id, "A", Peer.Platform.IOS, 0L)
        val android = Peer(id, "B", Peer.Platform.ANDROID, 0L)
        assertThat(HostElection.host(ios, android).platform).isEqualTo(Peer.Platform.IOS)
        assertThat(HostElection.host(android, ios).platform).isEqualTo(Peer.Platform.IOS)
    }

    @Test
    fun deterministicOver100Pairs() {
        repeat(100) {
            val a = peer(UUID.randomUUID().toString())
            val b = peer(UUID.randomUUID().toString())
            assertThat(HostElection.host(a, b).id).isEqualTo(HostElection.host(b, a).id)
        }
    }
}
