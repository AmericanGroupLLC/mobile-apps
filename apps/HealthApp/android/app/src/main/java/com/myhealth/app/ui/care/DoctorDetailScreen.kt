package com.myhealth.app.ui.care

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import com.myhealth.app.data.secure.ProviderDao
import com.myhealth.app.data.secure.ProviderEntity
import com.myhealth.app.ui.theme.CarePlusColor
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.launch

/**
 * Doctor detail. Week 1: shows what we have from NPPES + a "Save" button
 * that writes a [ProviderEntity] into the SQLCipher PHI database.
 *
 * Routes to here are `doctor_detail/{npi}` — for week 1 the screen takes
 * the NPI as a navigation argument and re-queries minimal fields. A
 * future revision will pass the full Provider via a viewModel-scoped
 * shared flow to avoid the second round-trip.
 */
@Composable
fun DoctorDetailScreen(npi: String, vm: DoctorDetailViewModel = hiltViewModel()) {
    val tint = CarePlusColor.CareBlue
    var saved by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    Column(Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Provider details", fontSize = 22.sp, fontWeight = FontWeight.Bold)
        Text("NPI: $npi", color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)

        Card(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(12.dp)) {
                Text("Detail look-ups call NPPES via the backend in week 2.",
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text("Booking via Ribbon Health (v1.1).",
                    color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
            }
        }

        Button(
            onClick = { scope.launch { vm.favorite(npi); saved = true } },
            enabled = !saved,
            colors = ButtonDefaults.buttonColors(containerColor = tint),
            shape = RoundedCornerShape(14.dp),
            modifier = Modifier.fillMaxWidth(),
        ) { Text(if (saved) "Saved" else "Save to favorites",
            color = androidx.compose.ui.graphics.Color.White) }
    }
}

@HiltViewModel
class DoctorDetailViewModel @Inject constructor(
    private val dao: ProviderDao,
) : ViewModel() {
    suspend fun favorite(npi: String) {
        dao.upsert(ProviderEntity(npi = npi, name = "NPI $npi"))
    }
}
