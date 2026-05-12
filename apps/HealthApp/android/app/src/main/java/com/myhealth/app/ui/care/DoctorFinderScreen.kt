package com.myhealth.app.ui.care

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.navigation.NavController
import com.myhealth.app.network.ApiBaseUrl
import com.myhealth.app.ui.Routes
import com.myhealth.app.ui.theme.CarePlusColor
import dagger.hilt.android.lifecycle.HiltViewModel
import io.ktor.client.HttpClient
import io.ktor.client.request.get
import io.ktor.client.statement.bodyAsText
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
data class Provider(
    val npi: String,
    val name: String,
    val specialty: String? = null,
    val phone: String? = null,
    val address_line: String? = null,
    val zip: String? = null,
)

@Serializable
private data class ProvidersResponse(val providers: List<Provider>)

@Composable
fun DoctorFinderScreen(nav: NavController, vm: DoctorFinderViewModel = hiltViewModel()) {
    val tint = CarePlusColor.CareBlue
    var zip by remember { mutableStateOf("") }
    var specialty by remember { mutableStateOf("") }
    val state by vm.state.collectAsState()

    Column(Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Find a doctor", fontSize = 22.sp, fontWeight = FontWeight.Bold)

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(value = zip, onValueChange = { zip = it.filter(Char::isDigit).take(5) },
                label = { Text("ZIP") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.weight(1f))
            OutlinedTextField(value = specialty, onValueChange = { specialty = it },
                label = { Text("Specialty") }, modifier = Modifier.weight(2f))
        }
        Button(
            onClick = { vm.search(zip, specialty) },
            enabled = zip.length == 5,
            colors = ButtonDefaults.buttonColors(containerColor = tint),
            shape = RoundedCornerShape(10.dp),
            modifier = Modifier.fillMaxWidth(),
        ) { Text("Search", color = androidx.compose.ui.graphics.Color.White) }

        when (val s = state) {
            DoctorFinderState.Idle -> Unit
            DoctorFinderState.Loading -> CircularProgressIndicator()
            is DoctorFinderState.Error -> Text(s.message, color = MaterialTheme.colorScheme.error)
            is DoctorFinderState.Ready -> LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                items(s.providers) { p ->
                    Card(Modifier.fillMaxWidth().clickable {
                        // Stash the selected provider for the detail screen via the nav arg.
                        // Week 1 keeps it simple: route includes the NPI; detail re-queries.
                        nav.navigate("${Routes.DOCTOR_DETAIL}/${p.npi}")
                    }) {
                        Column(Modifier.padding(12.dp)) {
                            Text(p.name, fontWeight = FontWeight.Bold)
                            p.specialty?.let { Text(it, fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant) }
                            p.address_line?.let { Text(it, fontSize = 11.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant) }
                        }
                    }
                }
            }
        }
    }
}

sealed interface DoctorFinderState {
    object Idle : DoctorFinderState
    object Loading : DoctorFinderState
    data class Ready(val providers: List<Provider>) : DoctorFinderState
    data class Error(val message: String) : DoctorFinderState
}

@HiltViewModel
class DoctorFinderViewModel @Inject constructor(
    private val http: HttpClient,
    private val json: Json,
    private val apiBase: ApiBaseUrl,
) : ViewModel() {
    private val _state = MutableStateFlow<DoctorFinderState>(DoctorFinderState.Idle)
    val state: StateFlow<DoctorFinderState> = _state

    fun search(zip: String, specialty: String) {
        viewModelScope.launch {
            _state.value = DoctorFinderState.Loading
            try {
                val s = if (specialty.isBlank()) "" else "&specialty=$specialty"
                val raw = http.get("${apiBase.value}/api/doctors/search?zip=$zip$s").bodyAsText()
                _state.value = DoctorFinderState.Ready(
                    json.decodeFromString(ProvidersResponse.serializer(), raw).providers
                )
            } catch (e: Exception) {
                _state.value = DoctorFinderState.Error(e.message ?: "Search failed.")
            }
        }
    }
}
