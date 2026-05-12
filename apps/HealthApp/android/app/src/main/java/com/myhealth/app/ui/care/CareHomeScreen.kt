package com.myhealth.app.ui.care

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.Medication
import androidx.compose.material.icons.filled.MedicalServices
import androidx.compose.material.icons.filled.Newspaper
import androidx.compose.material.icons.filled.Thermostat
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.myhealth.app.ui.Routes
import com.myhealth.app.ui.shell.AppHeader
import com.myhealth.app.ui.theme.CarePlusColor
import com.myhealth.app.ui.theme.CareTab

/**
 * Care tab home — top of the four-tab Care+ shell. Mirrors iOS
 * `Views/Care/CareHomeView.swift`.
 */
@Composable
fun CareHomeScreen(nav: NavController) {
    val tint = CarePlusColor.CareBlue
    var myChartConnected by remember { mutableStateOf(false) }
    var insuranceUploaded by remember { mutableStateOf(false) }

    Column(Modifier.fillMaxSize()) {
        AppHeader(
            tab = CareTab.Care,
            onProfile = { nav.navigate(Routes.PROFILE) },
            onBell = { nav.navigate(Routes.NEWS_DRAWER) },
        )
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // CTA tiles
            item {
                CtaTile(
                    icon = Icons.Filled.MedicalServices,
                    title = if (myChartConnected) "MyChart connected" else "Connect MyChart",
                    subtitle = if (myChartConnected) "Tap to view your records."
                               else "Read-only access via SMART-on-FHIR.",
                    cta = if (myChartConnected) null else "Connect",
                    tint = tint
                ) { nav.navigate(Routes.MYCHART_CONNECT) }
            }
            item {
                CtaTile(
                    icon = Icons.Filled.CreditCard,
                    title = if (insuranceUploaded) "Insurance card on file" else "Add insurance card",
                    subtitle = if (insuranceUploaded) "Tap to update." else "Snap a photo — OCR runs on-device.",
                    cta = if (insuranceUploaded) null else "Add",
                    tint = tint
                ) { nav.navigate(Routes.INSURANCE_CARD) }
            }

            // ── New: snap a printed lab report ───────────────────
            item {
                CtaTile(
                    icon = Icons.Filled.Newspaper,
                    title = "Snap lab report",
                    subtitle = "On-device OCR pulls A1C, BP, lipids.",
                    cta = "Snap",
                    tint = tint
                ) { nav.navigate(Routes.LAB_REPORT) }
            }

            // ── Care plan (per-condition) ────────────────────────
            item { SectionHeader("Care plan") }
            items(listOf("hypertension", "diabetest2", "stress")) { c ->
                val recipe = com.myhealth.app.ui.care.CarePlanRecipe.recipe(c)
                val reading = com.myhealth.app.ui.care.CarePlanRecipe.readingFor(c)
                com.myhealth.app.ui.care.CarePlanCard(
                    title = recipe.title,
                    goal = recipe.goal,
                    interventions = recipe.interventions,
                    reading = reading?.first,
                    readingHealthy = reading?.second ?: true,
                )
            }

            // Quick links
            item { SectionHeader("Find help") }
            item {
                Tile(Icons.Filled.LocalHospital, "Doctors",
                    "Search by ZIP and specialty. Save favorites.", tint) {
                    nav.navigate(Routes.DOCTOR_FINDER)
                }
            }
            item {
                Tile(Icons.Filled.Newspaper, "Annual reports",
                    "Yearly summary you can share with your doctor.", tint) {
                    nav.navigate(Routes.ANNUAL_REPORTS)
                }
            }
            item {
                Tile(Icons.Filled.Thermostat, "Symptoms log",
                    "Track how you feel day-to-day.", tint) {
                    nav.navigate(Routes.SYMPTOMS_LOG)
                }
            }

            item { SectionHeader("Care plan") }
            item {
                Tile(Icons.Filled.Medication, "Medicines",
                    "Reminders + adherence.", tint) { nav.navigate(Routes.MEDICINE) }
            }
        }
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(text, fontSize = 16.sp, fontWeight = FontWeight.SemiBold,
        modifier = Modifier.padding(top = 8.dp, bottom = 4.dp))
}

@Composable
private fun CtaTile(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String, subtitle: String, cta: String?,
    tint: androidx.compose.ui.graphics.Color, onClick: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        colors = CardDefaults.cardColors(MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(40.dp).background(tint.copy(alpha = 0.18f), RoundedCornerShape(10.dp)),
                contentAlignment = Alignment.Center
            ) { Icon(icon, null, tint = tint, modifier = Modifier.size(22.dp)) }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.Bold)
                Text(subtitle, fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            if (cta != null) {
                Box(
                    Modifier.background(tint, RoundedCornerShape(999.dp))
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) { Text(cta, color = androidx.compose.ui.graphics.Color.White,
                    fontWeight = FontWeight.SemiBold, fontSize = 12.sp) }
            } else {
                Icon(Icons.Filled.ChevronRight, null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun Tile(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String, subtitle: String,
    tint: androidx.compose.ui.graphics.Color, onClick: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        colors = CardDefaults.cardColors(MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(36.dp).background(tint.copy(alpha = 0.12f), RoundedCornerShape(9.dp)),
                contentAlignment = Alignment.Center
            ) { Icon(icon, null, tint = tint, modifier = Modifier.size(20.dp)) }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.Bold)
                Text(subtitle, fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Icon(Icons.Filled.ChevronRight, null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
