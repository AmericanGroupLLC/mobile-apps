package com.americangroupllc.cardwear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import com.americangroupllc.cardwear.feed.FeedScreen
import com.americangroupllc.cardwear.composer.ComposerScreen

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                CardWearApp()
            }
        }
    }
}

@androidx.compose.runtime.Composable
private fun CardWearApp() {
    var showComposer by remember { mutableStateOf(false) }
    Scaffold(modifier = Modifier.fillMaxSize().padding(8.dp)) {
        if (showComposer) {
            ComposerScreen(onDone = { showComposer = false })
        } else {
            FeedScreen(onCapture = { showComposer = true })
        }
    }
}
