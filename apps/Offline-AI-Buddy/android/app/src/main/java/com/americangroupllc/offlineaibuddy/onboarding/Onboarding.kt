package com.americangroupllc.offlineaibuddy.onboarding

import androidx.compose.foundation.layout.*
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun ConsentScreen(onContinue: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text("Welcome to Offline AI Buddy", fontWeight = FontWeight.Bold)
        Text("Before we start, three things to know:")
        Text("• On first launch, we download a ~1 GB language model over Wi-Fi.")
        Text("• It's a 1.5B-parameter model. It can't match cloud GPT-4 on hard tasks.")
        Text("• Generation may be slow on older phones.")
        Spacer(Modifier.weight(1f))
        Button(onClick = onContinue, modifier = Modifier.fillMaxWidth()) { Text("Continue") }
    }
}

@Composable
fun ProfileSetupScreen(onContinue: () -> Unit) {
    Column(modifier = Modifier.padding(24.dp)) {
        Text("Set up your profile")
        Spacer(Modifier.height(16.dp))
        Button(onClick = onContinue) { Text("Continue with default Adult profile") }
    }
}

@Composable
fun ModelDownloadScreen(onContinue: () -> Unit) {
    Column(modifier = Modifier.padding(24.dp)) {
        Text("Downloading the language model (~1 GB, Wi-Fi only)")
        Spacer(Modifier.height(16.dp))
        Button(onClick = onContinue) { Text("Skip (already downloaded)") }
    }
}

@Composable
fun PermissionsScreen(onContinue: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text("You're all set. We'll ask for microphone access only when you tap the voice button.")
        Spacer(Modifier.weight(1f))
        Button(onClick = onContinue, modifier = Modifier.fillMaxWidth()) { Text("Get started") }
    }
}

@Composable
fun OnboardingScreen() {
    // Legacy placeholder. The real flow is wired in RootNav as a
    // sequence of: consent → profile → model-download → permissions → home,
    // gated by the OnboardingPrefs.completed DataStore flag.
    Text("Onboarding")
}
