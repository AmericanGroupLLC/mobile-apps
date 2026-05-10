package com.myhealth.app.ui.anatomy

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.myhealth.core.exercises.Exercise
import com.myhealth.core.exercises.ExerciseLibrary
import com.myhealth.core.exercises.MuscleGroup

private enum class Region(val title: String, val muscles: List<MuscleGroup>) {
    Upper("Upper Body", listOf(MuscleGroup.chest, MuscleGroup.back, MuscleGroup.lats,
        MuscleGroup.shoulders, MuscleGroup.biceps, MuscleGroup.triceps)),
    Core("Core", listOf(MuscleGroup.core, MuscleGroup.obliques, MuscleGroup.lowerBack)),
    Lower("Lower Body", listOf(MuscleGroup.glutes, MuscleGroup.quads,
        MuscleGroup.hamstrings, MuscleGroup.calves)),
}

@Composable
fun AnatomyScreen() {
    var selectedRegion by remember { mutableStateOf(Region.Upper) }
    var selectedMuscle by remember { mutableStateOf<MuscleGroup?>(null) }

    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Text("Anatomy", fontSize = 28.sp, fontWeight = FontWeight.Bold)
        TabRow(selectedTabIndex = Region.values().indexOf(selectedRegion)) {
            Region.values().forEach { r ->
                Tab(selected = selectedRegion == r,
                    onClick = { selectedRegion = r; selectedMuscle = null },
                    text = { Text(r.title) })
            }
        }
        if (selectedMuscle == null) {
            LazyColumn(Modifier.padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                items(selectedRegion.muscles) { m ->
                    Row(Modifier.padding(vertical = 8.dp)) {
                        Text(m.label, fontWeight = FontWeight.SemiBold,
                            modifier = Modifier
                                .padding(end = 8.dp))
                        Text("${ExerciseLibrary.filter(muscle = m).size} exercises",
                            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
                    }
                    Text("View →", color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(start = 8.dp).clickable { selectedMuscle = m })
                }
            }
        } else {
            val m = selectedMuscle!!
            Text(m.label, fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 12.dp))
            Text("Back to muscles", color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.clickable { selectedMuscle = null })
            LazyColumn(Modifier.padding(top = 8.dp)) {
                items(ExerciseLibrary.filter(muscle = m)) { ex -> ExerciseRow(ex) }
            }
        }
    }
}

@Composable
private fun ExerciseRow(ex: Exercise) {
    Column(Modifier.padding(vertical = 8.dp)) {
        Text(ex.name, fontWeight = FontWeight.SemiBold)
        Text("${ex.equipment.label} · ${ex.difficulty.label}",
            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
    }
}
