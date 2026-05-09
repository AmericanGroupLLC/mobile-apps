package com.americangroupllc.offlineaibuddy.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.americangroupllc.offlineaibuddy.core.domain.ContentPolicy
import com.americangroupllc.offlineaibuddy.core.models.ChatMessage
import com.americangroupllc.offlineaibuddy.core.models.ChatSession
import com.americangroupllc.offlineaibuddy.core.models.Language
import com.americangroupllc.offlineaibuddy.llm.LlamaService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class ChatViewModel @Inject constructor(
    private val llama: LlamaService,
) : ViewModel() {
    val messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val streamingText = MutableStateFlow("")

    fun send(kind: ChatSession.Kind, language: Language, isKidSafe: Boolean, text: String) {
        val u = ChatMessage(id = UUID.randomUUID().toString(), role = ChatMessage.Role.USER, text = text)
        messages.value = messages.value + u

        viewModelScope.launch {
            val policy = ContentPolicy(language, isKidSafe)
            streamingText.value = ""
            llama.generate(kind, language, isKidSafe, messages.value, text).collect { chunk ->
                val next = streamingText.value + chunk
                val r = policy.filter(next)
                if (r.blocked) {
                    streamingText.value = r.filtered
                    return@collect
                }
                streamingText.value = next
            }
            val final = streamingText.value
            streamingText.value = ""
            if (final.isNotEmpty()) {
                messages.value = messages.value + ChatMessage(
                    id = UUID.randomUUID().toString(),
                    role = ChatMessage.Role.ASSISTANT,
                    text = final,
                )
            }
        }
    }
}
