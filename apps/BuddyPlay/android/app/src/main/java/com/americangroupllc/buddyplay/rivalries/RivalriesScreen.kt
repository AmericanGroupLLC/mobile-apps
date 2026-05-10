package com.americangroupllc.buddyplay.rivalries

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import com.americangroupllc.buddyplay.core.models.GameKind
import com.americangroupllc.buddyplay.core.models.Rivalry
import com.americangroupllc.buddyplay.core.storage.LocalRivalryStore
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@Composable
fun RivalriesScreen() {
    val vm: RivalriesViewModel = hiltViewModel()
    val list = vm.rivalries

    Column(Modifier.fillMaxSize().padding(20.dp)) {
        Text("Rivalries", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(12.dp))
        if (list.isEmpty()) {
            Text("No matches yet.", style = MaterialTheme.typography.titleMedium)
            Text(
                "Play someone and your head-to-head record will show up here. We never send this anywhere.",
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                items(list, key = { it.opponentId }) { r ->
                    RivalryRow(r)
                }
            }
        }
    }
}

@Composable
private fun RivalryRow(r: Rivalry) {
    Card {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(r.opponentName, style = MaterialTheme.typography.titleMedium)
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                GameKind.values().forEach { kind ->
                    val rec = r.perGame[kind]
                    if (rec != null && rec.totalPlayed > 0) {
                        Column {
                            Text(kind.displayName, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text("${rec.wins}W · ${rec.losses}L · ${rec.draws}D", style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                }
            }
        }
    }
}

@HiltViewModel
class RivalriesViewModel @Inject constructor(
    private val store: LocalRivalryStore,
) : ViewModel() {
    var rivalries: List<Rivalry> by mutableStateOf(store.loadAll().sortedByDescending { it.lastPlayedAt })
        private set

    fun reload() {
        rivalries = store.loadAll().sortedByDescending { it.lastPlayedAt }
    }
}
