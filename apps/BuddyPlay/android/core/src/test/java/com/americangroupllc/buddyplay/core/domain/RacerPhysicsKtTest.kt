package com.americangroupllc.buddyplay.core.domain

import com.americangroupllc.buddyplay.core.models.Peer
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class RacerPhysicsKtTest {

    private fun newGame(): Triple<RacerState, String, String> {
        val h = Peer("00000000-0000-0000-0000-000000000001", "H", Peer.Platform.IOS, 0L)
        val g = Peer("00000000-0000-0000-0000-000000000002", "G", Peer.Platform.ANDROID, 0L)
        return Triple(RacerPhysics.initialState(h, g), h.id, g.id)
    }

    @Test
    fun tickIsDeterministic() {
        var (s1, h, g) = newGame()
        var (s2, _, _) = newGame()
        val input = RacerInput(h, throttle = 1.0, brake = 0.0, steering = 0.2)
        s1.cars[h] = s1.cars[h]!!.copy(lastInput = input)
        s2.cars[h] = s2.cars[h]!!.copy(lastInput = input)
        repeat(60) {
            s1 = RacerPhysics.tick(s1, dtMillis = 33)
            s2 = RacerPhysics.tick(s2, dtMillis = 33)
        }
        assertThat(s1.cars[h]!!.x).isEqualTo(s2.cars[h]!!.x)
        assertThat(s1.cars[h]!!.y).isEqualTo(s2.cars[h]!!.y)
        assertThat(s1.cars[h]!!.heading).isEqualTo(s2.cars[h]!!.heading)
        assertThat(s1.cars[g]!!.x).isEqualTo(s2.cars[g]!!.x)
    }

    @Test
    fun throttleAccelerates() {
        var (s, h, _) = newGame()
        s.cars[h] = s.cars[h]!!.copy(lastInput = RacerInput(h, 1.0, 0.0, 0.0))
        val initial = s.cars[h]!!.speed
        repeat(10) { s = RacerPhysics.tick(s, dtMillis = 33) }
        assertThat(s.cars[h]!!.speed).isGreaterThan(initial)
    }

    @Test
    fun wallBouncesVelocity() {
        var (s, h, _) = newGame()
        s.cars[h] = RacerCar(
            x = RacerPhysics.TRACK_WIDTH - 0.1, y = 30.0,
            heading = 0.0, speed = RacerPhysics.MAX_SPEED, lastInput = null,
        )
        s = RacerPhysics.tick(s, dtMillis = 33)
        assertThat(s.cars[h]!!.x).isAtMost(RacerPhysics.TRACK_WIDTH)
        assertThat(s.cars[h]!!.speed).isLessThan(0.0)
    }

    @Test
    fun idleDecaySlowsCar() {
        var (s, h, _) = newGame()
        s.cars[h] = s.cars[h]!!.copy(speed = 20.0, lastInput = null)
        repeat(10) { s = RacerPhysics.tick(s, dtMillis = 33) }
        assertThat(s.cars[h]!!.speed).isLessThan(20.0)
    }
}
