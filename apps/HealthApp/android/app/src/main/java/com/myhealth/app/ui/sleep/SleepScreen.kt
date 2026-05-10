package com.myhealth.app.ui.sleep

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun SleepScreen() {
    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Text("Sleep", fontSize = 28.sp, fontWeight = FontWeight.Bold)
        Text("Last night + recovery (Health Connect)")
    }
}
