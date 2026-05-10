package com.myhealth.app.ui.more

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.myhealth.app.ui.Routes
import com.myhealth.app.ui.home.DashboardTile

@Composable
fun MoreScreen(nav: NavController) {
    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Text("More", fontSize = 28.sp, fontWeight = FontWeight.Bold)
        Text("Health", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.SemiBold)
        DashboardTile("Vitals & Biological Age", "All sensor + manual data") { nav.navigate(Routes.VITALS) }
        DashboardTile("Anatomy", "Browse by muscle group") { nav.navigate(Routes.ANATOMY) }

        HorizontalDivider(Modifier.padding(vertical = 8.dp))
        Text("Care", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.SemiBold)
        DashboardTile("Medicines", "Reminders + adherence") { nav.navigate(Routes.MEDICINE) }
        DashboardTile("Activities", "Walking, cycling, gardening, ...") { nav.navigate(Routes.ACTIVITY) }
        DashboardTile("Health articles", "Bundled + live") { nav.navigate(Routes.ARTICLES) }

        HorizontalDivider(Modifier.padding(vertical = 8.dp))
        Text("App", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.SemiBold)
        DashboardTile("Profile", "Body, goal, language, units") { nav.navigate(Routes.PROFILE) }
        DashboardTile("Settings", "Theme, sync, export, erase") { nav.navigate(Routes.SETTINGS) }
    }
}
