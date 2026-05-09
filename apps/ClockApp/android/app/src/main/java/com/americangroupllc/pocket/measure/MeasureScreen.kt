package com.americangroupllc.pocket.measure

import android.content.Context
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.google.ar.core.ArCoreApk

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MeasureScreen() {
    val ctx = LocalContext.current
    val arSupported = remember { isArAvailable(ctx) }
    Scaffold(topBar = { TopAppBar(title = { Text("Measure") }) }) { padding ->
        Column(
            modifier = Modifier.padding(padding).fillMaxSize().padding(16.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (arSupported) {
                Text("ARCore available — point camera at a surface and tap two points to measure.")
                Spacer(Modifier.height(16.dp))
                Text("(MeasureSession scaffold — see measure/MeasureSession.kt for ARCore wiring.)")
            } else {
                Text("AR not available on this device. Use the on-screen ruler instead.")
                Spacer(Modifier.height(16.dp))
                Text("Ruler fallback: hold the phone flat against the object and align with the screen edge.")
            }
        }
    }
}

private fun isArAvailable(ctx: Context): Boolean {
    return try {
        val avail = ArCoreApk.getInstance().checkAvailability(ctx)
        avail == ArCoreApk.Availability.SUPPORTED_INSTALLED ||
        avail == ArCoreApk.Availability.SUPPORTED_APK_TOO_OLD ||
        avail == ArCoreApk.Availability.SUPPORTED_NOT_INSTALLED
    } catch (t: Throwable) { false }
}
