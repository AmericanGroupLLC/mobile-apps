package com.myhealth.app.ui.news

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SecondaryTabRow
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.myhealth.app.ui.theme.CarePlusColor

/**
 * Global news drawer surfaced from the bell in [AppHeader]. Three inner
 * tabs: Urgent · For You · Wellness. First app-wide use of
 * [ModalBottomSheet] — sets the pattern for [com.myhealth.app.ui.workout.RpeRatingSheet]
 * and any future bottom-sheet UIs.
 *
 * Items are seeded locally for week 1; the spec calls for a content
 * pipeline (Open mHealth feed, MyChart messages, internal articles)
 * which is deferred to weeks 4–5.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewsDrawerSheet(onDismiss: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var tabIndex by remember { mutableIntStateOf(0) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
    ) {
        Column(Modifier.fillMaxWidth().padding(bottom = 24.dp)) {
            Text(
                "Notifications",
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(start = 24.dp, end = 24.dp, top = 4.dp, bottom = 8.dp)
            )

            SecondaryTabRow(selectedTabIndex = tabIndex) {
                listOf("Urgent", "For You", "Wellness").forEachIndexed { i, label ->
                    Tab(
                        selected = tabIndex == i,
                        onClick = { tabIndex = i },
                        text = { Text(label) }
                    )
                }
            }

            val items = when (tabIndex) {
                0 -> URGENT_SEED
                1 -> FOR_YOU_SEED
                else -> WELLNESS_SEED
            }

            LazyColumn(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(items) { item ->
                    NewsRow(item)
                }
                if (items.isEmpty()) {
                    item { Text("Nothing here right now.",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(16.dp)) }
                }
            }
        }
    }
}

private data class NewsItem(val source: String, val title: String, val subtitle: String,
                            val isUrgent: Boolean = false)

private val URGENT_SEED = listOf(
    NewsItem("WHO", "Measles advisory · Bay Area",
        "Check immunization status", isUrgent = true),
    NewsItem("MyChart", "New lab results available",
        "A1C, lipid panel", isUrgent = true),
)

private val FOR_YOU_SEED = listOf(
    NewsItem("CDC", "DASH diet vs hypertension", "New trial results, 4 min read"),
    NewsItem("NIH", "A1C and sleep quality", "How sleep shapes glucose"),
    NewsItem("SCC Health", "Free BP screenings nearby", "Santa Clara County"),
)

private val WELLNESS_SEED = listOf(
    NewsItem("Care+", "Hydration nudge",
        "You averaged 4 cups yesterday — aim for 8 today."),
    NewsItem("Care+", "Mindful minute",
        "Tap to try a 60-second breathing exercise."),
)

@Composable
private fun NewsRow(item: NewsItem) {
    val badge = sourceBadge(item.source)
    val urgentTint = MaterialTheme.colorScheme.error
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = androidx.compose.material3.CardDefaults.cardColors(
            if (item.isUrgent) urgentTint.copy(alpha = 0.06f)
            else MaterialTheme.colorScheme.surfaceVariant
        ),
    ) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            // Urgent left-edge stripe
            if (item.isUrgent) {
                Box(
                    Modifier.height(40.dp).background(urgentTint,
                        RoundedCornerShape(2.dp)).padding(horizontal = 1.5.dp)
                ) {}
            }
            Column(Modifier.padding(start = if (item.isUrgent) 8.dp else 0.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        Modifier.background(badge.copy(alpha = 0.18f),
                            RoundedCornerShape(99.dp))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) { Text(item.source, color = badge,
                        fontWeight = FontWeight.Bold, fontSize = 10.sp) }
                }
                Text(item.title, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(top = 4.dp))
                Text(item.subtitle,
                    color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp)
            }
        }
    }
}

/** Stable color per news source — mirrors iOS [NewsDrawerSheet]. */
private fun sourceBadge(source: String): androidx.compose.ui.graphics.Color =
    when (source.uppercase()) {
        "WHO"        -> CarePlusColor.Danger
        "MYCHART"    -> CarePlusColor.CareBlue
        "CDC"        -> CarePlusColor.Info
        "NIH"        -> CarePlusColor.TrainGreen
        "SCC HEALTH" -> CarePlusColor.Warning
        "CARE+"      -> CarePlusColor.DietCoral
        else         -> androidx.compose.ui.graphics.Color.Gray
    }
