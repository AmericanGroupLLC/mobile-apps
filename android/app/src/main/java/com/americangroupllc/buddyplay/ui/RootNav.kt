package com.americangroupllc.buddyplay.ui

import android.util.Log
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SportsEsports
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.americangroupllc.buddyplay.core.models.GameKind
import com.americangroupllc.buddyplay.home.HomeScreen
import com.americangroupllc.buddyplay.lobby.HostLobbyScreen
import com.americangroupllc.buddyplay.lobby.JoinLobbyScreen
import com.americangroupllc.buddyplay.rivalries.RivalriesScreen
import com.americangroupllc.buddyplay.settings.SettingsScreen

/** Logcat tag for nav-graph entry events. Filter `adb logcat -s BuddyPlayNav`. */
private const val NAV_TAG = "BuddyPlayNav"

@Composable
fun RootNav() {
    val nav = rememberNavController()
    val current by nav.currentBackStackEntryAsState()
    val tabs = listOf(
        Triple("home",      "Play",      Icons.Filled.SportsEsports),
        Triple("rivalries", "Rivalries", Icons.Filled.EmojiEvents),
        Triple("settings",  "Settings",  Icons.Filled.Settings),
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
            composable("home") {
                LaunchedEffect(Unit) { Log.d(NAV_TAG, "enter home") }
                HomeScreen(
                    onHost = { kind ->
                        nav.navigate("lobby/host/${kind.name}")
                    },
                    onJoin = {
                        // For Join we don't yet know the target game until after scan; route to
                        // Join lobby with a sentinel game kind. Real picker lands in Phase 8.
                        nav.navigate("lobby/join/${GameKind.CHESS.name}")
                    },
                )
            }
            composable("rivalries") {
                LaunchedEffect(Unit) { Log.d(NAV_TAG, "enter rivalries") }
                RivalriesScreen()
            }
            composable("settings") {
                LaunchedEffect(Unit) { Log.d(NAV_TAG, "enter settings") }
                SettingsScreen()
            }
            composable(
                route = "lobby/{role}/{gameId}",
                arguments = listOf(
                    navArgument("role")   { type = NavType.StringType },
                    navArgument("gameId") { type = NavType.StringType },
                ),
            ) { entry ->
                val role   = entry.arguments?.getString("role")   ?: "host"
                val gameId = entry.arguments?.getString("gameId") ?: GameKind.CHESS.name
                val kind = runCatching { GameKind.valueOf(gameId) }.getOrDefault(GameKind.CHESS)
                LaunchedEffect(role, gameId) {
                    Log.d(NAV_TAG, "enter lobby role=$role game=$gameId")
                }
                if (role == "join") {
                    JoinLobbyScreen(
                        onBack = { nav.popBackStack() },
                        onStart = {
                            nav.navigate("game/${kind.name}") {
                                popUpTo("home")
                            }
                        },
                    )
                } else {
                    HostLobbyScreen(
                        kind = kind,
                        onDone = { nav.popBackStack() },
                        onStart = {
                            nav.navigate("game/${kind.name}") {
                                popUpTo("home")
                            }
                        },
                    )
                }
            }
            composable(
                route = "game/{gameId}",
                arguments = listOf(
                    navArgument("gameId") { type = NavType.StringType },
                ),
            ) { entry ->
                val gameId = entry.arguments?.getString("gameId") ?: GameKind.CHESS.name
                val kind = runCatching { GameKind.valueOf(gameId) }.getOrDefault(GameKind.CHESS)
                LaunchedEffect(gameId) { Log.d(NAV_TAG, "enter game game=$gameId") }
                GameRouteHost(kind = kind, onBack = { nav.popBackStack() })
            }
        }
    }
}
