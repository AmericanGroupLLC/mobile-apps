package com.americangroupllc.pocket

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.americangroupllc.pocket.calculator.CalculatorScreen
import com.americangroupllc.pocket.compass.CompassScreen
import com.americangroupllc.pocket.level.LevelScreen
import com.americangroupllc.pocket.measure.MeasureScreen
import com.americangroupllc.pocket.tools.ToolsLauncher
import com.americangroupllc.pocket.clock.ClockScreen as PocketClockScreen
import com.americangroupllc.pocket.settings.SettingsScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    PocketNavHost()
                }
            }
        }
    }
}

@Composable
fun PocketNavHost() {
    val nav = rememberNavController()
    NavHost(navController = nav, startDestination = "tools") {
        composable("tools")      { ToolsLauncher(onOpen = { route -> nav.navigate(route) }) }
        composable("clock")      { PocketClockScreen() }
        composable("calculator") { CalculatorScreen() }
        composable("measure")    { MeasureScreen() }
        composable("compass")    { CompassScreen() }
        composable("level")      { LevelScreen() }
        composable("settings")   { SettingsScreen() }
    }
}
