package com.myhealth.wear.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.Text
import com.myhealth.core.exercises.ExerciseLibrary
import com.myhealth.core.exercises.MuscleGroup

@Composable fun QuickLogPage() = SimplePage("Quick Log", "+250 ml · +1k steps · mood ↑")
@Composable fun LiveWorkoutPage() = SimplePage("Live Workout", "Tap to start")
@Composable fun RunPage() = SimplePage("Run", "GPS route · pace")
@Composable fun WaterPage() = SimplePage("Water", "Crown to set ml")
@Composable fun WeightPage() = SimplePage("Weight", "Crown to set kg")
@Composable fun MoodPage() = SimplePage("Mood", "Awful → Great")
@Composable fun HistoryPage() = SimplePage("History", "Recent metrics")
@Composable fun SettingsPage() = SimplePage("Settings", "Sync · API URL · log out")

@Composable
fun AnatomyPage() {
    ScalingLazyColumn(
        modifier = Modifier.fillMaxSize().padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        item {
            Text("Anatomy", fontWeight = FontWeight.Bold, fontSize = 16.sp)
        }
        items(MuscleGroup.values().toList()) { m ->
            Chip(
                label = { Text("${m.label} (${ExerciseLibrary.filter(muscle = m).size})") },
                onClick = { /* navigate to muscle detail (TODO) */ },
                colors = ChipDefaults.primaryChipColors()
            )
        }
    }
}

@Composable
private fun SimplePage(title: String, subtitle: String) {
    Column(
        Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(title, fontWeight = FontWeight.Bold, fontSize = 18.sp)
        Text(subtitle, fontSize = 11.sp)
    }
}
