package com.myhealth.app.ui.workout

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.DirectionsRun
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.Nightlight
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material3.Card
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
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

@Composable
fun WorkoutHomeScreen(nav: NavController) {
    val tint = CarePlusColor.WorkoutPink
    var showRpe by remember { mutableStateOf(false) }

    Column(Modifier.fillMaxSize()) {
        AppHeader(
            tab = CareTab.Workout,
            onProfile = { nav.navigate(Routes.PROFILE) },
            onBell = { nav.navigate(Routes.NEWS_DRAWER) },
        )
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {

            // Activity rings header
            item {
                Column(horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp)) {
                    ActivityRings(move = 0.72f, exercise = 0.45f, stand = 0.85f)
                    Spacer(Modifier.height(12.dp))
                    ActivityRingsStats(move = "420", exercise = "28", stand = "9/12")
                }
            }

            // Wellness insight banner
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(tint.copy(alpha = 0.10f)),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Row(Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        Text("Wellness insight",
                            color = tint, fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.padding(end = 8.dp))
                        Text("RHR lowest on 8k step days.",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            fontSize = 13.sp)
                    }
                }
            }

            item {
                Card(
                    modifier = Modifier.fillMaxWidth().clickable { showRpe = true },
                    colors = CardDefaults.cardColors(MaterialTheme.colorScheme.surfaceVariant),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            Modifier.size(40.dp).background(tint.copy(alpha = 0.18f),
                                RoundedCornerShape(10.dp)),
                            contentAlignment = Alignment.Center
                        ) { Icon(Icons.Filled.Speed, null, tint = tint) }
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text("Rate that workout (RPE)", fontWeight = FontWeight.Bold)
                            Text("How hard did it feel? 1–10 scale.",
                                color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
                        }
                        Icon(Icons.Filled.ChevronRight, null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }

            item { Section("Cardio") }
            item {
                Tile(Icons.Filled.DirectionsRun, "Run / walk tracker",
                    "GPS pace + map.", tint) { nav.navigate(Routes.RUN_TRACKER) }
            }

            item { Section("Strength") }
            item {
                Tile(Icons.Filled.FitnessCenter, "Workout logger",
                    "Sets, reps, perceived load.", tint) { nav.navigate(Routes.WORKOUT_LOGGER) }
            }

            item { Section("Recovery") }
            item {
                Tile(Icons.Filled.Nightlight, "Sleep & HRV",
                    "Stages, recovery score, mood.", tint) { nav.navigate(Routes.SLEEP) }
            }

            item { Section("Coming soon") }
            item {
                Tile(Icons.Filled.Speed, "Wellness insights",
                    "Weekly summary across cardio, strength, sleep.",
                    tint) { nav.navigate(Routes.WELLNESS_INSIGHTS) }
            }
        }
    }

    if (showRpe) RpeRatingSheet(onDismiss = { showRpe = false })
}

@Composable
private fun Section(text: String) =
    Text(text, fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
        modifier = Modifier.padding(top = 8.dp, bottom = 4.dp))

@Composable
private fun Tile(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String, subtitle: String,
    tint: androidx.compose.ui.graphics.Color, onClick: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        colors = CardDefaults.cardColors(MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(36.dp).background(tint.copy(alpha = 0.12f), RoundedCornerShape(9.dp)),
                contentAlignment = Alignment.Center
            ) { Icon(icon, null, tint = tint, modifier = Modifier.size(20.dp)) }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.Bold)
                Text(subtitle, fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Icon(Icons.Filled.ChevronRight, null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
