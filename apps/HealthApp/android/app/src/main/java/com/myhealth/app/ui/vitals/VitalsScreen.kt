package com.myhealth.app.ui.vitals

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.myhealth.app.ui.Routes
import com.myhealth.app.ui.home.DashboardTile

@Composable
fun VitalsScreen(nav: NavController, vm: VitalsViewModel = hiltViewModel()) {
    val s by vm.snapshot.collectAsStateWithLifecycle()
    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Vitals", fontSize = 28.sp, fontWeight = FontWeight.Bold)

        DashboardTile("Biological Age", "Tap to see your bio age vs real age") {
            nav.navigate(Routes.BIO_AGE)
        }

        Section("Cardiovascular") {
            VitalCell("Resting HR", s.restingHR?.let { "${it.toInt()} bpm" } ?: "—")
            VitalCell("VO₂ Max", s.vo2Max?.let { "%.1f".format(it) } ?: "—")
        }
        Section("Activity") {
            VitalCell("Steps today", s.stepsToday.toString())
        }
        Section("Body") {
            VitalCell("Weight", s.weightKg?.let { "%.1f kg".format(it) } ?: "—")
        }
        Section("Sleep") {
            VitalCell("Last night", s.lastNightSleepHrs?.let { "%.1f h".format(it) } ?: "—")
        }
        Text(
            "Hydration sensors don't exist yet. BP / glucose require manual entry or a paired meter.",
            fontSize = 11.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(top = 8.dp)
        )
    }
}

@Composable
private fun Section(title: String, content: @Composable () -> Unit) {
    Column {
        Text(title, color = MaterialTheme.colorScheme.primary,
            fontWeight = FontWeight.SemiBold, fontSize = 14.sp,
            modifier = Modifier.padding(top = 6.dp))
        content()
    }
}

@Composable
private fun VitalCell(label: String, value: String) {
    Card(shape = RoundedCornerShape(12.dp), modifier = Modifier.fillMaxWidth()) {
        Row(
            Modifier.padding(12.dp).fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(label, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(value, fontWeight = FontWeight.Bold)
        }
    }
}
