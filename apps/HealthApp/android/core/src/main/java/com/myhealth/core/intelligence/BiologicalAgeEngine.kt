package com.myhealth.core.intelligence

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/**
 * On-device biological-age heuristic — Kotlin port of the Swift
 * `BiologicalAgeEngine`. Same weights, same disclaimers: not a medical claim.
 */
object BiologicalAgeEngine {

    enum class Sex { female, male, other }
    enum class Direction { better, neutral, worse }

    data class Inputs(
        val chronologicalYears: Double,
        val sex: Sex,
        val restingHR: Double? = null,
        val hrv: Double? = null,
        val vo2Max: Double? = null,
        val avgSleepHours: Double? = null,
        val bmi: Double? = null,
        val bodyFatPct: Double? = null,
        val systolicBP: Double? = null,
        val diastolicBP: Double? = null,
        val weeklyExerciseMin: Double? = null,
        val stepsPerDay: Double? = null,
        val smoker: Boolean = false,
        val heavyAlcohol: Boolean = false,
    )

    data class Factor(
        val name: String,
        val value: String,
        val deltaYears: Double,
        val direction: Direction,
    )

    data class Result(
        val chronologicalYears: Double,
        val biologicalYears: Double,
        val confidence: Double,
        val factors: List<Factor>,
    ) {
        val deltaYears: Double get() = biologicalYears - chronologicalYears
        val verdict: String get() = when {
            deltaYears < -3        -> "Significantly younger than your age 🚀"
            deltaYears < -0.5      -> "Younger than your age ✨"
            deltaYears < 0.5       -> "Right on track"
            deltaYears < 3         -> "Slightly older than your age"
            deltaYears < 7         -> "Notably older — worth attention"
            else                   -> "Much older — consider lifestyle changes ⚠️"
        }
    }

    fun estimate(i: Inputs): Result {
        val factors = mutableListOf<Factor>()

        i.restingHR?.let { rhr ->
            val d = clamp((rhr - 60) * 0.15, -3.0, 5.0)
            factors += Factor("Resting HR", "${rhr.toInt()} bpm", d, dir(d))
        }
        i.hrv?.let { hrv ->
            val d = clamp(-((hrv - 35) / 10.0) * 0.6, -3.0, 4.0)
            factors += Factor("HRV (SDNN)", "${hrv.toInt()} ms", d, dir(d))
        }
        i.vo2Max?.let { vo2 ->
            val target = if (i.sex == Sex.female) 32.0 else 38.0
            val d = clamp(-((vo2 - target) / 5.0) * 0.7, -4.0, 5.0)
            factors += Factor("VO₂ Max", "%.1f ml/kg/min".format(vo2), d, dir(d))
        }
        i.avgSleepHours?.let { sleep ->
            val off = abs(sleep - 7.5)
            val d = clamp(off * 0.5, 0.0, 4.0)
            val direction = if (off < 0.5) Direction.better
                else if (off < 1.0) Direction.neutral else Direction.worse
            factors += Factor("Avg sleep", "%.1f h".format(sleep), d, direction)
        }
        i.bmi?.let { bmi ->
            val d = when {
                bmi < 18.5 -> (18.5 - bmi) * 0.4
                bmi > 25 -> (bmi - 25) * 0.4
                else -> 0.0
            }
            factors += Factor("BMI", "%.1f".format(bmi), clamp(d, 0.0, 5.0),
                if (d > 0.5) Direction.worse else Direction.neutral)
        }
        i.bodyFatPct?.let { bf ->
            val target = if (i.sex == Sex.female) 0.25 else 0.18
            val d = max(0.0, bf - target) * 25
            factors += Factor("Body fat", "${(bf * 100).toInt()}%", clamp(d, 0.0, 4.0),
                if (d > 0.3) Direction.worse else Direction.neutral)
        }
        i.systolicBP?.let { sys ->
            val d = when {
                sys > 130 -> (sys - 130) / 10.0 * 0.7
                sys < 90 -> (90 - sys) / 10.0 * 0.5
                else -> 0.0
            }
            factors += Factor("Blood pressure",
                "${sys.toInt()}/${(i.diastolicBP ?: 0.0).toInt()} mmHg",
                clamp(d, 0.0, 4.0),
                if (d > 0.5) Direction.worse else Direction.neutral)
        }
        i.weeklyExerciseMin?.let { exMin ->
            val d = clamp(-(min(exMin, 300.0) - 150) / 50.0 * 0.6, -2.5, 2.5)
            factors += Factor("Weekly exercise", "${exMin.toInt()} min / wk", d, dir(d))
        }
        i.stepsPerDay?.let { steps ->
            val d = clamp(-(min(steps, 12000.0) - 7500) / 1500.0 * 0.4, -1.5, 2.0)
            factors += Factor("Daily steps", steps.toInt().toString(), d, dir(d))
        }
        if (i.smoker) factors += Factor("Smoking", "Yes", 6.0, Direction.worse)
        if (i.heavyAlcohol) factors += Factor("Heavy alcohol", "Yes", 3.0, Direction.worse)

        val total = factors.sumOf { it.deltaYears }
        val bio = max(15.0, min(120.0, i.chronologicalYears + total))
        val possible = 11.0
        val confidence = max(0.2, min(1.0, factors.size / possible))

        return Result(
            chronologicalYears = i.chronologicalYears,
            biologicalYears = bio,
            confidence = confidence,
            factors = factors.sortedByDescending { abs(it.deltaYears) }
        )
    }

    private fun clamp(v: Double, lo: Double, hi: Double) = min(max(v, lo), hi)
    private fun dir(d: Double): Direction = when {
        d < -0.25 -> Direction.better
        d > 0.25 -> Direction.worse
        else -> Direction.neutral
    }
}
