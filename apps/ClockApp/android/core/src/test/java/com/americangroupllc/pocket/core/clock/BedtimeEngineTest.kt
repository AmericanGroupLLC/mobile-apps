package com.americangroupllc.pocket.core.clock

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class BedtimeEngineTest {
    @Test fun `sleep hours within same day window`() {
        assertThat(BedtimeEngine.sleepHours(22, 0, 6, 0)).isWithin(1e-9).of(8.0)
    }
    @Test fun `no wrap when wake after bed`() {
        assertThat(BedtimeEngine.sleepHours(1, 30, 8, 0)).isWithin(1e-9).of(6.5)
    }
    @Test fun `winddown inside window`() {
        assertThat(BedtimeEngine.isWinddown(21, 45, 22, 0)).isTrue()
        assertThat(BedtimeEngine.isWinddown(22, 1, 22, 0)).isFalse()
        assertThat(BedtimeEngine.isWinddown(21, 0, 22, 0)).isFalse()
    }
    @Test fun `winddown wraps midnight`() {
        assertThat(BedtimeEngine.isWinddown(23, 50, 0, 10)).isTrue()
        assertThat(BedtimeEngine.isWinddown(0, 5, 0, 10)).isTrue()
    }
}
