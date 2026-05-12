package com.myhealth.app.ui.diet

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
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.navigation.NavController
import com.myhealth.app.data.prefs.SettingsRepository
import com.myhealth.app.ui.Routes
import com.myhealth.app.ui.shell.AppHeader
import com.myhealth.app.ui.theme.CarePlusColor
import com.myhealth.app.ui.theme.CareTab
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking

/**
 * Diet tab home matching the design-spec mockup. Mirrors iOS
 * `DietHomeView`. The existing diary screen is reachable via
 * "Open food diary".
 */
@Composable
fun DietHomeScreen(
    nav: NavController,
    vm: DietHomeViewModel = hiltViewModel(),
) {
    val tint = CarePlusColor.DietCoral
    val condition by vm.priorityCondition.collectAsState(initial = null)
    var waterCups by remember { mutableIntStateOf(5) }
    val kcalConsumed = 1420
    val kcalGoal = 1800

    Column(Modifier.fillMaxSize()) {
        AppHeader(
            tab = CareTab.Diet,
            onProfile = { nav.navigate(Routes.PROFILE) },
            onBell = { nav.navigate(Routes.NEWS_DRAWER) },
        )
        LazyColumn(
            Modifier.fillMaxSize().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                Column {
                    Text("Today · $kcalConsumed / $kcalGoal kcal",
                        fontWeight = FontWeight.SemiBold)
                    LinearProgressIndicator(
                        progress = { kcalConsumed.toFloat() / kcalGoal },
                        modifier = Modifier.fillMaxWidth().padding(top = 4.dp),
                        color = tint
                    )
                }
            }

            condition?.let { c ->
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth()
                            .clickable { nav.navigate(Routes.VENDOR_BROWSE) },
                        colors = CardDefaults.cardColors(tint.copy(alpha = 0.10f)),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Row(Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.AutoAwesome, null, tint = tint,
                                modifier = Modifier.padding(end = 8.dp))
                            Column {
                                Text("For your $c",
                                    color = tint, fontWeight = FontWeight.SemiBold)
                                Text(bannerCopy(c), fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                }
            }

            item {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    MacroTile("Protein", "82g", Modifier.weight(1f))
                    MacroTile("Carbs", "140g", Modifier.weight(1f))
                    MacroTile("Fat", "42g", Modifier.weight(1f))
                }
            }

            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(CarePlusColor.Info.copy(alpha = 0.10f)),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Row(Modifier.padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.WaterDrop, null, tint = CarePlusColor.Info,
                            modifier = Modifier.padding(end = 8.dp))
                        Column(Modifier.weight(1f)) {
                            Text("Water", fontWeight = FontWeight.SemiBold)
                            Text("$waterCups of 8 cups",
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                fontSize = 12.sp)
                        }
                        IconButton(onClick = { waterCups++ }) {
                            Icon(Icons.Filled.AddCircle, null, tint = CarePlusColor.Info)
                        }
                    }
                }
            }

            item {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Order nearby",
                        fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                    Text("See all", color = tint, fontWeight = FontWeight.SemiBold,
                        fontSize = 12.sp,
                        modifier = Modifier.clickable { nav.navigate(Routes.VENDOR_BROWSE) })
                }
            }
            item { VendorPreview("Sweetgreen", "Harvest bowl · 480 kcal") {
                nav.navigate(Routes.VENDOR_BROWSE) } }
            item { VendorPreview("Mendocino Farms", "Salmon plate · 540 kcal") {
                nav.navigate(Routes.VENDOR_BROWSE) } }

            item {
                Card(
                    modifier = Modifier.fillMaxWidth()
                        .clickable { nav.navigate(Routes.MEAL_LOG_ENTRY) },
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Row(Modifier.padding(12.dp)) {
                        Text("Open food diary", fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.weight(1f))
                    }
                }
            }
        }
    }
}

@Composable
private fun MacroTile(label: String, value: String, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Column(
            Modifier.fillMaxWidth().padding(vertical = 12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
            Text(value, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
private fun VendorPreview(name: String, subtitle: String, onClick: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(name, fontWeight = FontWeight.SemiBold)
                Text(subtitle, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
            }
        }
    }
}

private fun bannerCopy(condition: String): String = when (condition.lowercase()) {
    "hypertension" -> "Low-sodium meals nearby"
    "heartcondition" -> "Mediterranean & DASH plates"
    "diabetest1", "diabetest2" -> "Lower-glycemic meals nearby"
    "kidneyissue" -> "Low-K, low-P meals nearby"
    else -> "Suggestions tailored to you"
}

@HiltViewModel
class DietHomeViewModel @Inject constructor(
    settings: SettingsRepository,
) : ViewModel() {
    private val priority = listOf("diabetest2","diabetest1","hypertension",
                                  "heartcondition","kidneyissue")
    val priorityCondition = settings.healthConditions.map { set ->
        priority.firstOrNull { it in set.map(String::lowercase) }
    }
}
