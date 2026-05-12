package com.myhealth.app.ui.diet

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.myhealth.app.data.prefs.SettingsRepository
import com.myhealth.app.data.vendor.VendorRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

@Composable
fun VendorBrowseScreen(vm: VendorBrowseViewModel = hiltViewModel()) {
    val state by vm.state.collectAsState()
    LaunchedEffect(Unit) { vm.load() }

    Column(Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Meal vendors", fontSize = 22.sp, fontWeight = FontWeight.Bold)

        when (val s = state) {
            VendorState.Loading -> CircularProgressIndicator()
            is VendorState.Error -> Text(s.message, color = MaterialTheme.colorScheme.error)
            is VendorState.Ready -> {
                Text(s.summary, fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(s.vendors) { v ->
                        Card(Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(12.dp)) {
                                Text(v.name, fontWeight = FontWeight.Bold)
                                v.cuisine?.let { Text(it, fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant) }
                                v.calories_per_meal_avg?.let {
                                    Text("$it kcal avg",
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                                v.blurb?.let { Text(it, fontSize = 12.sp) }
                            }
                        }
                    }
                }
            }
        }
    }
}

sealed interface VendorState {
    object Loading : VendorState
    data class Ready(val vendors: List<VendorRepository.Vendor>, val summary: String) : VendorState
    data class Error(val message: String) : VendorState
}

@HiltViewModel
class VendorBrowseViewModel @Inject constructor(
    private val repo: VendorRepository,
    private val settings: SettingsRepository,
) : ViewModel() {
    private val _state = MutableStateFlow<VendorState>(VendorState.Loading)
    val state: StateFlow<VendorState> = _state

    fun load() {
        viewModelScope.launch {
            _state.value = VendorState.Loading
            val conditions = settings.healthConditions.first()
                .filter { it != "none" }
            try {
                val vendors = repo.menu(conditions.toList())
                val summary = if (conditions.isEmpty())
                    "Showing all vendors. Declare conditions in Profile to filter."
                else "Filtered for: ${conditions.joinToString(", ")}"
                _state.value = VendorState.Ready(vendors, summary)
            } catch (e: Exception) {
                _state.value = VendorState.Error(e.message ?: "Load failed.")
            }
        }
    }
}
