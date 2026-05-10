package com.americangroupllc.pocket.core.compass

import kotlin.math.*

data class GeoCoordinate(val latitude: Double, val longitude: Double)

object HeadingMath {

    fun magneticToTrue(magneticDegrees: Double, declination: Double): Double =
        normalize(magneticDegrees + declination)

    fun bearingBetween(a: GeoCoordinate, b: GeoCoordinate): Double {
        val lat1 = Math.toRadians(a.latitude)
        val lat2 = Math.toRadians(b.latitude)
        val dLon = Math.toRadians(b.longitude - a.longitude)
        val y = sin(dLon) * cos(lat2)
        val x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return normalize(Math.toDegrees(atan2(y, x)))
    }

    fun cardinalLabel(degrees: Double): String {
        val labels = arrayOf("N","NE","E","SE","S","SW","W","NW")
        val n = normalize(degrees)
        val idx = ((n + 22.5) / 45).toInt() % 8
        return labels[idx]
    }

    fun normalize(degrees: Double): Double {
        var d = degrees % 360
        if (d < 0) d += 360
        return d
    }
}
