package com.americangroupllc.drift.core.domain

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class LocationFuzzerTest {

    @Test fun `truncateZip returns exactly 3 chars`() {
        assertThat(LocationFuzzer.truncateZip("94025")).isEqualTo("940")
        assertThat(LocationFuzzer.truncateZip("94025-1234")).isEqualTo("940")
    }

    @Test fun `truncateZip null or short`() {
        assertThat(LocationFuzzer.truncateZip(null)).isNull()
        assertThat(LocationFuzzer.truncateZip("")).isNull()
        assertThat(LocationFuzzer.truncateZip("12")).isNull()
    }

    @Test fun `FuzzedLocation does not expose lat or lon`() {
        val f = LocationFuzzer.fuzz(zip5 = "94025", countyFips = "06085", stateCode = "ca")
        // Reflect over the data class properties — adding lat/lon would fail this.
        val names = FuzzedLocation::class.java.declaredFields
            .filterNot { java.lang.reflect.Modifier.isStatic(it.modifiers) }
            .map { it.name }
            .filterNot { it.startsWith("$") }
            .toSet()
        assertThat(names).containsExactly("zipPrefix3", "countyFips", "stateCode")
        assertThat(f.zipPrefix3).isEqualTo("940")
        assertThat(f.countyFips).isEqualTo("06085")
        assertThat(f.stateCode).isEqualTo("CA")
    }

    @Test fun `bad county and state are dropped`() {
        val f = LocationFuzzer.fuzz(zip5 = null, countyFips = "ABC", stateCode = "California")
        assertThat(f.countyFips).isNull()
        assertThat(f.stateCode).isNull()
    }

    @Test fun `validateCoordinate rejects out of range`() {
        assertThat(LocationFuzzer.validateCoordinate(37.4, -122.1)).isTrue()
        assertThat(LocationFuzzer.validateCoordinate(999.0, 0.0)).isFalse()
        assertThat(LocationFuzzer.validateCoordinate(0.0, -200.0)).isFalse()
        assertThat(LocationFuzzer.validateCoordinate(Double.NaN, 0.0)).isFalse()
    }
}
