package com.myhealth.app.ui.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.myhealth.app.data.prefs.SettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settings: SettingsRepository,
    @dagger.hilt.android.qualifiers.ApplicationContext private val ctx: android.content.Context,
) : ViewModel() {
    val units: StateFlow<Boolean> = settings.unitsImperial
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)
    val isGuest: StateFlow<Boolean> = settings.isGuest
        .stateIn(viewModelScope, SharingStarted.Eagerly, true)

    private val _crashReports = kotlinx.coroutines.flow.MutableStateFlow(
        com.myhealth.app.crash.CrashReportingService.isEnabled(ctx)
    )
    val crashReports: StateFlow<Boolean> = _crashReports

    fun setUnits(v: Boolean) { viewModelScope.launch { settings.setUnitsImperial(v) } }
    fun setGuest(v: Boolean) { viewModelScope.launch { settings.setGuest(v) } }
    fun setCrashReports(v: Boolean) {
        com.myhealth.app.crash.CrashReportingService.setEnabled(ctx, v)
        _crashReports.value = v
    }
}

@Composable
fun SettingsScreen(vm: SettingsViewModel = hiltViewModel()) {
    val units by vm.units.collectAsStateWithLifecycle(false)
    val guest by vm.isGuest.collectAsStateWithLifecycle(true)
    val crashReports by vm.crashReports.collectAsStateWithLifecycle(false)
    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Text("Settings", fontSize = 28.sp, fontWeight = FontWeight.Bold)
        Text("Account", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(top = 12.dp))
        Text(if (guest) "Guest mode (local only)" else "Cloud-synced",
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        HorizontalDivider(Modifier.padding(vertical = 8.dp))
        Row("Imperial units", units) { vm.setUnits(it) }
        HorizontalDivider(Modifier.padding(vertical = 8.dp))
        Text("Privacy", color = MaterialTheme.colorScheme.primary,
            fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(top = 4.dp))
        Row("Send crash reports (Sentry)", crashReports) { vm.setCrashReports(it) }
        Text(
            "Off by default. When on, anonymous crash stack traces (no personal data) are sent to Sentry to help fix bugs.",
            fontSize = 11.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        HorizontalDivider(Modifier.padding(vertical = 8.dp))
        Text("Sign in for cloud sync (opens login screen — TODO)",
            color = MaterialTheme.colorScheme.primary, fontSize = 13.sp)
        Text("Export my data (JSON)", color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(top = 12.dp), fontSize = 13.sp)
        Text("Erase all on-device data", color = MaterialTheme.colorScheme.error,
            modifier = Modifier.padding(top = 12.dp), fontSize = 13.sp)
    }
}

@Composable
private fun Row(label: String, value: Boolean, onToggle: (Boolean) -> Unit) {
    androidx.compose.foundation.layout.Row(
        modifier = Modifier.padding(vertical = 4.dp),
        horizontalArrangement = androidx.compose.foundation.layout.Arrangement.SpaceBetween,
        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
    ) {
        Text(label, modifier = Modifier.padding(end = 16.dp))
        Switch(checked = value, onCheckedChange = onToggle)
    }
}
