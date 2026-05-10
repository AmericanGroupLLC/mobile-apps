package com.americangroupllc.offlineaibuddy

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import com.americangroupllc.offlineaibuddy.ui.RootNav
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { OfflineAIBuddyApp() }
    }
}

@Composable
private fun OfflineAIBuddyApp() {
    MaterialTheme {
        Surface(color = MaterialTheme.colorScheme.background) {
            RootNav()
        }
    }
}
