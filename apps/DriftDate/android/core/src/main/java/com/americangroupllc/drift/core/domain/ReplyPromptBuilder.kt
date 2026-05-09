package com.americangroupllc.drift.core.domain

import com.americangroupllc.drift.core.models.Message
import com.americangroupllc.drift.core.models.Profile
import com.americangroupllc.drift.core.models.Tone

/**
 * Builds the system+user prompt sent to the `reply-suggest` Edge Function.
 * Pure logic — mirrored case-for-case with `ReplyPromptBuilder.swift` and
 * `prompt.ts`.
 */
object ReplyPromptBuilder {

    data class Inputs(
        val viewer: Profile,
        val target: Profile,
        val lastMessages: List<Message>,
        val tone: Tone,
    )

    data class Output(val system: String, val user: String)

    fun build(input: Inputs): Output {
        val toneClause = toneSpecificClause(input.tone)
        val system =
            "You write three short reply suggestions for a Drift dating app chat. " +
            "Return strict JSON: {\"casual\": ..., \"context\": ..., \"playful\": ...}. " +
            "Each suggestion is one sentence, ≤ 140 characters, no emoji unless playful, " +
            "and never asks for private location. $toneClause"

        val viewerVibes = if (input.viewer.vibeTags.isEmpty()) "—" else input.viewer.vibeTags.joinToString(", ")
        val targetVibes = if (input.target.vibeTags.isEmpty()) "—" else input.target.vibeTags.joinToString(", ")

        val tail = input.lastMessages.takeLast(5)
        val messagesSection = if (tail.isEmpty()) {
            "(no messages yet — these are opener suggestions)"
        } else {
            tail.joinToString("\n") { m ->
                val label = when (m.authorId) {
                    input.viewer.id -> "A"
                    input.target.id -> "B"
                    else -> "?"
                }
                "$label: ${m.text}"
            }
        }

        val user = """
            Person A: ${input.viewer.displayName} (intent: ${input.viewer.intent.serialName()}, vibes: $viewerVibes)
            Person B: ${input.target.displayName} (intent: ${input.target.intent.serialName()}, vibes: $targetVibes)

            Last messages (oldest → newest):
            $messagesSection
        """.trimIndent()

        return Output(system, user)
    }

    fun toneSpecificClause(tone: Tone): String = when (tone) {
        Tone.ENERGETIC    -> "The conversation has good energy — match it. Light playful escalation is welcome."
        Tone.DEEP         -> "The conversation is thoughtful and longer-form. Match the depth; ask one open follow-up."
        Tone.MEETUP_READY -> "Both parties seem meetup-ready. Suggest a public-place hangout (coffee, walk, public event) — never request a private location share."
        Tone.SLOW         -> "The conversation is slow. Keep suggestions light and easy to answer."
    }

    private fun com.americangroupllc.drift.core.models.Intent.serialName(): String = name.lowercase()
}
