package com.myhealth.app.vision

import android.graphics.Bitmap
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * On-device prescription-bottle OCR. Mirrors iOS
 * `PrescriptionBottleOCR.swift`. Pre-fills the existing
 * AddMedicine flow with drug name, strength, dosage instructions,
 * prescriber, refills, and Rx number.
 */
@Singleton
class PrescriptionBottleOcr @Inject constructor() {
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    data class Result(
        val drugName: String? = null,
        val strength: String? = null,
        val instructions: String? = null,
        val prescriber: String? = null,
        val refillsRemaining: Int? = null,
        val rxNumber: String? = null,
        val rawText: String = "",
    )

    suspend fun read(bitmap: Bitmap, rotationDegrees: Int = 0): Result =
        suspendCancellableCoroutine { cont ->
            val image = InputImage.fromBitmap(bitmap, rotationDegrees)
            recognizer.process(image)
                .addOnSuccessListener { v -> cont.resume(extract(v.text)) }
                .addOnFailureListener { e -> cont.resumeWithException(e) }
        }

    fun extract(text: String): Result {
        val drug = text.lineSequence()
            .map { it.trim() }
            .firstOrNull { it.length > 3 && it.any(Char::isLetter) && it.none(Char::isDigit) }

        val strength = Regex("""\d+\s*(mg|mcg|g|ml)""", RegexOption.IGNORE_CASE)
            .find(text)?.value
        val refills = Regex("""(?i)refills?\s*[:\s]*(\d+)""")
            .find(text)?.groupValues?.get(1)?.toIntOrNull()
        val rx = Regex("""(?i)rx\s*[#:]?\s*(\d{6,12})""")
            .find(text)?.groupValues?.get(1)
        val instructions = text.lineSequence()
            .map { it.trim() }
            .firstOrNull {
                val low = it.lowercase()
                low.startsWith("take ") || low.startsWith("use ") ||
                low.startsWith("apply ") || low.startsWith("inject ") ||
                low.startsWith("instill ")
            }
        val prescriber = Regex("""(?i)(?:dr\.?\s+|prescriber\s+|rx by\s+)([A-Za-z .\-,]{2,40})""")
            .find(text)?.groupValues?.get(1)?.trim()

        return Result(
            drugName = drug, strength = strength, instructions = instructions,
            prescriber = prescriber, refillsRemaining = refills,
            rxNumber = rx, rawText = text
        )
    }
}
