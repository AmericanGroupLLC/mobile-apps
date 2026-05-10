package com.americangroupllc.offlineaibuddy.profile

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.americangroupllc.offlineaibuddy.core.models.Profile
import com.americangroupllc.offlineaibuddy.core.storage.ProfilesStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import javax.inject.Inject

@HiltViewModel
class ProfilesViewModel @Inject constructor(
    private val store: ProfilesStore,
) : ViewModel() {
    val profiles = MutableStateFlow(store.loadAll())
    val activeId = MutableStateFlow(store.loadAll().firstOrNull()?.id)

    fun setActive(id: String) { activeId.value = id }

    fun verify(pin: String, profileId: String): Boolean = store.verify(pin, profileId)
}

@Composable
fun ProfileSwitcherScreen(vm: ProfilesViewModel = hiltViewModel()) {
    val profiles by vm.profiles.collectAsState()
    val activeId by vm.activeId.collectAsState()
    var pinPromptingFor by remember { mutableStateOf<Profile?>(null) }

    LazyColumn(modifier = Modifier.fillMaxWidth().padding(16.dp)) {
        items(profiles, key = { it.id }) { p ->
            ListItem(
                headlineContent = { Text(p.name) },
                supportingContent = {
                    Text(
                        if (p.kind == Profile.Kind.ADULT) "Adult" else "Kid-Safe",
                    )
                },
                trailingContent = { if (p.id == activeId) Text("✓") },
                modifier = Modifier.padding(vertical = 4.dp),
            )
        }
    }
    pinPromptingFor?.let { p ->
        PinPromptScreen(profile = p) { pin ->
            if (vm.verify(pin, p.id)) {
                vm.setActive(p.id)
                pinPromptingFor = null
            }
        }
    }
}
