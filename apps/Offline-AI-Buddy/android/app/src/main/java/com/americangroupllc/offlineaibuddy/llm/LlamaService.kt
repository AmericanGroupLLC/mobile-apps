package com.americangroupllc.offlineaibuddy.llm

import com.americangroupllc.offlineaibuddy.core.models.ChatMessage
import com.americangroupllc.offlineaibuddy.core.models.ChatSession
import com.americangroupllc.offlineaibuddy.core.models.Language
import com.americangroupllc.offlineaibuddy.core.models.ModelManifest
import com.americangroupllc.offlineaibuddy.core.domain.PromptTemplates
import com.americangroupllc.offlineaibuddy.core.domain.TranslateOrchestrator
import com.americangroupllc.offlineaibuddy.core.storage.ModelStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.delay
import javax.inject.Inject
import javax.inject.Singleton

/**
 * App-side wrapper around [LlamaJni]. Mirrors the iOS `LlamaService`
 * API. v1 falls back to a canned echo stream when the JNI library
 * isn't loaded (CI / fork builds without llama.cpp submodule).
 */
@Singleton
class LlamaService @Inject constructor(
    private val store: ModelStore,
    private val manifest: ModelManifest,
) {
    private val jni = LlamaJni()
    @Volatile var modelLoaded: Boolean = false; private set

    suspend fun warmupIfModelPresent(): Boolean {
        val file = store.urlFor("${manifest.name}.gguf")
        if (!file.exists()) return false
        modelLoaded = jni.load(file.absolutePath, manifest.contextSize)
        return modelLoaded
    }

    fun generate(
        kind: ChatSession.Kind,
        language: Language,
        isKidSafe: Boolean,
        history: List<ChatMessage>,
        userInput: String,
        translateSrc: Language? = null,
        translateDst: Language? = null,
    ): Flow<String> = flow {
        val prompt = if (kind == ChatSession.Kind.TRANSLATE && translateSrc != null && translateDst != null) {
            TranslateOrchestrator.prompt(translateSrc, translateDst, userInput)
        } else {
            val base = PromptTemplates.prompt(kind, language, isKidSafe)
            val user = base.render(
                mapOf(
                    "user" to userInput,
                    "date" to java.time.LocalDate.now().toString(),
                    "audience" to "general",
                )
            )
            PromptTemplates.Prompt(base.system, user)
        }
        if (jni.isLoaded) {
            val out = jni.generate(prompt.system, prompt.userTemplate, maxTokens = 512)
            for (chunk in out.chunked(8)) {
                emit(chunk)
                delay(10)
            }
        } else {
            // Stub fallback so the UI still streams in CI.
            val pieces = listOf("(stub) ", "you said: ", userInput)
            for (p in pieces) {
                emit(p)
                delay(10)
            }
        }
    }.flowOn(Dispatchers.Default)
}
