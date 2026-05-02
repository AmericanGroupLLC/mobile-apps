package com.myhealth.core.intelligence

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class BiologicalAgeEngineTest {

    @Test fun `fit young adult is younger than chronological`() {
        val r = BiologicalAgeEngine.estimate(
            BiologicalAgeEngine.Inputs(
                chronologicalYears = 30.0,
                sex = BiologicalAgeEngine.Sex.male,
                restingHR = 52.0, hrv = 80.0, vo2Max = 50.0,
                avgSleepHours = 7.8, bmi = 23.0,
                bodyFatPct = 0.14, systolicBP = 115.0, diastolicBP = 75.0,
                weeklyExerciseMin = 250.0, stepsPerDay = 11000.0
            )
        )
        assertThat(r.biologicalYears).isLessThan(30.0)
        assertThat(r.confidence).isGreaterThan(0.7)
    }

    @Test fun `sedentary smoker is older`() {
        val r = BiologicalAgeEngine.estimate(
            BiologicalAgeEngine.Inputs(
                chronologicalYears = 35.0,
                sex = BiologicalAgeEngine.Sex.male,
                restingHR = 78.0, hrv = 22.0, vo2Max = 28.0,
                avgSleepHours = 5.5, bmi = 31.0,
                bodyFatPct = 0.32, systolicBP = 145.0, diastolicBP = 92.0,
                weeklyExerciseMin = 30.0, stepsPerDay = 3000.0,
                smoker = true
            )
        )
        assertThat(r.biologicalYears).isGreaterThan(35.0)
    }

    @Test fun `confidence scales with signals`() {
        val bare = BiologicalAgeEngine.estimate(
            BiologicalAgeEngine.Inputs(40.0, BiologicalAgeEngine.Sex.female)
        )
        val full = BiologicalAgeEngine.estimate(
            BiologicalAgeEngine.Inputs(
                40.0, BiologicalAgeEngine.Sex.female,
                restingHR = 60.0, hrv = 50.0, vo2Max = 36.0,
                avgSleepHours = 7.5, bmi = 22.0, bodyFatPct = 0.22,
                systolicBP = 115.0, diastolicBP = 75.0,
                weeklyExerciseMin = 180.0, stepsPerDay = 9000.0
            )
        )
        assertThat(full.confidence).isGreaterThan(bare.confidence)
    }

    @Test fun `smoking dominates factor list`() {
        val r = BiologicalAgeEngine.estimate(
            BiologicalAgeEngine.Inputs(
                chronologicalYears = 50.0,
                sex = BiologicalAgeEngine.Sex.male,
                restingHR = 80.0, vo2Max = 25.0, smoker = true
            )
        )
        assertThat(r.factors.first().name).isEqualTo("Smoking")
    }
}
