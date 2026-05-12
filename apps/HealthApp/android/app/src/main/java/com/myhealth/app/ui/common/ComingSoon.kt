package com.myhealth.app.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Placeholder destination for screens that exist in the Care+ spec but
 * aren't yet implemented. Mirrors iOS [ComingSoon] visually — friendly
 * tinted icon, title, "Coming soon" pill, optional ETA week.
 */
@Composable
fun ComingSoon(
    title: String,
    icon: ImageVector = Icons.Filled.AutoAwesome,
    tint: Color = MaterialTheme.colorScheme.primary,
    etaWeek: Int? = null,
) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            Modifier.size(110.dp).background(tint.copy(alpha = 0.15f), CircleShape),
            contentAlignment = Alignment.Center
        ) { Icon(icon, null, tint = tint, modifier = Modifier.size(44.dp)) }

        Text(title, fontSize = 22.sp, fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(top = 16.dp))

        Box(
            Modifier
                .padding(top = 6.dp)
                .background(tint.copy(alpha = 0.18f), RoundedCornerShape(999.dp))
                .padding(horizontal = 10.dp, vertical = 4.dp)
        ) { Text("Coming soon", color = tint, fontWeight = FontWeight.SemiBold, fontSize = 12.sp) }

        Text(
            text = etaWeek
                ?.let { "Planned for week $it of the Care+ MVP build." }
                ?: "This screen is part of the Care+ rollout. The plumbing is in place — final UI lands in a future drop.",
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 12.dp, start = 24.dp, end = 24.dp)
        )
    }
}

/** Convenience for screens that don't bother passing an icon. */
@Composable
fun ComingSoon(title: String) = ComingSoon(title, etaWeek = null)
