package com.myhealth.app.ui.care

import android.graphics.BitmapFactory
import android.net.Uri
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
import androidx.compose.runtime.LaunchedEffect
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
import com.myhealth.app.data.secure.InsuranceCardDao
import com.myhealth.app.data.secure.InsuranceCardEntity
import com.myhealth.app.data.secure.SecureTokenStore
import com.myhealth.app.ui.theme.CarePlusColor
import com.myhealth.app.vision.InsuranceCardOcr
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Insurance card sheet — pick image → on-device OCR → review → save.
 * Image and raw OCR text never leave the device. Parsed fields land in
 * the SQLCipher PHI database via [InsuranceCardDao].
 */
@Composable
fun InsuranceCardScreen(vm: InsuranceCardViewModel = hiltViewModel()) {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    var imageUri by remember { mutableStateOf<Uri?>(null) }
    var bitmap by remember { mutableStateOf<android.graphics.Bitmap?>(null) }
    var processing by remember { mutableStateOf(false) }
    var result by remember { mutableStateOf<InsuranceCardOcr.Result?>(null) }
    var saved by remember { mutableStateOf(false) }
    val tint = CarePlusColor.CareBlue

    val pickImage = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri ->
        imageUri = uri
        if (uri == null) return@rememberLauncherForActivityResult
        processing = true
        scope.launch {
            try {
                val bmp = withContext(Dispatchers.IO) {
                    ctx.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it) }
                }
                bitmap = bmp
                if (bmp != null) {
                    result = vm.ocr.read(bmp)
                }
            } finally { processing = false }
        }
    }

    LaunchedEffect(Unit) { /* TODO: load latest card via vm.dao.latest() */ }

    Column(Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Insurance card", fontSize = 22.sp, fontWeight = FontWeight.Bold)

        bitmap?.let {
            Image(
                bitmap = it.asImageBitmap(), contentDescription = null,
                modifier = Modifier.fillMaxWidth().height(200.dp).padding(top = 4.dp)
            )
        } ?: Card(Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp)) {
                Text("Snap or pick the front of your card.", fontSize = 14.sp)
                Text("Image and parsed text never leave the device.",
                    color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
            }
        }

        Button(
            onClick = { pickImage.launch("image/*") },
            colors = ButtonDefaults.buttonColors(containerColor = tint),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier.fillMaxWidth(),
        ) { Text("Pick image", color = androidx.compose.ui.graphics.Color.White) }

        if (processing) Row(Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center) { CircularProgressIndicator() }

        result?.let { r ->
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("Detected", fontWeight = FontWeight.SemiBold)
                    Field("Payer", r.payer)
                    Field("Member ID", r.memberId)
                    Field("Group #", r.groupNumber)
                    Field("BIN", r.bin)
                    Field("PCN", r.pcn)
                    Field("RxGrp", r.rxGrp)
                }
            }
            Button(
                onClick = { scope.launch { vm.save(r); saved = true } },
                enabled = !saved,
                colors = ButtonDefaults.buttonColors(containerColor = tint),
                modifier = Modifier.fillMaxWidth()
            ) { Text(if (saved) "Saved" else "Save to my profile",
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
class InsuranceCardViewModel @Inject constructor(
    val ocr: InsuranceCardOcr,
    private val dao: InsuranceCardDao,
    private val secureTokens: SecureTokenStore,
) : ViewModel() {
    suspend fun save(r: InsuranceCardOcr.Result) {
        secureTokens.setInsuranceRawText(r.rawText)
        dao.upsert(InsuranceCardEntity(
            payer = r.payer, memberId = r.memberId, groupNumber = r.groupNumber,
            bin = r.bin, pcn = r.pcn, rxGrp = r.rxGrp
        ))
    }
}
