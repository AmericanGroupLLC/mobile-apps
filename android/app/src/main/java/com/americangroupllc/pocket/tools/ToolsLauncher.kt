package com.americangroupllc.pocket.tools

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp

private data class ToolCard(val title: String, val route: String, val icon: ImageVector, val tint: Color)

private val cards = listOf(
    ToolCard("Clock",      "clock",      Icons.Filled.AccessTime,    Color(0xFFFB8C00)),
    ToolCard("Calculator", "calculator", Icons.Filled.Calculate,     Color(0xFF5C6BC0)),
    ToolCard("Measure",    "measure",    Icons.Filled.Straighten,    Color(0xFF43A047)),
    ToolCard("Compass",    "compass",    Icons.Filled.Explore,       Color(0xFFE53935)),
    ToolCard("Level",      "level",      Icons.Filled.Architecture,  Color(0xFF1E88E5)),
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ToolsLauncher(onOpen: (String) -> Unit) {
    Scaffold(topBar = { TopAppBar(title = { Text("Pocket") }) }) { padding ->
        LazyVerticalGrid(
            columns = GridCells.Adaptive(minSize = 150.dp),
            modifier = Modifier.padding(padding).fillMaxSize().padding(12.dp)
        ) {
            items(cards) { card ->
                Card(
                    modifier = Modifier
                        .padding(8.dp)
                        .height(120.dp)
                        .fillMaxWidth()
                        .clickable { onOpen(card.route) },
                    shape = RoundedCornerShape(18.dp)
                ) {
                    Column(
                        modifier = Modifier.fillMaxSize().padding(12.dp),
                        verticalArrangement = Arrangement.Center,
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(card.icon, contentDescription = card.title, tint = card.tint)
                        Spacer(Modifier.height(8.dp))
                        Text(card.title, style = MaterialTheme.typography.titleMedium)
                    }
                }
            }
        }
    }
}
