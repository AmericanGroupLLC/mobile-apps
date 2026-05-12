package com.myhealth.app.ui.onboarding

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
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
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Cake
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.HealthAndSafety
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.MedicalServices
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.health.connect.client.PermissionController
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.myhealth.app.data.prefs.SettingsRepository
import com.myhealth.app.health.HealthConnectGateway
import com.myhealth.app.ui.theme.CarePlusColor
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.launch

/**
 * Care+ 6-page onboarding (Android). Mirrors iOS
 * `Views/Onboarding/OnboardingFlowView.swift`:
 *   0 Welcome → 1 Login → 2 Birth → 3 Permissions → 4 Goal → 5 Health.
 *
 * Page 3 wires Health Connect's permission contract — fixes the
 * pre-Care+ gap where `HealthConnectGateway.readPermissions` was
 * declared but never actually requested.
 */
@Composable
fun OnboardingScreen(
    onComplete: () -> Unit,
    vm: OnboardingViewModel = hiltViewModel(),
) {
    val pagerState = rememberPagerState(pageCount = { 6 })
    val scope = rememberCoroutineScope()
    var name by remember { mutableStateOf("") }
    val selectedConditions = remember { mutableStateListOf<String>() }

    Box(
        Modifier.fillMaxSize().background(
            Brush.verticalGradient(
                listOf(
                    CarePlusColor.CareBlue.copy(alpha = 0.18f),
                    CarePlusColor.DietCoral.copy(alpha = 0.16f),
                    CarePlusColor.WorkoutPink.copy(alpha = 0.18f)
                )
            )
        )
    ) {
        HorizontalPager(state = pagerState, modifier = Modifier.fillMaxSize()) { page ->
            when (page) {
                0 -> WelcomePage { scope.launch { pagerState.animateScrollToPage(1) } }
                1 -> LoginPage { scope.launch { pagerState.animateScrollToPage(2) } }
                2 -> BirthPage(name, { name = it }) {
                    scope.launch { pagerState.animateScrollToPage(3) }
                }
                3 -> PermissionsPage { scope.launch { pagerState.animateScrollToPage(4) } }
                4 -> GoalPage { scope.launch { pagerState.animateScrollToPage(5) } }
                5 -> HealthIssuesPage(selectedConditions) {
                    vm.finish(name, selectedConditions.toSet())
                    onComplete()
                }
            }
        }
    }
}

@Composable
private fun WelcomePage(onNext: () -> Unit) = Column(
    Modifier.fillMaxSize().padding(24.dp),
    verticalArrangement = Arrangement.SpaceEvenly,
    horizontalAlignment = Alignment.CenterHorizontally
) {
    Spacer(Modifier.height(48.dp))
    Box(
        Modifier.size(120.dp).background(
            Brush.linearGradient(listOf(CarePlusColor.CareBlue, CarePlusColor.WorkoutPink)),
            CircleShape
        ),
        contentAlignment = Alignment.Center
    ) { Icon(Icons.Filled.Favorite, null, tint = Color.White,
        modifier = Modifier.size(56.dp)) }
    Text("Welcome to MyHealth", fontSize = 28.sp, fontWeight = FontWeight.Bold)
    Text(
        "Care · Diet · Train · Workout — your complete health companion. All on your device, plus optional clinical integration.",
        textAlign = TextAlign.Center,
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
    Button(onClick = onNext, modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.buttonColors(containerColor = CarePlusColor.CareBlue)) {
        Text("Get started", color = Color.White)
    }
}

@Composable
private fun LoginPage(onNext: () -> Unit) = Column(
    Modifier.fillMaxSize().padding(24.dp),
    verticalArrangement = Arrangement.spacedBy(12.dp)
) {
    Text("Sign in or continue", fontSize = 22.sp, fontWeight = FontWeight.Bold)
    Text("Sign in to sync across devices, or continue as a guest. Sync later from Settings.",
        color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp)
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    OutlinedTextField(value = email, onValueChange = { email = it },
        label = { Text("Email") }, modifier = Modifier.fillMaxWidth())
    OutlinedTextField(value = password, onValueChange = { password = it },
        label = { Text("Password") }, modifier = Modifier.fillMaxWidth())
    Button(onClick = onNext, modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.buttonColors(containerColor = CarePlusColor.CareBlue)) {
        Text("Continue as guest", color = Color.White)
    }
}

@Composable
private fun BirthPage(name: String, onName: (String) -> Unit, onNext: () -> Unit) = Column(
    Modifier.fillMaxSize().padding(24.dp),
    verticalArrangement = Arrangement.spacedBy(12.dp)
) {
    Text("Your birth details", fontSize = 22.sp, fontWeight = FontWeight.Bold)
    Text("Used for biological age + (opt-in) astro insights. Stored on this device.",
        color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp)
    OutlinedTextField(value = name, onValueChange = onName, label = { Text("Name") },
        modifier = Modifier.fillMaxWidth())
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(Icons.Filled.Cake, null, tint = CarePlusColor.CareBlue,
            modifier = Modifier.padding(end = 8.dp))
        Text("DOB picker — wired to a date dialog in week 2.",
            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
    }
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(Icons.Filled.AccessTime, null, tint = CarePlusColor.CareBlue,
            modifier = Modifier.padding(end = 8.dp))
        Text("Approximate time of birth — wired in week 2.",
            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
    }
    Spacer(Modifier.weight(1f))
    Button(onClick = onNext, modifier = Modifier.fillMaxWidth(), enabled = name.isNotBlank(),
        colors = ButtonDefaults.buttonColors(containerColor = CarePlusColor.CareBlue)) {
        Text("Continue", color = Color.White)
    }
}

@Composable
private fun PermissionsPage(onNext: () -> Unit) {
    var hcGranted by remember { mutableStateOf(false) }
    var notifGranted by remember { mutableStateOf(false) }
    var locGranted by remember { mutableStateOf(false) }

    val healthConnectLauncher = rememberLauncherForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { granted ->
        hcGranted = granted.isNotEmpty()
    }
    val notifLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted -> notifGranted = granted }
    val locLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted -> locGranted = granted }

    Column(
        Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("Permissions", fontSize = 22.sp, fontWeight = FontWeight.Bold)
        Text("Each is optional. Care+ works without any of them; features improve with each grant.",
            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp)

        PermRow(Icons.Filled.HealthAndSafety, "Health Connect",
            "Steps, HR, sleep, weight.", hcGranted) {
            healthConnectLauncher.launch(HealthConnectGateway.READ_PERMS)
        }
        PermRow(Icons.Filled.MedicalServices, "MyChart (SMART-on-FHIR)",
            "Read your conditions, meds, labs.", false) {
            // Full connect happens on the Care home tile after onboarding.
        }
        PermRow(Icons.Filled.Notifications, "Notifications",
            "Reminders for meds + standup timer.", notifGranted) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                notifLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            } else { notifGranted = true }
        }
        PermRow(Icons.Filled.LocationOn, "Location",
            "Doctor finder + run tracker.", locGranted) {
            locLauncher.launch(Manifest.permission.ACCESS_COARSE_LOCATION)
        }

        Spacer(Modifier.weight(1f))
        Button(onClick = onNext, modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = CarePlusColor.CareBlue)) {
            Text("Continue", color = Color.White)
        }
    }
}

@Composable
private fun PermRow(icon: ImageVector, title: String, subtitle: String,
                    granted: Boolean, onClick: () -> Unit) =
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(12.dp),
        onClick = onClick
    ) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, null, tint = CarePlusColor.CareBlue, modifier = Modifier.padding(end = 12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.SemiBold)
                Text(subtitle, fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (granted) Icon(Icons.Filled.CheckCircle, null, tint = CarePlusColor.Success)
        }
    }

@Composable
private fun GoalPage(onNext: () -> Unit) = Column(
    Modifier.fillMaxSize().padding(24.dp),
    verticalArrangement = Arrangement.spacedBy(12.dp)
) {
    Text("What's your goal?", fontSize = 22.sp, fontWeight = FontWeight.Bold)
    listOf("Lose weight","Maintain","Build muscle","Improve endurance","General wellness")
        .forEach { g ->
            Button(onClick = {}, modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )) { Text(g) }
        }
    Spacer(Modifier.weight(1f))
    Button(onClick = onNext, modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.buttonColors(containerColor = CarePlusColor.CareBlue)) {
        Text("Continue", color = Color.White)
    }
}

@Composable
private fun HealthIssuesPage(selected: MutableList<String>, onFinish: () -> Unit) {
    val all = listOf(
        "hypertension", "diabetesT2", "heartCondition", "asthma",
        "kneeInjury", "backPain", "anemia", "obesity"
    )
    Column(Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Any conditions to declare?", fontSize = 22.sp, fontWeight = FontWeight.Bold)
        Text("Used to filter unsafe exercises and tune food suggestions. On-device only.",
            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
        Column(modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp)) {
            all.forEach { key ->
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(checked = key in selected,
                        onCheckedChange = {
                            if (it) selected.add(key) else selected.remove(key)
                        })
                    Text(key.replaceFirstChar(Char::titlecase))
                }
            }
        }
        Button(onClick = onFinish, modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = CarePlusColor.CareBlue)) {
            Text("Finish", color = Color.White)
        }
    }
}

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val settings: SettingsRepository,
) : ViewModel() {
    fun finish(name: String, conditions: Set<String>) {
        viewModelScope.launch {
            settings.setDidOnboard(true)
            settings.setHealthConditions(conditions.ifEmpty { setOf("none") })
        }
    }
}
