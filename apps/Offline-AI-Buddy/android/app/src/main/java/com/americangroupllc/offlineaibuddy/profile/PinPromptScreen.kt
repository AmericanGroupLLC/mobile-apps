package com.americangroupllc.offlineaibuddy.profile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.americangroupllc.offlineaibuddy.core.models.Profile

@Composable
fun PinPromptScreen(profile: Profile, onSubmit: (String) -> Unit) {
    var pin by remember { mutableStateOf("") }
    Column(
        modifier = Modifier.fillMaxWidth().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("Enter PIN for ${profile.name}")
        OutlinedTextField(
            value = pin,
            onValueChange = { if (it.length <= 4) pin = it.filter(Char::isDigit) },
            label = { Text("4-digit PIN") },
            singleLine = true,
        )
        Button(onClick = { onSubmit(pin) }, enabled = pin.length == 4) {
            Text("Unlock")
        }
    }
}
