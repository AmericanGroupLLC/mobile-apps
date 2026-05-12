package com.myhealth.app.ui.shell

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.myhealth.app.ui.theme.CareTab

/**
 * Global header rendered above every primary tab. Tappable avatar (Profile)
 * on the left, tappable bell (News drawer) on the right, tab title in the
 * middle. Tinted to the active tab's accent.
 */
@Composable
fun AppHeader(
    tab: CareTab,
    onProfile: () -> Unit,
    onBell: () -> Unit,
    hasUnread: Boolean = true,
) {
    Row(
        Modifier.fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f))
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            Modifier.size(36.dp).background(tab.accent.copy(alpha = 0.18f), CircleShape)
                .clickable(onClick = onProfile),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Filled.AccountCircle, contentDescription = "Profile",
                tint = tab.accent, modifier = Modifier.size(28.dp))
        }
        Column(Modifier.padding(start = 12.dp).weight(1f)) {
            Text(tab.label, fontWeight = FontWeight.SemiBold, fontSize = 17.sp)
            Text("Care+",
                color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 11.sp)
        }
        Box(
            Modifier.size(36.dp)
                .background(MaterialTheme.colorScheme.surface, CircleShape)
                .clickable(onClick = onBell),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Filled.Notifications, contentDescription = "News drawer",
                modifier = Modifier.size(20.dp))
            if (hasUnread) {
                Box(
                    Modifier.size(8.dp)
                        .align(Alignment.TopEnd)
                        .padding(end = 4.dp, top = 4.dp)
                        .background(MaterialTheme.colorScheme.error, CircleShape)
                )
            }
        }
    }
}
