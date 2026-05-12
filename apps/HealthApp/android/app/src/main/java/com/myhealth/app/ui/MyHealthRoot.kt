package com.myhealth.app.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.myhealth.app.ui.activity.ActivityListScreen
import com.myhealth.app.ui.anatomy.AnatomyScreen
import com.myhealth.app.ui.articles.ArticlesScreen
import com.myhealth.app.ui.care.CareHomeScreen
import com.myhealth.app.ui.care.DoctorDetailScreen
import com.myhealth.app.ui.care.DoctorFinderScreen
import com.myhealth.app.ui.care.InsuranceCardScreen
import com.myhealth.app.ui.care.LabReportScreen
import com.myhealth.app.ui.care.MyChartConnectScreen
import com.myhealth.app.ui.care.MyChartDataScreen
import com.myhealth.app.ui.common.ComingSoon
import com.myhealth.app.ui.diary.DiaryScreen
import com.myhealth.app.ui.diet.DietHomeScreen
import com.myhealth.app.ui.diet.VendorBrowseScreen
import com.myhealth.app.ui.home.HomeScreen
import com.myhealth.app.ui.medicine.MedicineListScreen
import com.myhealth.app.ui.more.MoreScreen
import com.myhealth.app.ui.news.NewsDrawerSheet
import com.myhealth.app.ui.onboarding.OnboardingScreen
import com.myhealth.app.ui.profile.ProfileScreen
import com.myhealth.app.ui.settings.SettingsScreen
import com.myhealth.app.ui.sleep.SleepScreen
import com.myhealth.app.ui.theme.CareTab
import com.myhealth.app.ui.train.StandupTimerScreen
import com.myhealth.app.ui.train.TrainHomeScreen
import com.myhealth.app.ui.train.TrainScreen
import com.myhealth.app.ui.vitals.BiologicalAgeScreen
import com.myhealth.app.ui.vitals.VitalsScreen
import com.myhealth.app.ui.workout.WorkoutHomeScreen

const val ONBOARDING_KEY = "did_onboard"
val ONBOARDING_PREF = booleanPreferencesKey(ONBOARDING_KEY)

object Routes {
    const val ONBOARD = "onboard"

    // Care+ primary tabs
    const val CARE = "care"
    const val DIET = "diet"
    const val TRAIN = "train"
    const val WORKOUT = "workout"

    // Global header destinations
    const val PROFILE = "profile"
    const val NEWS_DRAWER = "news_drawer"
    const val SETTINGS = "settings"

    // Care sub-routes
    const val MYCHART_CONNECT = "mychart_connect"
    const val MYCHART_DATA = "mychart_data"
    const val INSURANCE_CARD = "insurance_card"
    const val LAB_REPORT = "lab_report"
    const val DOCTOR_FINDER = "doctor_finder"
    const val DOCTOR_DETAIL = "doctor_detail" // doctor_detail/{npi}
    const val ANNUAL_REPORTS = "annual_reports"
    const val SYMPTOMS_LOG = "symptoms_log"

    // Diet sub-routes
    const val VENDOR_BROWSE = "vendor_browse"
    const val MEAL_PLAN_DETAIL = "meal_plan_detail"
    const val ORDER_CHECKOUT = "order_checkout"
    const val MEAL_LOG_ENTRY = "meal_log_entry"
    const val WATER_TRACKER = "water_tracker"

    // Train sub-routes
    const val STANDUP_TIMER = "standup_timer"
    const val TODAY_PLAN = "today_plan"
    const val EXERCISE_DETAIL = "exercise_detail"
    const val WORKOUT_LIBRARY = "workout_library"
    const val PROGRESS_REPORT = "progress_report"
    const val RECOVERY_DAY = "recovery_day"

    // Workout sub-routes
    const val RUN_TRACKER = "run_tracker"
    const val WORKOUT_LOGGER = "workout_logger"
    const val SLEEP = "sleep"
    const val WELLNESS_INSIGHTS = "wellness_insights"
    const val COMMUNITY_HUB = "community_hub"
    const val CHALLENGE_DETAIL = "challenge_detail"

    // Existing destinations kept reachable via Profile / inner nav
    const val MEDICINE = "medicine"
    const val ACTIVITY = "activity"
    const val ARTICLES = "articles"
    const val VITALS = "vitals"
    const val BIO_AGE = "bio_age"
    const val ANATOMY = "anatomy"
    const val MORE = "more"
    const val HOME = "home"
}

private data class TabItem(val route: String, val tab: CareTab,
                           val icon: @Composable () -> Unit, val label: String)

@Composable
fun MyHealthRoot(rootViewModel: RootViewModel = hiltViewModel()) {
    val didOnboard by rootViewModel.didOnboard.collectAsStateWithLifecycle()
    if (!didOnboard) {
        OnboardingScreen(onComplete = { rootViewModel.completeOnboarding() })
        return
    }
    val nav = rememberNavController()
    val backStackEntry by nav.currentBackStackEntryAsState()

    val tabs = listOf(
        TabItem(Routes.CARE, CareTab.Care,
            { Icon(Icons.Filled.Favorite, null) }, "Care"),
        TabItem(Routes.DIET, CareTab.Diet,
            { Icon(Icons.Filled.Restaurant, null) }, "Diet"),
        TabItem(Routes.TRAIN, CareTab.Train,
            { Icon(Icons.Filled.FitnessCenter, null) }, "Train"),
        TabItem(Routes.WORKOUT, CareTab.Workout,
            { Icon(Icons.Filled.DirectionsRun, null) }, "Workout"),
    )
    var newsOpen by remember { mutableStateOf(false) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                tabs.forEach { tab ->
                    val selected = backStackEntry?.destination?.hierarchy
                        ?.any { it.route == tab.route } == true
                    NavigationBarItem(
                        selected = selected,
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
            startDestination = Routes.CARE,
            modifier = Modifier.padding(padding)
        ) {
            // ─── Primary tabs ─────────────────────────────────────────────
            composable(Routes.CARE) { CareHomeScreen(nav) }
            composable(Routes.DIET) { DietHomeScreen(nav) }
            composable(Routes.TRAIN) { TrainHomeScreen(nav) }
            composable(Routes.WORKOUT) { WorkoutHomeScreen(nav) }

            // ─── Header destinations ──────────────────────────────────────
            composable(Routes.PROFILE) { ProfileScreen() }
            composable(Routes.SETTINGS) { SettingsScreen() }
            composable(Routes.NEWS_DRAWER) { NewsDrawerSheet(onDismiss = { nav.popBackStack() }) }

            // ─── Care ─────────────────────────────────────────────────────
            composable(Routes.MYCHART_CONNECT) { MyChartConnectScreen(nav) }
            composable(Routes.MYCHART_DATA)    { MyChartDataScreen() }
            composable(Routes.INSURANCE_CARD)  { InsuranceCardScreen() }
            composable(Routes.LAB_REPORT)      { LabReportScreen() }
            composable(Routes.DOCTOR_FINDER)   { DoctorFinderScreen(nav) }
            composable(
                "${Routes.DOCTOR_DETAIL}/{npi}",
                arguments = listOf(navArgument("npi") { type = NavType.StringType })
            ) { back ->
                DoctorDetailScreen(npi = back.arguments?.getString("npi") ?: "")
            }
            composable(Routes.ANNUAL_REPORTS) { ComingSoon("Annual reports") }
            composable(Routes.SYMPTOMS_LOG)   { ComingSoon("Symptoms log") }

            // ─── Diet ─────────────────────────────────────────────────────
            composable(Routes.VENDOR_BROWSE)    { VendorBrowseScreen() }
            composable(Routes.MEAL_PLAN_DETAIL) { ComingSoon("Meal plan") }
            composable(Routes.ORDER_CHECKOUT)   { ComingSoon("Order checkout") }
            composable(Routes.MEAL_LOG_ENTRY)   { ComingSoon("Meal log entry") }
            composable(Routes.WATER_TRACKER)    { ComingSoon("Water tracker") }

            // ─── Train ────────────────────────────────────────────────────
            composable(Routes.STANDUP_TIMER)   { StandupTimerScreen() }
            composable(Routes.TODAY_PLAN)      { ComingSoon("Today's plan") }
            composable(Routes.EXERCISE_DETAIL) { ComingSoon("Exercise detail") }
            composable(Routes.WORKOUT_LIBRARY) { ComingSoon("Workout library") }
            composable(Routes.PROGRESS_REPORT) { ComingSoon("Progress report") }
            composable(Routes.RECOVERY_DAY)    { ComingSoon("Recovery day") }

            // ─── Workout ──────────────────────────────────────────────────
            composable(Routes.RUN_TRACKER)       { ComingSoon("Run tracker") }
            composable(Routes.WORKOUT_LOGGER)    { ComingSoon("Workout logger") }
            composable(Routes.SLEEP)             { SleepScreen() }
            composable(Routes.WELLNESS_INSIGHTS) { ComingSoon("Wellness insights") }
            composable(Routes.COMMUNITY_HUB)     { ComingSoon("Community hub") }
            composable(Routes.CHALLENGE_DETAIL)  { ComingSoon("Challenge detail") }

            // ─── Existing kept reachable ──────────────────────────────────
            composable(Routes.HOME)     { HomeScreen(nav) }
            composable(Routes.MEDICINE) { MedicineListScreen() }
            composable(Routes.ACTIVITY) { ActivityListScreen() }
            composable(Routes.ARTICLES) { ArticlesScreen() }
            composable(Routes.VITALS)   { VitalsScreen(nav) }
            composable(Routes.BIO_AGE)  { BiologicalAgeScreen() }
            composable(Routes.ANATOMY)  { AnatomyScreen() }
            composable(Routes.MORE)     { MoreScreen(nav) }
        }
    }
}
