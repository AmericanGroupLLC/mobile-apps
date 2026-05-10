package com.myhealth.app.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Nightlight
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.myhealth.app.ui.activity.ActivityListScreen
import com.myhealth.app.ui.anatomy.AnatomyScreen
import com.myhealth.app.ui.articles.ArticlesScreen
import com.myhealth.app.ui.diary.DiaryScreen
import com.myhealth.app.ui.home.HomeScreen
import com.myhealth.app.ui.medicine.MedicineListScreen
import com.myhealth.app.ui.more.MoreScreen
import com.myhealth.app.ui.onboarding.OnboardingScreen
import com.myhealth.app.ui.profile.ProfileScreen
import com.myhealth.app.ui.settings.SettingsScreen
import com.myhealth.app.ui.sleep.SleepScreen
import com.myhealth.app.ui.train.TrainScreen
import com.myhealth.app.ui.vitals.BiologicalAgeScreen
import com.myhealth.app.ui.vitals.VitalsScreen

const val ONBOARDING_KEY = "did_onboard"
val ONBOARDING_PREF = booleanPreferencesKey(ONBOARDING_KEY)

object Routes {
    const val ONBOARD = "onboard"
    const val HOME = "home"
    const val TRAIN = "train"
    const val DIARY = "diary"
    const val SLEEP = "sleep"
    const val MORE = "more"
    const val MEDICINE = "medicine"
    const val ACTIVITY = "activity"
    const val ARTICLES = "articles"
    const val VITALS = "vitals"
    const val BIO_AGE = "bio_age"
    const val ANATOMY = "anatomy"
    const val PROFILE = "profile"
    const val SETTINGS = "settings"
}

private data class TabItem(val route: String, val icon: @Composable () -> Unit, val label: String)

@Composable
fun MyHealthRoot(rootViewModel: RootViewModel = hiltViewModel()) {
    val didOnboard by rootViewModel.didOnboard.collectAsStateWithLifecycle()
    if (!didOnboard) {
        OnboardingScreen(onComplete = { rootViewModel.completeOnboarding() })
        return
    }
    val nav = rememberNavController()
    val backStackEntry by nav.currentBackStackEntryAsState()
    val current = backStackEntry?.destination?.route

    val tabs = listOf(
        TabItem(Routes.HOME, { Icon(Icons.Filled.Home, null) }, "Home"),
        TabItem(Routes.TRAIN, { Icon(Icons.Filled.FitnessCenter, null) }, "Train"),
        TabItem(Routes.DIARY, { Icon(Icons.Filled.Book, null) }, "Diary"),
        TabItem(Routes.SLEEP, { Icon(Icons.Filled.Nightlight, null) }, "Sleep"),
        TabItem(Routes.MORE, { Icon(Icons.Filled.GridView, null) }, "More"),
    )

    Scaffold(
        bottomBar = {
            NavigationBar {
                tabs.forEach { tab ->
                    NavigationBarItem(
                        selected = backStackEntry?.destination?.hierarchy?.any { it.route == tab.route } == true,
                        onClick = {
                            nav.navigate(tab.route) {
                                popUpTo(nav.graph.findStartDestination().id) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = tab.icon,
                        label = { Text(tab.label) }
                    )
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = nav,
            startDestination = Routes.HOME,
            modifier = Modifier.padding(padding)
        ) {
            composable(Routes.HOME) { HomeScreen(nav) }
            composable(Routes.TRAIN) { TrainScreen(nav) }
            composable(Routes.DIARY) { DiaryScreen(nav) }
            composable(Routes.SLEEP) { SleepScreen() }
            composable(Routes.MORE) { MoreScreen(nav) }

            composable(Routes.MEDICINE) { MedicineListScreen() }
            composable(Routes.ACTIVITY) { ActivityListScreen() }
            composable(Routes.ARTICLES) { ArticlesScreen() }
            composable(Routes.VITALS) { VitalsScreen(nav) }
            composable(Routes.BIO_AGE) { BiologicalAgeScreen() }
            composable(Routes.ANATOMY) { AnatomyScreen() }
            composable(Routes.PROFILE) { ProfileScreen() }
            composable(Routes.SETTINGS) { SettingsScreen() }
        }
    }
}
