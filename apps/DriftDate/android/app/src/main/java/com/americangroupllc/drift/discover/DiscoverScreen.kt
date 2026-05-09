package com.americangroupllc.drift.discover

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.americangroupllc.drift.core.models.Layer
import com.americangroupllc.drift.core.models.Profile

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DiscoverScreen() {
    var layer by remember { mutableStateOf(Layer.ZIP) }
    val candidates = remember { listOf<Profile>() }   // wired up in DiscoverViewModel

    Scaffold(topBar = { CenterAlignedTopAppBar(title = { Text("Discover") }) }) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
                .padding(horizontal = 16.dp)
        ) {
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                Layer.values().forEachIndexed { index, l ->
                    SegmentedButton(
                        selected = layer == l,
                        onClick = { layer = l },
                        shape = SegmentedButtonDefaults.itemShape(index, Layer.values().size),
                    ) { Text(l.name.lowercase().replaceFirstChar { it.uppercase() }) }
                }
            }
            Spacer(Modifier.height(12.dp))
            LazyColumn { items(candidates) { p -> ProfileCard(p, layer) } }
        }
    }
}

@Composable
fun ProfileCard(p: Profile, layer: Layer) {
    Card(
        Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp)
    ) {
        Column(Modifier.padding(12.dp)) {
            Text(p.displayName, style = MaterialTheme.typography.titleMedium)
            Text(p.intent.name.lowercase(), style = MaterialTheme.typography.bodySmall)
            Text("layer: ${layer.name.lowercase()}", style = MaterialTheme.typography.labelSmall)
            Spacer(Modifier.height(8.dp))
            Row {
                OutlinedButton(onClick = { /* pass */ }) { Text("Pass") }
                Spacer(Modifier.width(8.dp))
                Button(onClick = { /* wave */ }) { Text("Wave") }
            }
        }
    }
}
