package com.americangroupllc.drift.core.domain

import com.americangroupllc.drift.core.models.Intent
import com.americangroupllc.drift.core.models.Layer
import com.americangroupllc.drift.core.models.Profile
import kotlin.math.abs

/**
 * Pure-logic 0..1 scoring, mirrored case-for-case with `LayerScorer.swift`.
 *
 * Weights: intent 30%, layer 20%, shared 15%, verification 15%, recency 10%,
 * conversation likelihood 10%. Tied scores break by `lastActiveAt` recency.
 */
object LayerScorer {

    fun score(viewer: Profile, target: Profile, layer: Layer, nowMillis: Long = System.currentTimeMillis()): Double {
        val intent  = intentScore(viewer.intent, target.intent)
        val layerR  = layerRelevance(viewer, target, layer)
        val shared  = sharedInterests(viewer.vibeTags, target.vibeTags)
        val verif   = verificationScore(target)
        val recency = recentActivityScore(target.lastActiveAt, nowMillis)
        val convo   = conversationLikelihood(target)
        return (intent  * 0.30
              + layerR  * 0.20
              + shared  * 0.15
              + verif   * 0.15
              + recency * 0.10
              + convo   * 0.10)
    }

    fun intentScore(a: Intent, b: Intent): Double = when {
        a == b                                        -> 1.0
        a == Intent.OPEN || b == Intent.OPEN          -> 0.7
        (a == Intent.DATING && b == Intent.SERIOUS)
        || (a == Intent.SERIOUS && b == Intent.DATING) -> 0.6
        a == Intent.FRIENDSHIP || b == Intent.FRIENDSHIP -> 0.3
        else                                           -> 0.4
    }

    fun layerRelevance(viewer: Profile, target: Profile, layer: Layer): Double = when (layer) {
        Layer.ZIP    -> if (viewer.zipPrefix3 != null && viewer.zipPrefix3 == target.zipPrefix3) 1.0 else 0.0
        Layer.COUNTY -> if (viewer.countyFips != null && viewer.countyFips == target.countyFips) 0.85 else 0.0
        Layer.STATE  -> if (viewer.stateCode  != null && viewer.stateCode  == target.stateCode)  0.65 else 0.0
        Layer.SERVER -> 0.4
    }

    fun sharedInterests(a: List<String>, b: List<String>): Double {
        if (a.isEmpty() || b.isEmpty()) return 0.0
        val aset = a.map { it.lowercase() }.toSet()
        val bset = b.map { it.lowercase() }.toSet()
        val inter = aset.intersect(bset).size
        val union = (aset + bset).size
        return if (union == 0) 0.0 else inter.toDouble() / union.toDouble()
    }

    fun verificationScore(target: Profile): Double = if (target.isVerified) 1.0 else 0.2

    fun recentActivityScore(lastActiveMillis: Long, nowMillis: Long): Double {
        val hours = ((nowMillis - lastActiveMillis).coerceAtLeast(0L)) / 3_600_000.0
        return when {
            hours < 24       -> 1.0
            hours < 24 * 3   -> 0.75
            hours < 24 * 7   -> 0.5
            hours < 24 * 30  -> 0.25
            else             -> 0.05
        }
    }

    fun conversationLikelihood(target: Profile): Double {
        val promptScore = (target.prompts.size.coerceAtMost(3)) / 3.0
        val voiceScore  = if (target.voicePromptUrl != null) 1.0 else 0.0
        return (promptScore * 0.7) + (voiceScore * 0.3)
    }

    fun sorted(candidates: List<Profile>, viewer: Profile, layer: Layer, nowMillis: Long = System.currentTimeMillis()): List<Profile> =
        candidates.sortedWith { lhs, rhs ->
            val ls = score(viewer, lhs, layer, nowMillis)
            val rs = score(viewer, rhs, layer, nowMillis)
            if (abs(ls - rs) > 0.0001) {
                rs.compareTo(ls)            // descending
            } else {
                rhs.lastActiveAt.compareTo(lhs.lastActiveAt)
            }
        }
}
