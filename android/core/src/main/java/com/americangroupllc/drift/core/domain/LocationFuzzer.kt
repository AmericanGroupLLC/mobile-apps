package com.americangroupllc.drift.core.domain

import kotlinx.serialization.Serializable

@Serializable
data class FuzzedLocation(
    val zipPrefix3: String? = null,
    val countyFips: String? = null,
    val stateCode:  String? = null,
) {
    companion object {
        val EMPTY = FuzzedLocation()
    }
}

/** Pure-logic mirror of `LocationFuzzer.swift`. */
object LocationFuzzer {

    fun truncateZip(zip: String?): String? {
        if (zip.isNullOrBlank()) return null
        val digits = zip.filter { it.isDigit() }
        return if (digits.length >= 3) digits.take(3) else null
    }

    fun fuzz(zip5: String? = null, countyFips: String? = null, stateCode: String? = null): FuzzedLocation {
        val zip3 = truncateZip(zip5)
        val cf   = countyFips?.takeIf { it.length == 5 }
        val sc   = stateCode?.takeIf { it.length == 2 }?.uppercase()
        return FuzzedLocation(zip3, cf, sc)
    }

    fun validateCoordinate(lat: Double, lon: Double): Boolean =
        lat.isFinite() && lon.isFinite() &&
        lat in -90.0..90.0 && lon in -180.0..180.0
}
