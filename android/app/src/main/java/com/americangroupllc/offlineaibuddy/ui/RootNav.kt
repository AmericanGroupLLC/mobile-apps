package com.americangroupllc.offlineaibuddy.ui

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
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.americangroupllc.offlineaibuddy.chat.ChatScreen
import com.americangroupllc.offlineaibuddy.dailychallenge.DailyChallengeScreen
import com.americangroupllc.offlineaibuddy.gamecoach.GameCoachScreen
import com.americangroupllc.offlineaibuddy.home.HomeScreen
import com.americangroupllc.offlineaibuddy.partyquestions.PartyQuestionsScreen
import com.americangroupllc.offlineaibuddy.profile.ProfileSwitcherScreen
import com.americangroupllc.offlineaibuddy.roast.RoastScreen
import com.americangroupllc.offlineaibuddy.settings.SettingsScreen
import com.americangroupllc.offlineaibuddy.translate.TranslateScreen
import com.americangroupllc.offlineaibuddy.core.models.ChatSession

@Composable
fun RootNav() {
    val nav = rememberNavController()
    val current by nav.currentBackStackEntryAsState()
    val tabs = listOf(
        Triple("home",     "Home",     Icons.Filled.AutoAwesome),
        Triple("profile",  "Profile",  Icons.Filled.Person),
        Triple("settings", "Settings", Icons.Filled.Settings),
    )
    Scaffold(
        bottomBar = {
            NavigationBar {
                tabs.forEach { (route, label, icon) ->
                    val selected = current?.destination?.hierarchy?.any { it.route == route } == true
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
    ) { padding ->
        NavHost(nav, startDestination = "home", modifier = Modifier.padding(padding)) {
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
