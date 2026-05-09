package com.myhealth.app.ui.profile

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

@Composable
fun ProfileScreen() {
    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Text("Profile", fontSize = 28.sp, fontWeight = FontWeight.Bold)
        Text("Edit name, birth date, sex, body, goal, language, units.",
            color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text("(Form fields wired to ProfileEntity in Room — extend as needed.)",
            color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 11.sp)
    }
}
