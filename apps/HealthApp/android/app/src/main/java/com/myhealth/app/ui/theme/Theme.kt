package com.myhealth.app.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

// ─── Color schemes ──────────────────────────────────────────────────────────
//
// Care+ palette is defined in `Color.kt`. Material's `primary`/`secondary`/
// `tertiary` slots map to the four tab accents as follows:
//   primary   -> CareBlue   (the lead surface, used for global CTAs)
//   secondary -> DietCoral
//   tertiary  -> TrainGreen
//
// The fourth accent (WorkoutPink) is referenced directly via [CarePlusColor]
// since Material 3's scheme only exposes 3 slots. Per-tab accenting is done
// through [CareTab].accent, not via MaterialTheme's color scheme.

private val LightScheme = lightColorScheme(
    primary = CarePlusColor.CareBlue,
    secondary = CarePlusColor.DietCoral,
    tertiary = CarePlusColor.TrainGreen,
)
private val DarkScheme = darkColorScheme(
    primary = CarePlusColor.CareBlue,
    secondary = CarePlusColor.DietCoral,
    tertiary = CarePlusColor.TrainGreen,
)

@Composable
fun MyHealthTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context)
            else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkScheme
        else      -> LightScheme
    }
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }
    MaterialTheme(
        colorScheme = colorScheme,
        typography = CarePlusTypography,
        shapes = CarePlusShapes,
        content = content,
    )
}
