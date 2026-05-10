package com.americangroupllc.drift.core.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Photo(
    val id: String,
    @SerialName("profile_id")  val profileId: String,
    @SerialName("storage_path") val storagePath: String,
    @SerialName("sort_order")  val sortOrder: Int,        // 1..6
    @SerialName("is_verification_selfie") val isVerificationSelfie: Boolean = false,
    @SerialName("created_at")  val createdAt: String,
)

@Serializable
data class Prompt(
    val slot: Int,                  // 1..3
    val key: String,                // e.g. "looking_for"
    val response: String,
)

@Serializable
data class Profile(
    val id: String,
    @SerialName("display_name") val displayName: String,
    val photos: List<Photo> = emptyList(),
    @SerialName("voice_prompt_url") val voicePromptUrl: String? = null,
    val intent: Intent,
    @SerialName("vibe_tags") val vibeTags: List<String> = emptyList(),
    val prompts: List<Prompt> = emptyList(),
    @SerialName("verified_at") val verifiedAt: String? = null,
    @SerialName("zip_prefix3") val zipPrefix3: String? = null,
    @SerialName("county_fips") val countyFips: String? = null,
    @SerialName("state_code")  val stateCode: String? = null,
    @SerialName("discoverable_layers") val discoverableLayers: Set<Layer> = Layer.values().toSet(),
    @SerialName("last_active_at") val lastActiveAt: Long,    // epoch millis (client-mapped)
    @SerialName("created_at")     val createdAt: Long,
) {
    val isVerified: Boolean get() = verifiedAt != null
}
