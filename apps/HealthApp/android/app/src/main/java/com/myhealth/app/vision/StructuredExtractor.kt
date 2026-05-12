package com.myhealth.app.vision

/**
 * Schema-aware structured-extraction interface. Mirrors iOS
 * `StructuredExtractor.swift` — keep the two in sync.
 *
 * Two implementations:
 *  - [RegexStructuredExtractor] — ships today, no model download.
 *  - On-device LLM (placeholder, swap-in later): Google AI Edge SDK
 *    (Gemini Nano on Pixel 8 Pro / S24+) or MediaPipe LLM Inference
 *    (Gemma 2B int8 on Pixel 6+, S23+). The model file is ~1.4 GB so
 *    bundle sizing is the gate, not the API.
 */
interface StructuredExtractor {
    suspend fun extract(text: String, schema: List<Field>): Map<String, String?>
}

data class Field(
    val name: String,
    val keywords: List<String>,
    val valuePattern: String,
)

class RegexStructuredExtractor : StructuredExtractor {
    override suspend fun extract(text: String, schema: List<Field>): Map<String, String?> {
        return schema.associate { f ->
            f.name to matchAfter(f.keywords, f.valuePattern, text)
        }
    }

    private fun matchAfter(keys: List<String>, pattern: String, text: String): String? {
        val regex = Regex(pattern, RegexOption.IGNORE_CASE)
        for (line in text.split("\n")) {
            val lower = line.lowercase()
            val key = keys.firstOrNull { lower.contains(it) } ?: continue
            val tail = line.substring(lower.indexOf(key) + key.length)
            return regex.find(tail)?.value
        }
        return null
    }
}

object StructuredExtractorRegistry {
    /** Override at app boot to swap to an LLM-backed implementation. */
    @Volatile var shared: StructuredExtractor = RegexStructuredExtractor()
}
