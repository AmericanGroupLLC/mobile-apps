package com.americangroupllc.offlineaibuddy.voice

import android.content.Context
import android.content.Intent
import android.os.Build
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import com.americangroupllc.offlineaibuddy.core.models.Language
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Locale-aware TTS wrapper. Mirrors `BuddyAICore.VoiceSynthesizer`.
 */
@Singleton
class AndroidVoiceSynthesizer @Inject constructor(ctx: Context) {

    private val tts: TextToSpeech = TextToSpeech(ctx) { /* status */ }
    var rate: Float = 1.0f

    fun speak(text: String, language: Language, premium: Boolean) {
        tts.language = Locale.forLanguageTag(language.localeIdentifier)
        tts.setSpeechRate(rate)
        // Premium voices: use the platform's "highest quality" voice for
        // the locale when available.
        if (premium) {
            tts.voices?.firstOrNull {
                it.locale == Locale.forLanguageTag(language.localeIdentifier) && it.quality >= 400
            }?.let { tts.voice = it }
        }
        tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "oab-tts")
    }

    fun stop() = tts.stop()
}

/**
 * Push-to-talk STT wrapper. Mirrors `BuddyAICore.VoiceRecognizer`.
 * Tries on-device recognition where the platform supports it
 * (Android 13+ via `EXTRA_PREFER_OFFLINE`).
 */
@Singleton
class AndroidVoiceRecognizer @Inject constructor(private val ctx: Context) {

    private var recognizer: SpeechRecognizer? = null
    private var onPartial: ((String) -> Unit)? = null
    private var onFinal: ((String) -> Unit)? = null

    fun start(language: Language, onPartial: (String) -> Unit, onFinal: (String) -> Unit) {
        this.onPartial = onPartial
        this.onFinal = onFinal
        recognizer = SpeechRecognizer.createSpeechRecognizer(ctx).apply {
            setRecognitionListener(makeListener())
        }
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, language.localeIdentifier)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            }
        }
        recognizer?.startListening(intent)
    }

    fun stop() {
        recognizer?.stopListening()
        recognizer?.destroy()
        recognizer = null
    }

    private fun makeListener() = object : RecognitionListener {
        override fun onReadyForSpeech(params: android.os.Bundle?) {}
        override fun onBeginningOfSpeech() {}
        override fun onRmsChanged(rmsdB: Float) {}
        override fun onBufferReceived(buffer: ByteArray?) {}
        override fun onEndOfSpeech() {}
        override fun onError(error: Int) { onFinal?.invoke("") }
        override fun onPartialResults(partialResults: android.os.Bundle?) {
            partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                ?.firstOrNull()?.let { onPartial?.invoke(it) }
        }
        override fun onResults(results: android.os.Bundle?) {
            val text = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull().orEmpty()
            onFinal?.invoke(text)
        }
        override fun onEvent(eventType: Int, params: android.os.Bundle?) {}
    }
}
