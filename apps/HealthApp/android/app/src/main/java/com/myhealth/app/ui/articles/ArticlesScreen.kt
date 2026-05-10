package com.myhealth.app.ui.articles

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
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

private data class Article(
    val id: String, val title: String, val category: String,
    val summary: String, val body: String,
)

private val seedArticles = listOf(
    Article("move-7", "Move Every Day for 7 Days", "Activity",
        "A gentle 7-day plan to make daily movement a habit.",
        "Daily movement is the single biggest lever for long-term health. Walk after lunch, add stretching, then a strength move…"),
    Article("sleep-hygiene", "Sleep Hygiene Basics", "Sleep",
        "Six small habits that improve sleep tonight.",
        "1. Same bedtime + wake time, even on weekends.\n2. Bright light in the morning.\n3. Caffeine cutoff 8 hours before bed.\n4. Cool bedroom (~18°C).\n5. Wind-down routine.\n6. No screens for 30 minutes."),
    Article("hydration", "How Much Water Do You Really Need?", "Nutrition",
        "Evidence-based hydration guidelines.",
        "Most adults need ~30 ml per kg of body weight per day, including water from food. Pale-yellow urine = good."),
    Article("strength-101", "Strength Training for Beginners", "Training",
        "Two sessions a week, six exercises, big returns.",
        "Squat / Hinge / Push / Pull / Carry / Anti-rotation. 3 × 8-12. Add a small bit of weight each week."),
    Article("hrv", "Stress, HRV, and Recovery", "Wellness",
        "Why your watch tracks HRV and what to do with it.",
        "Higher HRV = more recovered. Boosters: 7-9 hours of sleep, slow nasal breathing, sunlight, zone-2 cardio."),
    Article("med-adherence", "Sticking With Your Meds", "Care",
        "Practical tips for daily medicine adherence.",
        "Anchor doses to existing routines. Use a pill organiser. Set notifications with the Take action."),
)

@Composable
fun ArticlesScreen() {
    var selected by remember { mutableStateOf<Article?>(null) }

    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Text("Health articles", fontSize = 28.sp, fontWeight = FontWeight.Bold)
        Text("Bundled — works offline.", color = MaterialTheme.colorScheme.onSurfaceVariant)

        if (selected == null) {
            LazyColumn(Modifier.padding(top = 8.dp)) {
                items(seedArticles) { a ->
                    Column(
                        Modifier.padding(vertical = 8.dp).clickable { selected = a }
                    ) {
                        Text(a.title, fontWeight = FontWeight.SemiBold)
                        Text(a.summary, color = MaterialTheme.colorScheme.onSurfaceVariant,
                            fontSize = 12.sp)
                        Text(a.category, color = MaterialTheme.colorScheme.primary,
                            fontWeight = FontWeight.Bold, fontSize = 11.sp)
                    }
                    HorizontalDivider()
                }
            }
        } else {
            val a = selected!!
            Text(a.category, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
            Text(a.title, fontSize = 24.sp, fontWeight = FontWeight.Bold)
            Text(a.summary, color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 4.dp))
            Text(a.body, modifier = Modifier.padding(top = 16.dp))
            Text("← Back to articles",
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(top = 16.dp).clickable { selected = null })
        }
    }
}
