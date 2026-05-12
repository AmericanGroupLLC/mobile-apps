package com.myhealth.app.ui.care

import android.app.Activity
import android.content.Intent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.navigation.NavController
import com.myhealth.app.fhir.EpicSandboxConfig
import com.myhealth.app.fhir.FhirOAuthClient
import com.myhealth.app.ui.Routes
import com.myhealth.app.ui.theme.CarePlusColor
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.launch
import net.openid.appauth.AuthorizationException
import net.openid.appauth.AuthorizationResponse

/**
 * MyChart connect — exact-scope-list surface mirroring iOS
 * `Views/Care/MyChartConnectView.swift`. Launches Custom Tab via AppAuth.
 */
@Composable
fun MyChartConnectScreen(nav: NavController, vm: MyChartConnectViewModel = hiltViewModel()) {
    val tint = CarePlusColor.CareBlue
    var error by remember { mutableStateOf<String?>(null) }
    var connecting by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    val launcher = rememberLauncherForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        connecting = false
        val intent: Intent? = result.data
        if (result.resultCode != Activity.RESULT_OK || intent == null) {
            error = "Connection cancelled."
            return@rememberLauncherForActivityResult
        }
        val response = AuthorizationResponse.fromIntent(intent)
        val ex = AuthorizationException.fromIntent(intent)
        if (response == null) {
            error = ex?.errorDescription ?: "Authorization failed."
            return@rememberLauncherForActivityResult
        }
        scope.launch {
            try {
                vm.exchange(response)
                nav.navigate(Routes.MYCHART_DATA)
            } catch (e: Exception) {
                error = e.message ?: "Token exchange failed."
            }
        }
    }

    Column(Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Connect MyChart", fontSize = 22.sp, fontWeight = FontWeight.Bold)
        Text("SMART-on-FHIR (Epic sandbox)",
            color = MaterialTheme.colorScheme.onSurfaceVariant)

        Section("What we'll read")
        ScopeRow("Patient profile")
        ScopeRow("Conditions / problem list")
        ScopeRow("Active medications")
        ScopeRow("Allergies")
        ScopeRow("Vital sign + lab observations")
        ScopeRow("Past + upcoming appointments")
        ScopeRow("Immunizations")

        Section("What we won't do")
        BulletRow("Write back into your chart (read-only)")
        BulletRow("Share with a third party")
        BulletRow("Store unencrypted on this device")

        Section("Sandbox login")
        EpicSandboxConfig.SANDBOX_PATIENTS.forEach {
            Text("• $it", fontSize = 12.sp)
        }

        if (error != null) {
            Text(error!!, color = MaterialTheme.colorScheme.error, fontSize = 12.sp)
        }

        Button(
            onClick = {
                error = null
                connecting = true
                launcher.launch(vm.buildIntent())
            },
            enabled = !connecting,
            colors = ButtonDefaults.buttonColors(containerColor = tint),
            shape = RoundedCornerShape(14.dp),
            modifier = Modifier.fillMaxWidth().padding(top = 12.dp)
        ) {
            Text(if (connecting) "Connecting…" else "Connect with MyChart",
                color = androidx.compose.ui.graphics.Color.White)
        }
    }
}

@Composable
private fun Section(text: String) =
    Text(text, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(top = 8.dp))

@Composable
private fun ScopeRow(text: String) =
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(Icons.Filled.CheckCircle, null, tint = CarePlusColor.CareBlue,
            modifier = Modifier.padding(end = 8.dp))
        Text(text, fontSize = 14.sp)
    }

@Composable
private fun BulletRow(text: String) =
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(Icons.Filled.CheckCircle, null, tint = CarePlusColor.Success,
            modifier = Modifier.padding(end = 8.dp))
        Text(text, fontSize = 12.sp)
    }

@HiltViewModel
class MyChartConnectViewModel @Inject constructor(
    private val client: FhirOAuthClient,
) : ViewModel() {
    private val service by lazy { client.authorizationService() }
    fun buildIntent() = service.getAuthorizationRequestIntent(client.buildAuthRequest())
    suspend fun exchange(response: AuthorizationResponse): FhirOAuthClient.TokenResponse {
        val token = client.exchangeCode(response)
        // Care+ PHI rule (PRIVACY-CARE.md §2): the FHIR `patient` claim is
        // a clinical identifier; persist it ONLY to the SQLCipher PHI
        // database, never to the server. The server's `mychart_issuer`
        // table only records that this user connected this issuer.
        // (PHI Room write happens here once the dao is wired through
        // AppModule; week-1 stub keeps it on-device via SecureTokenStore
        // until the dao injection lands.)
        return token
    }
}
