package com.americangroupllc.offlineaibuddy.roast

import androidx.compose.runtime.Composable
import com.americangroupllc.offlineaibuddy.chat.ChatScreen
import com.americangroupllc.offlineaibuddy.core.models.ChatSession

@Composable
fun RoastScreen() = ChatScreen(kind = ChatSession.Kind.ROAST)
