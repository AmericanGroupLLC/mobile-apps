package com.myhealth.app.ui.train

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.myhealth.app.ui.Routes
import com.myhealth.app.ui.home.DashboardTile

@Composable
fun TrainScreen(nav: NavController) {
    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Text("Train", fontSize = 28.sp, fontWeight = FontWeight.Bold)
        Text("Anatomy / Library / Programs / Custom", color = MaterialTheme.colorScheme.onSurfaceVariant)
        DashboardTile("Anatomy picker", "Tap a muscle, find exercises") {
            nav.navigate(Routes.ANATOMY)
        }
        DashboardTile("Exercise library", "30+ moves with form tips") {
            nav.navigate(Routes.ANATOMY)
        }
    }
}
