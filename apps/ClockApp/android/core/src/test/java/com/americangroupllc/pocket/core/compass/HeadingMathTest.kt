package com.americangroupllc.pocket.core.compass

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class HeadingMathTest {
    @Test fun `magnetic to true with positive declination`() {
        assertThat(HeadingMath.magneticToTrue(0.0, 13.0)).isWithin(1e-9).of(13.0)
        assertThat(HeadingMath.magneticToTrue(350.0, 13.0)).isWithin(1e-9).of(3.0)
    }

    @Test fun `magnetic to true with negative declination`() {
        assertThat(HeadingMath.magneticToTrue(10.0, -13.0)).isWithin(1e-9).of(357.0)
    }

    @Test fun `bearing SF to NYC is approximately 70 deg`() {
        val sf = GeoCoordinate(37.7749, -122.4194)
        val nyc = GeoCoordinate(40.7128, -74.0060)
        assertThat(HeadingMath.bearingBetween(sf, nyc)).isWithin(2.0).of(70.0)
    }

    @Test fun `cardinal labels`() {
        assertThat(HeadingMath.cardinalLabel(0.0)).isEqualTo("N")
        assertThat(HeadingMath.cardinalLabel(45.0)).isEqualTo("NE")
        assertThat(HeadingMath.cardinalLabel(90.0)).isEqualTo("E")
        assertThat(HeadingMath.cardinalLabel(135.0)).isEqualTo("SE")
        assertThat(HeadingMath.cardinalLabel(180.0)).isEqualTo("S")
        assertThat(HeadingMath.cardinalLabel(225.0)).isEqualTo("SW")
        assertThat(HeadingMath.cardinalLabel(270.0)).isEqualTo("W")
        assertThat(HeadingMath.cardinalLabel(315.0)).isEqualTo("NW")
        assertThat(HeadingMath.cardinalLabel(360.0)).isEqualTo("N")
    }

    @Test fun `normalize handles negatives and overflow`() {
        assertThat(HeadingMath.normalize(-10.0)).isWithin(1e-9).of(350.0)
        assertThat(HeadingMath.normalize(720.0)).isWithin(1e-9).of(0.0)
        assertThat(HeadingMath.normalize(45.0)).isWithin(1e-9).of(45.0)
    }
}
