package com.americangroupllc.offlineaibuddy.gamecoach

import androidx.compose.runtime.Composable
import com.americangroupllc.offlineaibuddy.chat.ChatScreen
import com.americangroupllc.offlineaibuddy.core.models.ChatSession

@Composable
fun GameCoachScreen() = ChatScreen(kind = ChatSession.Kind.GAME_COACH)
