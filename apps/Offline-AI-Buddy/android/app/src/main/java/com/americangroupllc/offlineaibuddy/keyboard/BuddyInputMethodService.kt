package com.americangroupllc.offlineaibuddy.keyboard

import android.content.Context
import android.inputmethodservice.InputMethodService
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import com.americangroupllc.offlineaibuddy.llm.LlamaService
import com.americangroupllc.offlineaibuddy.core.models.ChatSession
import com.americangroupllc.offlineaibuddy.core.models.Language
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Custom system keyboard ("Buddy Keyboard"). Renders a thin candidate
 * strip with up to 3 AI suggestions for the current chat context.
 *
 * Inference runs through `LlamaService` injected by Hilt — the whole
 * thing lives in the same APK, so the IME and the main app share the
 * runner without IPC. (The exported ContentProvider is here for
 * defense-in-depth + future cross-process support.)
 */
@AndroidEntryPoint
class BuddyInputMethodService : InputMethodService() {

    @Inject lateinit var llama: LlamaService

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var pendingJob: Job? = null
    private var stripView: SuggestionStripView? = null

    override fun onCreateInputView(): View {
        val container = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        stripView = SuggestionStripView(this) { suggestion ->
            currentInputConnection?.commitText(suggestion, 1)
        }
        container.addView(stripView)
        // QWERTY rendering omitted in v1 scaffold — Android's default IME
        // candidate strip plus suggestions is the v1 surface.
        val openMain = Button(this).apply {
            text = "Open Offline AI Buddy"
            setOnClickListener {
                val intent = packageManager.getLaunchIntentForPackage(packageName)
                intent?.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        }
        container.addView(openMain)
        return container
    }

    override fun onUpdateSelection(
        oldSelStart: Int, oldSelEnd: Int,
        newSelStart: Int, newSelEnd: Int,
        candidatesStart: Int, candidatesEnd: Int,
    ) {
        super.onUpdateSelection(oldSelStart, oldSelEnd, newSelStart, newSelEnd, candidatesStart, candidatesEnd)
        val ctx = currentInputConnection?.getTextBeforeCursor(120, 0)?.toString().orEmpty()
        if (ctx.length < 5) return
        pendingJob?.cancel()
        pendingJob = scope.launch {
            kotlinx.coroutines.delay(250)   // typing pause debounce
            val suggestions = mutableListOf<String>()
            llama.generate(
                kind = ChatSession.Kind.CHAT,
                language = Language.EN,
                isKidSafe = false,
                history = emptyList(),
                userInput = "Suggest 3 short replies (one per line) for this chat context: \"$ctx\"."
            ).collect { chunk ->
                if (suggestions.isEmpty()) suggestions += ""
                suggestions[suggestions.size - 1] += chunk
                if (chunk.contains("\n")) suggestions += ""
            }
            stripView?.setSuggestions(
                suggestions.map { it.trim() }.filter { it.isNotEmpty() }.take(3)
            )
        }
    }
}

class SuggestionStripView(
    ctx: Context,
    private val onTap: (String) -> Unit,
) : LinearLayout(ctx) {
    private val buttons: List<Button>

    init {
        orientation = HORIZONTAL
        buttons = (0 until 3).map { idx ->
            Button(ctx).apply {
                text = ""
                setOnClickListener {
                    val s = text.toString()
                    if (s.isNotEmpty()) onTap(s)
                }
                addView(this)
            }
        }
    }

    fun setSuggestions(suggestions: List<String>) {
        for (i in buttons.indices) {
            buttons[i].text = suggestions.getOrNull(i).orEmpty()
            buttons[i].isEnabled = suggestions.getOrNull(i)?.isNotEmpty() == true
        }
    }
}
