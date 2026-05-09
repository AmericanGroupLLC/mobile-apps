package com.americangroupllc.offlineaibuddy.partyquestions

import androidx.compose.runtime.Composable
import com.americangroupllc.offlineaibuddy.chat.ChatScreen
import com.americangroupllc.offlineaibuddy.core.models.ChatSession

@Composable
fun PartyQuestionsScreen() = ChatScreen(kind = ChatSession.Kind.PARTY_QUESTIONS)
