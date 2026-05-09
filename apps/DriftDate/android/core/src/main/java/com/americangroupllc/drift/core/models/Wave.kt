package com.americangroupllc.drift.core.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Wave(
    val id: String,
    @SerialName("from_profile_id") val fromProfileId: String,
    @SerialName("to_profile_id")   val toProfileId: String,
    val layer: Layer,
    val status: WaveStatus = WaveStatus.PENDING,
    @SerialName("created_at")  val createdAt: String,
    @SerialName("matched_at")  val matchedAt: String? = null,
)
