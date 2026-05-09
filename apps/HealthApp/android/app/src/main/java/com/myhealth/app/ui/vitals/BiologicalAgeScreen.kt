package com.myhealth.app.ui.vitals

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.myhealth.core.intelligence.BiologicalAgeEngine

@Composable
fun BiologicalAgeScreen() {
    var chrono by remember { mutableStateOf(30f) }
    var rhr by remember { mutableStateOf(60f) }
    var hrv by remember { mutableStateOf(45f) }
    var vo2 by remember { mutableStateOf(38f) }
    var sleep by remember { mutableStateOf(7.5f) }
    var bmi by remember { mutableStateOf(23f) }
    var smoker by remember { mutableStateOf(false) }

    val result = BiologicalAgeEngine.estimate(
        BiologicalAgeEngine.Inputs(
            chronologicalYears = chrono.toDouble(),
            sex = BiologicalAgeEngine.Sex.female,
            restingHR = rhr.toDouble(),
            hrv = hrv.toDouble(),
            vo2Max = vo2.toDouble(),
            avgSleepHours = sleep.toDouble(),
            bmi = bmi.toDouble(),
            smoker = smoker,
        )
    )

    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Biological Age", fontSize = 28.sp, fontWeight = FontWeight.Bold)

        Card(modifier = Modifier.fillMaxWidth()) {
            Row(
                Modifier.padding(16.dp).fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                AgeColumn("Chronological", result.chronologicalYears.toInt(), Color.Gray)
                AgeColumn("Biological", result.biologicalYears.toInt(),
                    if (result.deltaYears < 0) Color(0xFF34C759) else Color(0xFFFF9500))
            }
        }

        Text(result.verdict, fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.primary)

        HorizontalDivider()

        Slider(value = chrono, onValueChange = { chrono = it }, valueRange = 13f..100f)
        Text("Chronological age: ${chrono.toInt()}")
        Slider(value = rhr, onValueChange = { rhr = it }, valueRange = 40f..120f)
        Text("Resting HR: ${rhr.toInt()} bpm")
        Slider(value = hrv, onValueChange = { hrv = it }, valueRange = 10f..120f)
        Text("HRV: ${hrv.toInt()} ms")
        Slider(value = vo2, onValueChange = { vo2 = it }, valueRange = 20f..70f)
        Text("VO₂ Max: %.1f".format(vo2))
        Slider(value = sleep, onValueChange = { sleep = it }, valueRange = 4f..10f)
        Text("Sleep: %.1f h".format(sleep))
        Slider(value = bmi, onValueChange = { bmi = it }, valueRange = 16f..40f)
        Text("BMI: %.1f".format(bmi))

        Button(onClick = { smoker = !smoker }, modifier = Modifier.fillMaxWidth()) {
            Text(if (smoker) "Smoker: Yes" else "Smoker: No")
        }

        HorizontalDivider()
        Text("Top contributors", fontWeight = FontWeight.Bold)
        result.factors.take(5).forEach { f ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("${f.name} (${f.value})", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(if (f.deltaYears >= 0) "+%.1f yr".format(f.deltaYears)
                     else "%.1f yr".format(f.deltaYears))
            }
        }
        Text("Heuristic — not a medical diagnosis.",
            fontSize = 10.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun AgeColumn(label: String, years: Int, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(label, fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 11.sp)
        Text("$years", fontSize = 56.sp, fontWeight = FontWeight.Black, color = color)
        Text("years", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
