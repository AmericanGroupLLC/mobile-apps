package com.americangroupllc.pocket.core.level

import com.google.common.truth.Truth.assertThat
import org.junit.Test
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

class LevelMathTest {
    @Test fun `perfectly flat`() {
        val pr = LevelMath.pitchRoll(0.0, 0.0, 1.0)
        assertThat(pr.pitchDegrees).isWithin(1e-6).of(0.0)
        assertThat(pr.rollDegrees).isWithin(1e-6).of(0.0)
        assertThat(LevelMath.isFlat(pr.pitchDegrees, pr.rollDegrees)).isTrue()
    }

    @Test fun `rolled right 45`() {
        val gy = sin(PI / 4); val gz = cos(PI / 4)
        val pr = LevelMath.pitchRoll(0.0, gy, gz)
        assertThat(pr.rollDegrees).isWithin(1e-3).of(45.0)
    }

    @Test fun `pitched forward 30`() {
        val gx = -sin(PI / 6); val gz = cos(PI / 6)
        val pr = LevelMath.pitchRoll(gx, 0.0, gz)
        assertThat(pr.pitchDegrees).isWithin(1e-3).of(30.0)
    }

    @Test fun `bubble offset proportional within bounds`() {
        val zero = LevelMath.bubbleOffset(0.0, 0.0, radius = 100.0)
        assertThat(zero.first).isWithin(1e-9).of(0.0)
        assertThat(zero.second).isWithin(1e-9).of(0.0)
        val mid = LevelMath.bubbleOffset(15.0, 15.0, radius = 100.0, maxAngle = 30.0)
        assertThat(mid.first).isWithin(1e-9).of(50.0)
        assertThat(mid.second).isWithin(1e-9).of(50.0)
        val max = LevelMath.bubbleOffset(100.0, -100.0, radius = 100.0, maxAngle = 30.0)
        assertThat(max.first).isWithin(1e-9).of(-100.0)
        assertThat(max.second).isWithin(1e-9).of(100.0)
    }

    @Test fun `isFlat threshold`() {
        assertThat(LevelMath.isFlat(5.0, -5.0)).isTrue()
        assertThat(LevelMath.isFlat(45.0, 0.0)).isFalse()
        assertThat(LevelMath.isFlat(0.0, -45.0)).isFalse()
    }
}
