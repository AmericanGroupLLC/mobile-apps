package com.myhealth.wear

import com.google.common.truth.Truth.assertThat
import com.myhealth.core.exercises.ExerciseLibrary
import com.myhealth.core.exercises.MuscleGroup
import org.junit.Test

/** Wear-side unit tests — tiny smoke that proves the shared core module is
 *  reachable from the wear module. */
class WearExerciseLibraryTest {

    @Test fun libraryIsNotEmpty() {
        assertThat(ExerciseLibrary.exercises).isNotEmpty()
    }

    @Test fun chestFilterWorks() {
        val chest = ExerciseLibrary.filter(muscle = MuscleGroup.chest)
        assertThat(chest).isNotEmpty()
    }
}
