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
 * On-device insurance card OCR. Mirrors the iOS
 * [shared/.../Intelligence/InsuranceCardOCR.swift] regex set:
 * payer (top non-numeric line), member ID, group #, BIN, PCN, RxGrp.
 *
 * Image and OCR text never leave the device. Parsed structured fields go
 * into the SQLCipher PHI database via `InsuranceCardEntity`; raw OCR text
 * goes into `SecureTokenStore.setInsuranceRawText`.
 */
@Singleton
class InsuranceCardOcr @Inject constructor() {
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    data class Result(
        val payer: String? = null,
        val memberId: String? = null,
        val groupNumber: String? = null,
        val bin: String? = null,
        val pcn: String? = null,
        val rxGrp: String? = null,
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
        val payer = text.lineSequence()
            .map { it.trim() }
            .firstOrNull { it.isNotEmpty() && it.length > 2 && it.none(Char::isDigit) }
        val memberId = matchAfter(
            keys = listOf("member id", "member #", "member no", "subscriber id",
                "subscriber #", "id #", "id:", "id no"),
            pattern = """[A-Z0-9\-]{6,20}""",
            text = text
        )
        val group = matchAfter(
            keys = listOf("group #", "group no", "group:", "group number"),
            pattern = """[A-Z0-9\-]{4,15}""",
            text = text
        )
        val bin = matchAfter(
            keys = listOf("bin #", "bin:", "rx bin"),
            pattern = """\d{6}""",
            text = text
        )
        val pcn = matchAfter(
            keys = listOf("pcn:", "pcn #", "rx pcn"),
            pattern = """[A-Z0-9]{2,15}""",
            text = text
        )
        val rxGrp = matchAfter(
            keys = listOf("rxgrp", "rx grp", "rx group"),
            pattern = """[A-Z0-9\-]{2,15}""",
            text = text
        )
        return Result(
            payer = payer, memberId = memberId, groupNumber = group,
            bin = bin, pcn = pcn, rxGrp = rxGrp, rawText = text
        )
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
