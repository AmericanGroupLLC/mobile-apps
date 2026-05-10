package com.americangroupllc.offlineaibuddy.dailychallenge

import androidx.compose.runtime.Composable
import com.americangroupllc.offlineaibuddy.chat.ChatScreen
import com.americangroupllc.offlineaibuddy.core.models.ChatSession

@Composable
fun DailyChallengeScreen() = ChatScreen(kind = ChatSession.Kind.DAILY_CHALLENGE)
