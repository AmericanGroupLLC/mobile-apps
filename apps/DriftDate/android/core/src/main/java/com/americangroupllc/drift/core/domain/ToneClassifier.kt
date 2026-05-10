package com.americangroupllc.drift.core.domain

import com.americangroupllc.drift.core.models.Message
import com.americangroupllc.drift.core.models.Tone

/**
 * Pure function: classify the conversation's tone from a sliding window of
 * recent messages. Heuristics mirrored case-for-case with `ToneClassifier.swift`.
 */
object ToneClassifier {

    private val MEETUP_PATTERNS = listOf(
        "want to grab", "grab a coffee", "grab coffee", "grab dinner",
        "meet up", "meet for", "coffee?", "drinks this", "lunch sometime",
        "let's do", "what about saturday", "what about sunday",
    )

    fun classify(messages: List<Message>, nowMillis: Long = System.currentTimeMillis()): Tone {
        if (messages.isEmpty()) return Tone.SLOW

        val sorted = messages.sortedBy { it.createdAt }
        val recent = sorted.takeLast(10)

        if (recent.size >= 2) {
            val gap = recent.last().createdAt - recent[recent.size - 2].createdAt
            if (gap >= 4 * 60 * 60 * 1000L) return Tone.SLOW
        }

        for (m in recent) {
            val lower = m.text.lowercase()
            if (MEETUP_PATTERNS.any { lower.contains(it) }) return Tone.MEETUP_READY
        }

        val avgLen = recent.sumOf { it.text.length }.toDouble() / recent.size
        if (avgLen > 200) return Tone.DEEP

        if (recent.size >= 10) {
            val span = recent.last().createdAt - recent.first().createdAt
            if (span <= 5 * 60 * 1000L) return Tone.ENERGETIC
        }

        return Tone.SLOW
    }
}
