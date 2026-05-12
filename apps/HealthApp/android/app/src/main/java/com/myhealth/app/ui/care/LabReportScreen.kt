package com.myhealth.app.ui.care

import android.graphics.BitmapFactory
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import com.myhealth.app.ui.theme.CarePlusColor
import com.myhealth.app.vision.LabReportOcr
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Snap-a-lab-report screen. Mirrors iOS [LabReportSheet]. Pipeline:
 * pick photo → on-device OCR → schema-aware extractor → review → save.
 * Photo + OCR text never leave the device.
 */
@Composable
fun LabReportScreen(vm: LabReportViewModel = hiltViewModel()) {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val tint = CarePlusColor.CareBlue
    var bitmap by remember { mutableStateOf<android.graphics.Bitmap?>(null) }
    var processing by remember { mutableStateOf(false) }
    var result by remember { mutableStateOf<LabReportOcr.Result?>(null) }
    var saved by remember { mutableStateOf(false) }

    val pick = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri ->
        uri ?: return@rememberLauncherForActivityResult
        processing = true
        scope.launch {
            try {
                val bmp = withContext(Dispatchers.IO) {
                    ctx.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it) }
                }
                bitmap = bmp
                if (bmp != null) result = vm.ocr.read(bmp)
            } finally { processing = false }
        }
    }

    Column(Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Snap lab report", fontSize = 22.sp, fontWeight = FontWeight.Bold)

        bitmap?.let {
            Image(bitmap = it.asImageBitmap(), contentDescription = null,
                modifier = Modifier.fillMaxWidth().height(200.dp))
        } ?: Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)) {
            Column(Modifier.padding(16.dp)) {
                Text("Snap or pick a printed lab summary.", fontWeight = FontWeight.Medium)
                Text("Photo and parsed text never leave this device.",
                    color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
            }
        }

        Button(onClick = { pick.launch("image/*") },
            colors = ButtonDefaults.buttonColors(containerColor = tint),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier.fillMaxWidth()) {
            Text("Pick image", color = androidx.compose.ui.graphics.Color.White)
        }

        if (processing) Row(Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center) { CircularProgressIndicator() }

        result?.let { r ->
            Card(Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp)) {
                Column(Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("Detected", fontWeight = FontWeight.SemiBold)
                    Field("A1C", r.a1c?.let { "%.1f".format(it) })
                    Field("Fasting glucose", r.fastingGlucose?.let { "${it} mg/dL" })
                    Field("Blood pressure",
                        if (r.bpSystolic != null && r.bpDiastolic != null)
                            "${r.bpSystolic}/${r.bpDiastolic}" else null)
                    Field("Total cholesterol", r.cholesterolTotal?.toString())
                    Field("LDL", r.ldl?.toString())
                    Field("HDL", r.hdl?.toString())
                    Field("Triglycerides", r.triglycerides?.toString())
                    Field("BMI", r.bmi?.let { "%.1f".format(it) })
                    Field("Weight", r.weightKg?.let { "%.1f kg".format(it) })
                }
            }
            Button(
                onClick = { scope.launch { vm.save(r); saved = true } },
                enabled = !saved,
                colors = ButtonDefaults.buttonColors(containerColor = tint),
                modifier = Modifier.fillMaxWidth()
            ) { Text(if (saved) "Saved" else "Save to my care plan",
                color = androidx.compose.ui.graphics.Color.White) }
        }
    }
}

@Composable
private fun Field(label: String, value: String?) =
    Row(Modifier.fillMaxWidth()) {
        Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontSize = 12.sp, modifier = Modifier.padding(end = 12.dp))
        Text(value ?: "—")
    }

@HiltViewModel
class LabReportViewModel @Inject constructor(
    val ocr: LabReportOcr,
) : ViewModel() {
    suspend fun save(@Suppress("UNUSED_PARAMETER") r: LabReportOcr.Result) {
        // TODO week-2: persist via existing /api/profile/metrics endpoints
        // (analogous to iOS LabReportSheet.save). For now no-op so the
        // screen compiles cleanly and the UX flow is testable end-to-end.
    }
}
