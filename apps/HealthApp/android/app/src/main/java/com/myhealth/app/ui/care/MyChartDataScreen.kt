package com.myhealth.app.ui.care

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.myhealth.app.fhir.FhirRepository
import com.myhealth.app.ui.theme.CarePlusColor
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

/**
 * Renders the connected patient's summary + counts of every Care+ v1
 * resource. Mirrors iOS `Views/Care/MyChartDataView.swift`.
 */
@Composable
fun MyChartDataScreen(vm: MyChartDataViewModel = hiltViewModel()) {
    val state by vm.state.collectAsState()
    val tint = CarePlusColor.CareBlue

    LaunchedEffect(Unit) { vm.load() }

    Column(Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("MyChart records", fontSize = 22.sp, fontWeight = FontWeight.Bold)

        when (val s = state) {
            is MyChartDataState.Loading -> Row(
                Modifier.fillMaxWidth().padding(16.dp),
                horizontalArrangement = Arrangement.Center
            ) { CircularProgressIndicator() }

            is MyChartDataState.Error -> Text(s.message, color = MaterialTheme.colorScheme.error)

            is MyChartDataState.Ready -> {
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(12.dp)) {
                        Text(s.patient.displayName, fontWeight = FontWeight.Bold)
                        s.patient.gender?.let { Text("Sex: ${it.replaceFirstChar(Char::titlecase)}",
                            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp) }
                        s.patient.birthDate?.let { Text("DOB: $it",
                            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp) }
                    }
                }
                Text("Resource counts", fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(top = 8.dp))
                listOf(
                    "Condition" to "Conditions",
                    "MedicationStatement" to "Medications",
                    "AllergyIntolerance" to "Allergies",
                    "Observation" to "Observations",
                    "Encounter" to "Encounters",
                    "Immunization" to "Immunizations",
                    "Appointment" to "Appointments",
                ).forEach { (key, label) ->
                    Card(Modifier.fillMaxWidth()) {
                        Row(Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically) {
                            Text(label, modifier = Modifier.weight(1f))
                            Text("${s.counts[key] ?: 0}",
                                color = tint, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }
}

sealed interface MyChartDataState {
    object Loading : MyChartDataState
    data class Ready(val patient: FhirRepository.PatientSummary,
                     val counts: Map<String, Int>) : MyChartDataState
    data class Error(val message: String) : MyChartDataState
}

@HiltViewModel
class MyChartDataViewModel @Inject constructor(
    private val repo: FhirRepository,
) : ViewModel() {
    private val _state = MutableStateFlow<MyChartDataState>(MyChartDataState.Loading)
    val state: StateFlow<MyChartDataState> = _state

    fun load() {
        viewModelScope.launch {
            _state.value = MyChartDataState.Loading
            try {
                val patientId = "erXuFYUfucBZaryVksYEcMg3" // sandbox demo patient
                val patient = repo.patient(patientId)
                val counts = repo.summaryCounts(patientId)
                _state.value = MyChartDataState.Ready(patient, counts)
            } catch (e: Exception) {
                _state.value = MyChartDataState.Error(e.message ?: "Unknown error")
            }
        }
    }
}
