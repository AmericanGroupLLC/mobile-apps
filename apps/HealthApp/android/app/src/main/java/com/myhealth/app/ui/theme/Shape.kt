package com.myhealth.app.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

/**
 * Care+ shape scale. Tiles use [CareRadiusMd] (12dp), bottom sheets use
 * [CareRadiusLg] (18dp), pill buttons use [CareRadiusPill].
 */
val CareRadiusSm = 8.dp
val CareRadiusMd = 12.dp
val CareRadiusLg = 18.dp
val CareRadiusPill = 999.dp

/** 4-pt spacing scale. */
val CareSpacingXs = 4.dp
val CareSpacingSm = 8.dp
val CareSpacingMd = 12.dp
val CareSpacingLg = 16.dp
val CareSpacingXl = 24.dp
val CareSpacingXxl = 32.dp

val CarePlusShapes = Shapes(
    extraSmall = RoundedCornerShape(CareRadiusSm),
    small = RoundedCornerShape(CareRadiusSm),
    medium = RoundedCornerShape(CareRadiusMd),
    large = RoundedCornerShape(CareRadiusLg),
    extraLarge = RoundedCornerShape(CareRadiusLg),
)
