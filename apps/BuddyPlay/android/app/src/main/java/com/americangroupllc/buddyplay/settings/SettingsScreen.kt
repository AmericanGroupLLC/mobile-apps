package com.americangroupllc.buddyplay.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.americangroupllc.buddyplay.core.connectivity.ConnectivityBridge
import com.americangroupllc.buddyplay.core.models.GameKind
import com.americangroupllc.buddyplay.core.storage.DeviceIdProvider
import com.americangroupllc.buddyplay.core.storage.LocalRivalryStore
import com.americangroupllc.buddyplay.data.SettingsRepo
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import javax.inject.Inject

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen() {
    val vm: SettingsViewModel = hiltViewModel()
    var showEraseConfirm by remember { mutableStateOf(false) }
    var showResetIdConfirm by remember { mutableStateOf(false) }

    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text("Settings", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)

        SectionTitle("Profile")
        OutlinedTextField(
            value = vm.displayName,
            onValueChange = vm::updateDisplayName,
            label = { Text("Display name") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )

        SectionTitle("Connectivity")
        ConnectivityBridge.Preference.values().forEach { p ->
            Row(
                Modifier.fillMaxWidth().clickable { vm.updateConnectivityPref(p) }.padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                RadioButton(selected = vm.connectivityPref == p, onClick = { vm.updateConnectivityPref(p) })
                Text(when (p) {
                    ConnectivityBridge.Preference.AUTO     -> "Auto"
                    ConnectivityBridge.Preference.WIFI_ONLY -> "Wi-Fi only"
                    ConnectivityBridge.Preference.BLE_ONLY  -> "BLE only"
                })
            }
        }

        SectionTitle("Game")
        GameKind.values().forEach { kind ->
            Row(
                Modifier.fillMaxWidth().clickable { vm.updateDefaultGame(kind) }.padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                RadioButton(selected = vm.defaultGame == kind, onClick = { vm.updateDefaultGame(kind) })
                Text(kind.displayName)
            }
        }

        SectionTitle("Feedback")
        SwitchRow("Sound", vm.soundEnabled, vm::updateSoundEnabled)
        SwitchRow("Haptics", vm.hapticsEnabled, vm::updateHapticsEnabled)

        SectionTitle("Privacy")
        Text("BuddyPlay does not send any data.", style = MaterialTheme.typography.bodyMedium)
        Button(onClick = { showEraseConfirm = true }) { Text("Erase all rivalries") }
        Button(onClick = { showResetIdConfirm = true }) { Text("Reset device ID") }

        Spacer(Modifier.height(16.dp))
        Text("BuddyPlay v1.0 · MIT-licensed",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }

    if (showEraseConfirm) {
        AlertDialog(
            onDismissRequest = { showEraseConfirm = false },
            title = { Text("Erase all rivalries?") },
            text = { Text("This wipes every win/loss tally on this device. There's no cloud backup — this is the only copy.") },
            confirmButton = { TextButton(onClick = { vm.eraseAllRivalries(); showEraseConfirm = false }) { Text("Erase") } },
            dismissButton = { TextButton(onClick = { showEraseConfirm = false }) { Text("Cancel") } }
        )
    }
    if (showResetIdConfirm) {
        AlertDialog(
            onDismissRequest = { showResetIdConfirm = false },
            title = { Text("Reset device ID?") },
            text = { Text("Other phones will see you as a brand-new opponent (rivalries restart).") },
            confirmButton = { TextButton(onClick = { vm.resetDeviceId(); showResetIdConfirm = false }) { Text("Reset") } },
            dismissButton = { TextButton(onClick = { showResetIdConfirm = false }) { Text("Cancel") } }
        )
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(text, style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
}

@Composable
private fun SwitchRow(label: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(
        Modifier.fillMaxWidth().padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onCheckedChange)
    }
}

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val repo: SettingsRepo,
    private val rivalryStore: LocalRivalryStore,
    private val deviceIds: DeviceIdProvider,
) : ViewModel() {

    var displayName by mutableStateOf("Player")
        private set
    var connectivityPref by mutableStateOf(ConnectivityBridge.Preference.AUTO)
        private set
    var defaultGame by mutableStateOf(GameKind.CHESS)
        private set
    var soundEnabled by mutableStateOf(true)
        private set
    var hapticsEnabled by mutableStateOf(true)
        private set

    init {
        viewModelScope.launch { repo.displayName.collectLatest { displayName = it } }
        viewModelScope.launch { repo.connectivityPreference.collectLatest { connectivityPref = it } }
        viewModelScope.launch { repo.defaultGame.collectLatest { defaultGame = it } }
        viewModelScope.launch { repo.soundEnabled.collectLatest { soundEnabled = it } }
        viewModelScope.launch { repo.hapticsEnabled.collectLatest { hapticsEnabled = it } }
    }

    fun updateDisplayName(name: String) { displayName = name; viewModelScope.launch { repo.setDisplayName(name) } }
    fun updateConnectivityPref(p: ConnectivityBridge.Preference) { connectivityPref = p; viewModelScope.launch { repo.setConnectivityPreference(p) } }
    fun updateDefaultGame(k: GameKind) { defaultGame = k; viewModelScope.launch { repo.setDefaultGame(k) } }
    fun updateSoundEnabled(v: Boolean) { soundEnabled = v; viewModelScope.launch { repo.setSoundEnabled(v) } }
    fun updateHapticsEnabled(v: Boolean) { hapticsEnabled = v; viewModelScope.launch { repo.setHapticsEnabled(v) } }

    fun eraseAllRivalries() = rivalryStore.eraseAll()
    fun resetDeviceId() { deviceIds.reset() }
}
