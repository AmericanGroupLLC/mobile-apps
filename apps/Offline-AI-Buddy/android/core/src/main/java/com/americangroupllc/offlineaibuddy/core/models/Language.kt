package com.americangroupllc.offlineaibuddy.core.models

import kotlinx.serialization.Serializable

@Serializable
enum class Language(val displayName: String, val localeIdentifier: String) {
    EN("English", "en-US"),
    HI("हिन्दी", "hi-IN"),
    ZH("中文", "zh-CN"),
    FR("Français", "fr-FR"),
    ES("Español", "es-ES"),
}
