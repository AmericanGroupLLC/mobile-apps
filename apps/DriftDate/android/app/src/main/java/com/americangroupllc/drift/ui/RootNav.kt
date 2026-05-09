package com.americangroupllc.drift.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.outlined.MailOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import com.americangroupllc.drift.chat.ChatListScreen
import com.americangroupllc.drift.chat.ChatScreen
import com.americangroupllc.drift.discover.DiscoverScreen
import com.americangroupllc.drift.matches.MatchesScreen
import com.americangroupllc.drift.profile.ProfileScreen
import com.americangroupllc.drift.settings.SettingsScreen

@Composable
fun RootNav(nav: NavHostController) {
    val backStack by nav.currentBackStackEntryAsState()
    val current = backStack?.destination?.route ?: "discover"

    Scaffold(
        bottomBar = {
            NavigationBar {
                @Composable
                fun item(route: String, label: String, icon: androidx.compose.ui.graphics.vector.ImageVector) {
                    NavigationBarItem(
                        selected = current == route,
                        onClick = { nav.navigate(route) { launchSingleTop = true } },
                        icon = { Icon(icon, contentDescription = label) },
                        label = { Text(label) },
                    )
                }
                item("discover", "Discover", Icons.Filled.Search)
                item("matches",  "Matches",  Icons.Filled.Favorite)
                item("chat",     "Chats",    Icons.Outlined.MailOutline)
                item("profile",  "Profile",  Icons.Filled.Person)
                item("settings", "Settings", Icons.Filled.Settings)
            }
        }
    ) { padding ->
        NavHost(navController = nav, startDestination = "discover") {
            composable("discover") { DiscoverScreen() }
            composable("matches")  { MatchesScreen() }
            composable("chat")     { ChatListScreen(onOpen = { id -> nav.navigate("chat/$id") }) }
            composable("chat/{id}") { entry ->
                ChatScreen(conversationId = entry.arguments?.getString("id").orEmpty())
            }
            composable("profile")  { ProfileScreen() }
            composable("settings") {
                SettingsScreen(
                    onAccountErased = {
                        // Mirrors iOS post-erase UX: jump back to the
                        // root start destination and clear the back
                        // stack so the user can't tap "back" into a
                        // signed-out chat. When an explicit onboarding
                        // route lands, swap "discover" for it here.
                        nav.navigate("discover") {
                            popUpTo(nav.graph.startDestinationId) { inclusive = true }
                            launchSingleTop = true
                        }
                    }
                )
            }
        }
    }
}
