package com.americangroupllc.card

import android.Manifest
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.americangroupllc.card.feed.FeedScreen
import com.americangroupllc.card.settings.SettingsScreen
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { /* result intentionally ignored — reminder still works without runtime perm */ }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
        setContent { CardApp() }
    }
}

@Composable
fun CardApp() {
    MaterialTheme {
        Surface(modifier = Modifier) {
            val nav = rememberNavController()
            NavHost(navController = nav, startDestination = "feed") {
                composable("feed") {
                    FeedScreen(onOpenSettings = { nav.navigate("settings") })
                }
                composable("settings") {
                    SettingsScreen(onBack = { nav.popBackStack() })
                }
            }
        }
    }
}
