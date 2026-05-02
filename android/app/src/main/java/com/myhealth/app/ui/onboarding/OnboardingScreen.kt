package com.myhealth.app.ui.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.myhealth.core.models.HealthGoal
import com.myhealth.core.models.Sex
import kotlinx.coroutines.launch

@Composable
fun OnboardingScreen(onComplete: () -> Unit) {
    val pagerState = rememberPagerState(pageCount = { 4 })
    val scope = rememberCoroutineScope()

    var name by remember { mutableStateOf("") }
    var heightCm by remember { mutableStateOf(170f) }
    var weightKg by remember { mutableStateOf(65f) }
    var sex by remember { mutableStateOf(Sex.female) }
    var goal by remember { mutableStateOf(HealthGoal.maintain) }

    Box(
        Modifier.fillMaxSize().background(
            Brush.verticalGradient(
                listOf(
                    Color(0xFFFCE4EC),
                    Color(0xFFE1BEE7),
                    Color(0xFFC5CAE9)
                )
            )
        )
    ) {
        HorizontalPager(state = pagerState, modifier = Modifier.fillMaxSize()) { page ->
            when (page) {
                0 -> WelcomePage { scope.launch { pagerState.animateScrollToPage(1) } }
                1 -> ProfilePage(
                    name, { name = it },
                    sex, { sex = it },
                    heightCm, { heightCm = it },
                    weightKg, { weightKg = it },
                    onNext = { scope.launch { pagerState.animateScrollToPage(2) } }
                )
                2 -> GoalPage(goal, { goal = it },
                    onNext = { scope.launch { pagerState.animateScrollToPage(3) } })
                3 -> DonePage(name, onFinish = onComplete)
            }
        }
    }
}

@Composable
private fun WelcomePage(onNext: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.SpaceEvenly,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(48.dp))
        Box(
            Modifier.size(120.dp).background(
                Brush.linearGradient(listOf(Color(0xFFF9496F), Color(0xFFAF52DE))),
                CircleShape
            ),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Filled.Favorite, null, tint = Color.White,
                modifier = Modifier.size(56.dp))
        }
        Text("Welcome to MyHealth", fontSize = 32.sp, fontWeight = FontWeight.Bold)
        Text(
            "Your personal fitness OS — fitness, food, sleep, mood, vitals, and biological age. All on your device.",
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Button(onClick = onNext, modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
            Text("Get started")
        }
    }
}

@Composable
private fun ProfilePage(
    name: String, onName: (String) -> Unit,
    sex: Sex, onSex: (Sex) -> Unit,
    heightCm: Float, onHeight: (Float) -> Unit,
    weightKg: Float, onWeight: (Float) -> Unit,
    onNext: () -> Unit,
) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("Tell us about you", fontSize = 24.sp, fontWeight = FontWeight.Bold)
        OutlinedTextField(value = name, onValueChange = onName,
            label = { Text("Name") }, modifier = Modifier.fillMaxWidth())

        Text("Sex (for HealthKit)")
        SingleChoiceSegmentedButtonRow {
            Sex.values().forEachIndexed { i, s ->
                SegmentedButton(
                    selected = sex == s, onClick = { onSex(s) },
                    shape = SegmentedButtonDefaults.itemShape(i, Sex.values().size)
                ) { Text(s.name.replaceFirstChar { it.uppercase() }) }
            }
        }
        Text("Height: ${heightCm.toInt()} cm")
        Slider(value = heightCm, onValueChange = onHeight, valueRange = 120f..220f)
        Text("Weight: ${weightKg.toInt()} kg")
        Slider(value = weightKg, onValueChange = onWeight, valueRange = 30f..200f)
        Spacer(Modifier.weight(1f))
        Button(onClick = onNext, enabled = name.isNotBlank(),
            modifier = Modifier.fillMaxWidth()) { Text("Continue") }
    }
}

@Composable
private fun GoalPage(goal: HealthGoal, onSelect: (HealthGoal) -> Unit, onNext: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("What's your goal?", fontSize = 24.sp, fontWeight = FontWeight.Bold)
        HealthGoal.values().forEach { g ->
            Button(
                onClick = { onSelect(g) },
                modifier = Modifier.fillMaxWidth(),
                colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                    containerColor = if (goal == g) MaterialTheme.colorScheme.primary
                                      else MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Text(g.name.replace("_", " ").replaceFirstChar { it.uppercase() })
            }
        }
        Spacer(Modifier.weight(1f))
        Button(onClick = onNext, modifier = Modifier.fillMaxWidth()) { Text("Almost done") }
    }
}

@Composable
private fun DonePage(name: String, onFinish: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.SpaceEvenly,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("You're all set${if (name.isBlank()) "" else ", $name"}.",
            fontSize = 24.sp, fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center)
        Text("Open Vitals to scan your data. Add a medicine reminder. Log a meal. Everything stays private on this device.",
            textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Button(onClick = onFinish, modifier = Modifier.fillMaxWidth()) {
            Text("Enter MyHealth")
        }
    }
}

@Composable private fun Modifier.size(size: androidx.compose.ui.unit.Dp): Modifier =
    this.then(Modifier.width(size).height(size))
