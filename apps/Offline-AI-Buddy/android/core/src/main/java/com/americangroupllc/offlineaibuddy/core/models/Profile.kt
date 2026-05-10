package com.americangroupllc.offlineaibuddy.core.models

import kotlinx.serialization.Serializable

@Serializable
data class Profile(
    val id: String,                 // UUID string
    val name: String,
    val kind: Kind,
    val pinHash: String? = null,
    val pinSalt: String? = null,
    val createdAtMillis: Long = System.currentTimeMillis(),
) {
    @Serializable
    enum class Kind { ADULT, KID_SAFE }
}
