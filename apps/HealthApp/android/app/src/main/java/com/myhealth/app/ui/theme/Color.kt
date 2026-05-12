package com.myhealth.app.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Care+ semantic color tokens. Mirrors the iOS [CarePlusPalette] in
 * `shared/FitFusionCore/.../DesignSystem/Theme.swift` — keep the two in sync.
 *
 * Per-tab accents intentionally diverge from Material 3's tonal palette so the
 * four primary tabs (Care · Diet · Train · Workout) read as distinct surfaces.
 */
object CarePlusColor {
    // Tab accents
    val CareBlue    = Color(0xFF2E73D9)
    val DietCoral   = Color(0xFFFA6673)
    val TrainGreen  = Color(0xFF36C763)
    val WorkoutPink = Color(0xFFFA4A8C)

    // Status tokens
    val Success = Color(0xFF1FB85C)
    val Warning = Color(0xFFF59E1A)
    val Danger  = Color(0xFFEB3B4D)
    val Info    = Color(0xFF338CEB)

    // Legacy MyHealth tokens (kept for screens not yet migrated)
    val LegacyOrange = Color(0xFFF9496F)
    val LegacyIndigo = Color(0xFF5E5CE6)
    val LegacyGreen  = Color(0xFF34C759)
}

/** Stable accent for the four primary Care+ tabs. */
enum class CareTab(val accent: Color, val label: String) {
    Care(CarePlusColor.CareBlue, "Care"),
    Diet(CarePlusColor.DietCoral, "Diet"),
    Train(CarePlusColor.TrainGreen, "Train"),
    Workout(CarePlusColor.WorkoutPink, "Workout"),
}
