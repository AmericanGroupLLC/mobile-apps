package com.americangroupllc.pocket.core.level

import kotlin.math.*

data class PitchRoll(val pitchDegrees: Double, val rollDegrees: Double)

object LevelMath {

    /** Convert a normalized gravity vector (gx, gy, gz) to pitch/roll in degrees. */
    fun pitchRoll(gx: Double, gy: Double, gz: Double): PitchRoll {
        val pitch = Math.toDegrees(atan2(-gx, sqrt(gy * gy + gz * gz)))
        val roll  = Math.toDegrees(atan2(gy, gz))
        return PitchRoll(pitch, roll)
    }

    /** Bullseye bubble offset, clamped to (radius) at ±maxAngle°. */
    fun bubbleOffset(pitch: Double, roll: Double, radius: Double, maxAngle: Double = 30.0): Pair<Double, Double> {
        val r = roll.coerceIn(-maxAngle, maxAngle)
        val p = pitch.coerceIn(-maxAngle, maxAngle)
        val scale = radius / maxAngle
        return r * scale to p * scale
    }

    fun isFlat(pitch: Double, roll: Double, threshold: Double = 30.0): Boolean =
        abs(pitch) < threshold && abs(roll) < threshold
}
