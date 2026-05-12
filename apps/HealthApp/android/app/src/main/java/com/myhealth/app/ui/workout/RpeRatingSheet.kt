package com.myhealth.app.ui.workout

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
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
import androidx.lifecycle.viewModelScope
import com.myhealth.app.data.secure.RpeLogDao
import com.myhealth.app.data.secure.RpeLogEntity
import com.myhealth.app.ui.theme.CarePlusColor
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.launch

/**
 * Post-workout RPE rating sheet (Borg CR-10). First app-wide use of
 * [ModalBottomSheet]. Persists to the SQLCipher PHI database via
 * [RpeLogDao].
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RpeRatingSheet(
    onDismiss: () -> Unit,
    vm: RpeRatingViewModel = hiltViewModel(),
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val tint = CarePlusColor.WorkoutPink
    var rating by remember { mutableFloatStateOf(6f) }
    var notes by remember { mutableStateOf("") }
    var saved by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(saved) {
        if (saved) {
            kotlinx.coroutines.delay(500)
            onDismiss()
        }
    }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(Modifier.padding(24.dp).fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("Rate this workout", fontSize = 22.sp, fontWeight = FontWeight.Bold)
            Text("Borg CR-10 — useful for the adaptive plan.",
                color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)

            Row { Text("1"); Slider(value = rating, onValueChange = { rating = it },
                valueRange = 1f..10f, steps = 8, modifier = Modifier.weight(1f)); Text("10") }
            Text("RPE ${rating.toInt()}", fontSize = 28.sp, fontWeight = FontWeight.Bold,
                color = tint)
            Text(rpeLabel(rating.toInt()),
                color = tint, fontWeight = FontWeight.SemiBold)

            OutlinedTextField(
                value = notes, onValueChange = { notes = it },
                label = { Text("Notes (optional)") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            Button(
                onClick = {
                    scope.launch {
                        vm.save(rating.toInt(), notes.takeIf { it.isNotBlank() })
                        saved = true
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = !saved,
                colors = ButtonDefaults.buttonColors(containerColor = tint)
            ) { Text(if (saved) "Saved" else "Save RPE ${rating.toInt()}",
                color = androidx.compose.ui.graphics.Color.White) }
        }
    }
}

private fun rpeLabel(r: Int) = when (r) {
    1 -> "Nothing at all"
    2 -> "Extremely light"
    3 -> "Very light"
    4 -> "Light"
    5 -> "Moderate"
    6 -> "Somewhat hard"
    7 -> "Hard"
    8 -> "Very hard"
    9 -> "Extremely hard"
    10 -> "Maximal"
    else -> ""
}

@HiltViewModel
class RpeRatingViewModel @Inject constructor(
    private val dao: RpeLogDao,
) : ViewModel() {
    suspend fun save(rating: Int, notes: String?) {
        dao.insert(RpeLogEntity(rating = rating, notes = notes))
    }
}
