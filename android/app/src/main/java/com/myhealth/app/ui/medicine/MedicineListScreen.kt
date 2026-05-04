package com.myhealth.app.ui.medicine

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
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
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.myhealth.app.data.room.MedicineEntity

@Composable
fun MedicineListScreen(vm: MedicineViewModel = hiltViewModel()) {
    val meds by vm.medicines.collectAsStateWithLifecycle(emptyList())
    var showAdd by remember { mutableStateOf(false) }

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(onClick = { showAdd = true }) {
                Icon(Icons.Filled.Add, "Add medicine")
            }
        }
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding).padding(16.dp)) {
            Text("Medicines", fontSize = 28.sp, fontWeight = FontWeight.Bold)
            Text("On-device reminders, no account needed.",
                color = MaterialTheme.colorScheme.onSurfaceVariant)

            if (meds.isEmpty()) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("No medicines yet — tap + to add one.")
                }
            } else {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.padding(top = 12.dp)) {
                    items(meds, key = { it.id }) { MedicineRow(it) }
                }
            }
        }

        if (showAdd) {
            AddMedicineDialog(
                onDismiss = { showAdd = false },
                onSave = { name, dosage, hour, minute ->
                    vm.add(name, dosage, hour, minute)
                    showAdd = false
                }
            )
        }
    }
}

@Composable
private fun MedicineRow(m: MedicineEntity) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Box(Modifier.padding(12.dp)) {
            Column {
                Text(m.name, fontWeight = FontWeight.Bold)
                Text("${m.dosage} · ${m.eatWhen}",
                    color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
            }
            Box(Modifier.size(20.dp).align(Alignment.TopEnd)) {
                Box(
                    Modifier.size(20.dp)
                        .background(MaterialTheme.colorScheme.primary, CircleShape)
                ) {} // colour swatch placeholder
            }
        }
    }
}

@Composable
private fun AddMedicineDialog(
    onDismiss: () -> Unit,
    onSave: (name: String, dosage: String, hour: Int, minute: Int) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var dosage by remember { mutableStateOf("1 tablet") }
    var hour by remember { mutableStateOf("9") }
    var minute by remember { mutableStateOf("0") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("New medicine") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = name, onValueChange = { name = it },
                    label = { Text("Name") })
                OutlinedTextField(value = dosage, onValueChange = { dosage = it },
                    label = { Text("Dosage") })
                HorizontalDivider()
                Text("First reminder time")
                Box(Modifier.fillMaxWidth()) {
                    OutlinedTextField(value = hour, onValueChange = { hour = it },
                        label = { Text("Hour (0-23)") })
                }
                OutlinedTextField(value = minute, onValueChange = { minute = it },
                    label = { Text("Minute (0-59)") })
            }
        },
        confirmButton = {
            Button(onClick = {
                onSave(name, dosage, hour.toIntOrNull() ?: 9, minute.toIntOrNull() ?: 0)
            }, enabled = name.isNotBlank()) { Text("Save") }
        },
        dismissButton = { Button(onClick = onDismiss) { Text("Cancel") } }
    )
}
