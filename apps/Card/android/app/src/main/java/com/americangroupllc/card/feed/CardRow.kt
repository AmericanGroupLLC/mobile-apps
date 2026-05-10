package com.americangroupllc.card.feed

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.RadioButtonUnchecked
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.americangroupllc.card.core.models.Card
import com.americangroupllc.card.core.models.CardKind

@Composable
fun CardRow(
    card: Card,
    onTap: () -> Unit,
    onToggleComplete: () -> Unit,
) {
    Row(
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier
            .clickable { onTap() }
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        if (card.kind == CardKind.TASK) {
            IconButton(onClick = onToggleComplete) {
                if (card.isCompleted) {
                    Icon(Icons.Outlined.CheckCircle, contentDescription = "Mark not done", tint = Color(0xFF2E8B57))
                } else {
                    Icon(Icons.Outlined.RadioButtonUnchecked, contentDescription = "Mark done")
                }
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = card.text,
                color = if (card.isCompleted) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface,
                textDecoration = if (card.isCompleted) TextDecoration.LineThrough else TextDecoration.None,
            )
            Text(
                text = card.kind.name.lowercase(),
                fontSize = 10.sp,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier
                    .background(MaterialTheme.colorScheme.primaryContainer, RoundedCornerShape(8.dp))
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            )
        }
    }
}
