package com.americangroupllc.clockapp

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Alarm
import androidx.compose.material.icons.filled.HourglassBottom
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector

private enum class Tab(val title: String, val icon: ImageVector) {
    Clock("Clock", Icons.Filled.AccessTime),
    Alarm("Alarm", Icons.Filled.Alarm),
    Stopwatch("Stopwatch", Icons.Filled.Timer),
    Timer("Timer", Icons.Filled.HourglassBottom),
}

@Composable
fun ClockTabs() {
    var selected by remember { mutableStateOf(Tab.Clock) }
    Scaffold(
        bottomBar = {
            NavigationBar {
                Tab.entries.forEach { tab ->
                    NavigationBarItem(
                        selected = selected == tab,
                        onClick = { selected = tab },
                        icon = { Icon(tab.icon, contentDescription = tab.title) },
                        label = { Text(tab.title) },
                    )
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding).fillMaxSize()) {
            when (selected) {
                Tab.Clock -> ClockScreen()
                Tab.Alarm -> AlarmScreen()
                Tab.Stopwatch -> StopwatchScreen()
                Tab.Timer -> TimerScreen()
            }
        }
    }
}
