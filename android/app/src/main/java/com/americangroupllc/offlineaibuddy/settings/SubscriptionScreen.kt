package com.americangroupllc.offlineaibuddy.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun SubscriptionScreen() {
    Column(modifier = Modifier.padding(16.dp)) {
        Text("Premium")
        Button(onClick = { /* RevenueCat purchase flow */ }) { Text("Subscribe — $4.99/mo") }
        Button(onClick = { /* RevenueCat purchase flow */ }) { Text("Lifetime — $19.99 one-time") }
        Button(onClick = { /* restorePurchases */ }) { Text("Restore purchases") }
    }
}
