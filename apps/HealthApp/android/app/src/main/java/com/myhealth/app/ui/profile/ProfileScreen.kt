package com.myhealth.app.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import com.myhealth.app.data.secure.InsuranceCardDao
import com.myhealth.app.data.secure.MyChartIssuerDao
import com.myhealth.app.data.secure.SecureTokenStore
import com.myhealth.app.fhir.EpicSandboxConfig
import com.myhealth.app.ui.theme.CarePlusColor
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.map

/**
 * Care+ Profile. Replaces the previous stub. Shows BMI auto-calc + a
 * profile-completion percentage so users know what's still missing
 * before week 2's MyChart-merge backfills more data.
 */
@Composable
fun ProfileScreen(vm: ProfileViewModel = hiltViewModel()) {
    var name by remember { mutableStateOf("") }
    var heightCm by remember { mutableFloatStateOf(170f) }
    var weightKg by remember { mutableFloatStateOf(65f) }
    val tint = CarePlusColor.CareBlue
    val sources by vm.sources.collectAsState(initial = emptyList())

    val bmi = if (heightCm > 0) weightKg / ((heightCm / 100f) * (heightCm / 100f)) else 0f
    val completion = listOf(name.isNotEmpty(), heightCm > 0, weightKg > 0)
        .count { it } * 100 / 3

    Column(Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Profile", fontSize = 28.sp, fontWeight = FontWeight.Bold)

        Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)) {
            Column(Modifier.padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Profile completion", modifier = Modifier.weight(1f))
                    Text("$completion%", color = tint, fontWeight = FontWeight.Bold)
                }
                Spacer(Modifier.height(6.dp))
                LinearProgressIndicator(
                    progress = { completion / 100f },
                    modifier = Modifier.fillMaxWidth(),
                    color = tint,
                )
                Text("Complete your profile so MyChart imports merge cleanly.",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontSize = 11.sp, modifier = Modifier.padding(top = 6.dp))
            }
        }

        OutlinedTextField(value = name, onValueChange = { name = it },
            label = { Text("Name") }, modifier = Modifier.fillMaxWidth())

        Text("Height: ${heightCm.toInt()} cm", fontWeight = FontWeight.SemiBold)
        Slider(value = heightCm, onValueChange = { heightCm = it }, valueRange = 120f..220f)

        Text("Weight: ${weightKg.toInt()} kg", fontWeight = FontWeight.SemiBold)
        Slider(value = weightKg, onValueChange = { weightKg = it }, valueRange = 30f..200f)

        HorizontalDivider()

        Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)) {
            Row(Modifier.padding(16.dp).fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically) {
                Text("BMI", modifier = Modifier.weight(1f))
                Text("%.1f".format(bmi), fontWeight = FontWeight.Bold)
                Text(bmiLabel(bmi), color = bmiColor(bmi), fontWeight = FontWeight.SemiBold,
                    modifier = Modifier
                        .padding(start = 8.dp)
                        .background(bmiColor(bmi).copy(alpha = 0.18f), RoundedCornerShape(99.dp))
                        .padding(horizontal = 8.dp, vertical = 2.dp))
            }
        }

        // ── Connected sources ───────────────────────────────────
        Text("Connected sources", fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(top = 8.dp))
        sources.forEach { src ->
            Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)) {
                Row(Modifier.padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically) {
                    Text(src.label, modifier = Modifier.weight(1f))
                    when (src.status) {
                        SourceStatus.CONNECTED -> Text("✓",
                            color = CarePlusColor.Success, fontWeight = FontWeight.Bold)
                        SourceStatus.NOT_CONNECTED -> Text("Connect",
                            color = tint, fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
                        SourceStatus.ADD -> Text("Add",
                            color = tint, fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
                    }
                }
            }
        }
    }
}

data class ConnectedSource(val label: String, val status: SourceStatus)

enum class SourceStatus { CONNECTED, NOT_CONNECTED, ADD }

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val secureTokens: SecureTokenStore,
    private val insuranceDao: InsuranceCardDao,
    private val mychartDao: MyChartIssuerDao,
) : ViewModel() {
    val sources = mychartDao.observeAll().map { issuers ->
        listOf(
            ConnectedSource("Health Connect", SourceStatus.CONNECTED), // optimistic
            ConnectedSource("Epic MyChart",
                if (issuers.isNotEmpty()
                    || secureTokens.fhirAccessToken(EpicSandboxConfig.ISSUER) != null)
                    SourceStatus.CONNECTED else SourceStatus.NOT_CONNECTED),
            ConnectedSource("Insurance card",
                // Snapshot read; for week-1 we re-emit on each subscribe.
                if (kotlinx.coroutines.runBlocking { insuranceDao.latest() } != null)
                    SourceStatus.CONNECTED else SourceStatus.NOT_CONNECTED),
            ConnectedSource("Pharmacy", SourceStatus.ADD),
        )
    }
}

private fun bmiLabel(b: Float) = when {
    b < 18.5f -> "Under"
    b < 25f -> "Normal"
    b < 30f -> "Over"
    else -> "Obese"
}

private fun bmiColor(b: Float): Color = when {
    b < 18.5f -> CarePlusColor.Info
    b < 25f -> CarePlusColor.Success
    b < 30f -> CarePlusColor.Warning
    else -> CarePlusColor.Danger
}
