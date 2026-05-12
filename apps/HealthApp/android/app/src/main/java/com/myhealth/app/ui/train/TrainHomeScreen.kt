package com.myhealth.app.ui.train

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AirlineSeatReclineExtra
import androidx.compose.material.icons.filled.SelfImprovement
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.myhealth.app.ui.Routes
import com.myhealth.app.ui.shell.AppHeader
import com.myhealth.app.ui.theme.CarePlusColor
import com.myhealth.app.ui.theme.CareTab

/**
 * Train tab home — adds the design-spec "Moderate workout for you"
 * recommendation card above the existing programs list. Mirrors iOS
 * `TrainHomeView`.
 */
@Composable
fun TrainHomeScreen(nav: NavController) {
    val tint = CarePlusColor.TrainGreen

    Column(Modifier.fillMaxSize()) {
        AppHeader(
            tab = CareTab.Train,
            onProfile = { nav.navigate(Routes.PROFILE) },
            onBell = { nav.navigate(Routes.NEWS_DRAWER) },
        )
        LazyColumn(Modifier.fillMaxSize().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)) {

            // Recommendation card
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(tint.copy(alpha = 0.10f)),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Column(Modifier.padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("Moderate workout for you",
                            color = tint, fontWeight = FontWeight.SemiBold)
                        Text("35 min recovery flow",
                            fontSize = 22.sp, fontWeight = FontWeight.Bold)
                        Text("Sleep 6.2h · HRV low",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            fontSize = 12.sp)
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp),
                            modifier = Modifier.padding(top = 4.dp)) {
                            listOf("rate","run","care","diet").forEach { tag ->
                                Box(
                                    Modifier.background(MaterialTheme.colorScheme.surface,
                                        RoundedCornerShape(99.dp))
                                        .padding(horizontal = 8.dp, vertical = 3.dp)
                                ) { Text(tag, fontWeight = FontWeight.SemiBold,
                                    fontSize = 11.sp) }
                            }
                        }
                    }
                }
            }

            item {
                Text("Today's plan", fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(top = 8.dp))
            }
            item { PlanRow(Icons.Filled.SelfImprovement, "Warm-up", "5 min · 4 moves") }
            item { PlanRow(Icons.Filled.SelfImprovement, "Strength block",
                "20 min · 6 moves") }
            item { PlanRow(Icons.Filled.SelfImprovement, "Cooldown",
                "10 min · breathwork") }

            item {
                Card(
                    modifier = Modifier.fillMaxWidth()
                        .clickable { nav.navigate(Routes.STANDUP_TIMER) },
                    colors = CardDefaults.cardColors(
                        CarePlusColor.Warning.copy(alpha = 0.10f)
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Row(Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.AirlineSeatReclineExtra, null,
                            tint = CarePlusColor.Warning,
                            modifier = Modifier.padding(end = 12.dp))
                        Column(Modifier.weight(1f)) {
                            Text("Sedentary 52 min", fontWeight = FontWeight.SemiBold)
                            Text("Time to stand up",
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                fontSize = 12.sp)
                        }
                    }
                }
            }

            item {
                Card(
                    modifier = Modifier.fillMaxWidth()
                        .clickable { nav.navigate(Routes.WORKOUT_LIBRARY) },
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Row(Modifier.padding(12.dp)) {
                        Text("Open program library",
                            fontWeight = FontWeight.SemiBold)
                    }
                }
            }
        }
    }
}

@Composable
private fun PlanRow(icon: androidx.compose.ui.graphics.vector.ImageVector,
                    title: String, subtitle: String) {
    val tint = CarePlusColor.TrainGreen
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.background(tint.copy(alpha = 0.12f),
                    RoundedCornerShape(9.dp)).padding(8.dp)
            ) { Icon(icon, null, tint = tint) }
            Column(Modifier.padding(start = 12.dp).weight(1f)) {
                Text(title, fontWeight = FontWeight.SemiBold)
                Text(subtitle, color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontSize = 12.sp)
            }
        }
    }
}
