package com.americangroupllc.offlineaibuddy.ui

import android.util.Log
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.americangroupllc.offlineaibuddy.chat.ChatScreen
import com.americangroupllc.offlineaibuddy.core.models.ChatSession
import com.americangroupllc.offlineaibuddy.dailychallenge.DailyChallengeScreen
import com.americangroupllc.offlineaibuddy.gamecoach.GameCoachScreen
import com.americangroupllc.offlineaibuddy.home.HomeScreen
import com.americangroupllc.offlineaibuddy.onboarding.ConsentScreen
import com.americangroupllc.offlineaibuddy.onboarding.ModelDownloadScreen
import com.americangroupllc.offlineaibuddy.onboarding.OnboardingPrefs
import com.americangroupllc.offlineaibuddy.onboarding.PermissionsScreen
import com.americangroupllc.offlineaibuddy.onboarding.ProfileSetupScreen
import com.americangroupllc.offlineaibuddy.partyquestions.PartyQuestionsScreen
import com.americangroupllc.offlineaibuddy.profile.ProfileSwitcherScreen
import com.americangroupllc.offlineaibuddy.roast.RoastScreen
import com.americangroupllc.offlineaibuddy.settings.SettingsScreen
import com.americangroupllc.offlineaibuddy.translate.TranslateScreen
import kotlinx.coroutines.launch
import androidx.compose.runtime.rememberCoroutineScope

private const val ONBOARDING_LOG_TAG = "Onboarding"

@Composable
fun RootNav() {
    val nav = rememberNavController()
    val current by nav.currentBackStackEntryAsState()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    // Read the persisted onboarding flag once at startup. We collect as
    // state so the recomposition observes the initial value, but we
    // intentionally pin the start destination based on the FIRST emission
    // so navigation doesn't reset mid-session if the flag flips.
    val onboardingComplete by remember(context) {
        OnboardingPrefs.completedFlow(context)
    }.collectAsState(initial = null)

    // While we don't yet know the flag's value, render nothing — DataStore
    // returns the first value on the next frame, so this is a single-frame
    // gap and avoids rendering the wrong start destination.
    val initial = onboardingComplete ?: return

    val startRoute = if (initial) "home" else "consent"

    Scaffold(
        bottomBar = {
            // Hide the bottom nav while the user is in the onboarding
            // flow — only the main tabs (home/profile/settings) should
            // show the bar.
            val route = current?.destination?.route
            val inOnboarding = route in setOf("consent", "profile-setup", "model-download", "permissions")
            if (!inOnboarding) {
                BottomTabs(nav = nav, current = current?.destination?.route)
            }
        }
    ) { padding ->
        NavHost(nav, startDestination = startRoute, modifier = Modifier.padding(padding)) {
            // ---- Onboarding flow -------------------------------------------------
            composable("consent") {
                LaunchedEffect(Unit) { Log.i(ONBOARDING_LOG_TAG, "step=consent") }
                ConsentScreen(onContinue = { nav.navigate("profile-setup") })
            }
            composable("profile-setup") {
                LaunchedEffect(Unit) { Log.i(ONBOARDING_LOG_TAG, "step=profile-setup") }
                ProfileSetupScreen(onContinue = { nav.navigate("model-download") })
            }
            composable("model-download") {
                LaunchedEffect(Unit) { Log.i(ONBOARDING_LOG_TAG, "step=model-download") }
                ModelDownloadScreen(onContinue = { nav.navigate("permissions") })
            }
            composable("permissions") {
                LaunchedEffect(Unit) { Log.i(ONBOARDING_LOG_TAG, "step=permissions") }
                PermissionsScreen(onContinue = {
                    Log.i(ONBOARDING_LOG_TAG, "step=complete")
                    scope.launch { OnboardingPrefs.setCompleted(context, true) }
                    nav.navigate("home") {
                        // Wipe the onboarding stack so back-press from
                        // home exits the app rather than going back to
                        // the permissions screen.
                        popUpTo("consent") { inclusive = true }
                        launchSingleTop = true
                    }
                })
            }

            // ---- Main tabs -------------------------------------------------------
            composable("home")     { HomeScreen { route -> nav.navigate(route) } }
            composable("profile")  { ProfileSwitcherScreen() }
            composable("settings") { SettingsScreen() }

            composable("chat")           { ChatScreen(kind = ChatSession.Kind.CHAT) }
            composable("roast")          { RoastScreen() }
            composable("dailychallenge") { DailyChallengeScreen() }
            composable("partyquestions") { PartyQuestionsScreen() }
            composable("gamecoach")      { GameCoachScreen() }
            composable("translate")      { TranslateScreen() }
        }
    }
}

@Composable
private fun BottomTabs(
    nav: androidx.navigation.NavHostController,
    current: String?,
) {
    val tabs = listOf(
        Triple("home",     "Home",     Icons.Filled.AutoAwesome),
        Triple("profile",  "Profile",  Icons.Filled.Person),
        Triple("settings", "Settings", Icons.Filled.Settings),
    )
    NavigationBar {
        tabs.forEach { (route, label, icon) ->
            val selected = current == route
            NavigationBarItem(
                selected = selected,
                onClick = {
                    nav.navigate(route) {
                        popUpTo(nav.graph.findStartDestination().id) { saveState = true }
                        launchSingleTop = true
                        restoreState = true
                    }
                },
                icon = { Icon(icon, contentDescription = label) },
                label = { Text(label) }
            )
        }
    }
}
