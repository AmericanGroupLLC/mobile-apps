package com.myhealth.app.ui.care

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.myhealth.app.ui.theme.CarePlusColor

/**
 * Per-condition Care plan card. Mirrors iOS `CarePlanCard.swift`.
 *  • title + reading pill
 *  • goal sentence
 *  • intervention tags
 */
@Composable
fun CarePlanCard(
    title: String,
    goal: String,
    interventions: List<String>,
    reading: String? = null,
    readingHealthy: Boolean = true,
) {
    val tint = CarePlusColor.CareBlue
    val pillColor = if (readingHealthy) CarePlusColor.Success else CarePlusColor.Warning

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row {
                Text(title, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                if (reading != null) {
                    Box(
                        Modifier.background(pillColor.copy(alpha = 0.18f), RoundedCornerShape(99.dp))
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    ) { Text(reading, color = pillColor, fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp) }
                }
            }
            Text(goal, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
            if (interventions.isNotEmpty()) {
                val scroll = rememberScrollState()
                Row(Modifier.horizontalScroll(scroll),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    interventions.forEach { tag ->
                        Box(
                            Modifier.background(tint.copy(alpha = 0.10f),
                                RoundedCornerShape(99.dp))
                                .padding(horizontal = 8.dp, vertical = 3.dp)
                        ) { Text(tag, color = tint, fontWeight = FontWeight.SemiBold,
                            fontSize = 11.sp) }
                    }
                }
            }
        }
    }
}

/** Per-condition copy. Mirrors iOS [CarePlanRecipe.swift]. */
object CarePlanRecipe {
    data class Recipe(val title: String, val goal: String, val interventions: List<String>)

    fun recipe(condition: String): Recipe = when (condition.lowercase()) {
        "hypertension" -> Recipe("Hypertension", "Goal: under 130/80",
            listOf("Low sodium", "BP log", "DASH plan"))
        "lowbloodpressure" -> Recipe("Low blood pressure",
            "Stay hydrated; avoid sudden standing", listOf("Hydration", "Salt"))
        "heartcondition" -> Recipe("Heart condition", "Stay under prescribed HR cap",
            listOf("HR cap", "Rest day"))
        "diabetest1" -> Recipe("Type 1 diabetes", "Pre/post-meal glucose check",
            listOf("Carb count", "Insulin log"))
        "diabetest2" -> Recipe("Type 2 / Prediabetes",
            "Goal: A1C under 5.7 by next labs",
            listOf("Diet", "Exercise", "Lab retest"))
        "obesity" -> Recipe("Weight management",
            "Steady cardio + 0.5 kg/week deficit", listOf("DASH", "Walk 10k"))
        "asthma" -> Recipe("Asthma", "Carry inhaler; watch AQI",
            listOf("AQI alert", "Inhaler log"))
        "kneeinjury", "ankleinjury", "shoulderinjury", "backpain", "osteoporosis" ->
            Recipe(condition.replaceFirstChar(Char::titlecase),
                "Avoid high-impact; mobility work daily", listOf("Mobility", "Ice/heat"))
        "kidneyissue" -> Recipe("Kidney (CKD)", "Low-K and low-P meals",
            listOf("Low K", "Low P"))
        "anemia" -> Recipe("Anemia", "Iron + vitamin-C pairings",
            listOf("Iron", "Vit C"))
        else -> Recipe(condition.replaceFirstChar(Char::titlecase),
            "Tap to see condition-specific guidance.", emptyList())
    }

    /** Stub readings — wired to Health Connect in week 2. */
    fun readingFor(condition: String): Pair<String, Boolean>? = when (condition.lowercase()) {
        "hypertension" -> "138/88" to false
        "diabetest2", "diabetest1" -> "A1C 6.1" to false
        "heartcondition" -> "HR 72" to true
        "obesity" -> "BMI 31" to false
        else -> null
    }
}
