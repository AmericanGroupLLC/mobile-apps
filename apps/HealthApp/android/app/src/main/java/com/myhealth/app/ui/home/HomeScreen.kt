package com.myhealth.app.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.myhealth.app.ui.Routes

@Composable
fun HomeScreen(nav: NavController) {
    Column(
        Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("Welcome back", fontSize = 28.sp, fontWeight = FontWeight.Bold)
        Text("Today's plan + readiness will appear here.",
            color = MaterialTheme.colorScheme.onSurfaceVariant)

        DashboardTile(
            title = "Vitals & Biological Age",
            subtitle = "HR · HRV · SpO₂ · BP · VO₂Max · sleep · body comp",
            onClick = { nav.navigate(Routes.VITALS) }
        )
        DashboardTile(
            title = "Medicines",
            subtitle = "Today's reminders & adherence",
            onClick = { nav.navigate(Routes.MEDICINE) }
        )
        DashboardTile(
            title = "Anatomy",
            subtitle = "Find exercises by muscle group",
            onClick = { nav.navigate(Routes.ANATOMY) }
        )
        DashboardTile(
            title = "Health articles",
            subtitle = "Bundled + live MyHealthfinder topics",
            onClick = { nav.navigate(Routes.ARTICLES) }
        )
    }
}

@Composable
fun DashboardTile(title: String, subtitle: String, onClick: () -> Unit) {
    Card(
        onClick = onClick,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(title, fontWeight = FontWeight.Bold, fontSize = 16.sp)
            Text(subtitle, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
        }
    }
}
