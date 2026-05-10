package com.myhealth.app.ui.activity

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
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
import com.myhealth.app.data.room.ActivityDao
import com.myhealth.app.data.room.ActivityEntity
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn

@HiltViewModel
class ActivityViewModel @Inject constructor(dao: ActivityDao) : ViewModel() {
    val activities: StateFlow<List<ActivityEntity>> = dao.observeAll()
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())
}

@Composable
fun ActivityListScreen(vm: ActivityViewModel = hiltViewModel()) {
    val acts by vm.activities.collectAsStateWithLifecycle(emptyList())
    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Text("Activities", fontSize = 28.sp, fontWeight = FontWeight.Bold)
        Text("Walking, gardening, chores — anything that moves you.",
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        LazyColumn(Modifier.padding(top = 8.dp)) {
            items(acts) { a ->
                Column(Modifier.padding(vertical = 8.dp)) {
                    Text(a.kind, fontWeight = FontWeight.SemiBold)
                    Text("${a.durationMin.toInt()} min · ${a.kcalBurned.toInt()} kcal",
                        color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
                }
            }
        }
    }
}
