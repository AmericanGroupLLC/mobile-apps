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
 * On-device lab report OCR. Mirrors iOS `LabReportOCR.swift` — same
 * schema, so iOS + Android produce identical fields. Snap a printed
 * Quest / LabCorp / Kaiser report → A1C, fasting glucose, BP, lipid
 * panel, BMI, weight.
 */
@Singleton
class LabReportOcr @Inject constructor() {
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    data class Result(
        val a1c: Double? = null,
        val fastingGlucose: Double? = null,
        val bpSystolic: Int? = null,
        val bpDiastolic: Int? = null,
        val cholesterolTotal: Double? = null,
        val ldl: Double? = null,
        val hdl: Double? = null,
        val triglycerides: Double? = null,
        val bmi: Double? = null,
        val weightKg: Double? = null,
        val rawText: String = "",
    )

    suspend fun read(bitmap: Bitmap, rotationDegrees: Int = 0): Result =
        suspendCancellableCoroutine { cont ->
            val image = InputImage.fromBitmap(bitmap, rotationDegrees)
            recognizer.process(image)
                .addOnSuccessListener { v ->
                    cont.resume(extract(v.text))
                }
                .addOnFailureListener { e -> cont.resumeWithException(e) }
        }

    suspend fun extract(text: String): Result {
        val ext = StructuredExtractorRegistry.shared
        val map = ext.extract(text, SCHEMA)
        val (sys, dia) = parseBp(map["bp"])
        return Result(
            a1c = map["a1c"]?.toDoubleOrNull(),
            fastingGlucose = map["fastingGlucose"]?.toDoubleOrNull(),
            bpSystolic = sys,
            bpDiastolic = dia,
            cholesterolTotal = map["cholesterol"]?.toDoubleOrNull(),
            ldl = map["ldl"]?.toDoubleOrNull(),
            hdl = map["hdl"]?.toDoubleOrNull(),
            triglycerides = map["triglycerides"]?.toDoubleOrNull(),
            bmi = map["bmi"]?.toDoubleOrNull(),
            weightKg = map["weight"]?.toDoubleOrNull(),
            rawText = text,
        )
    }

    private fun parseBp(s: String?): Pair<Int?, Int?> {
        s ?: return null to null
        val parts = s.split("/")
        if (parts.size != 2) return null to null
        return parts[0].trim().toIntOrNull() to parts[1].trim().toIntOrNull()
    }

    companion object {
        val SCHEMA = listOf(
            Field("a1c", listOf("a1c", "hba1c", "hemoglobin a1c"), """\d+\.\d+"""),
            Field("fastingGlucose",
                listOf("fasting glucose", "fasting blood sugar", "fbg", "glucose"),
                """\d+(\.\d+)?"""),
            Field("bp", listOf("bp", "blood pressure"), """\d{2,3}\s*/\s*\d{2,3}"""),
            Field("cholesterol",
                listOf("total cholesterol", "cholesterol total", "tc:"),
                """\d+(\.\d+)?"""),
            Field("ldl", listOf("ldl"), """\d+(\.\d+)?"""),
            Field("hdl", listOf("hdl"), """\d+(\.\d+)?"""),
            Field("triglycerides", listOf("triglycerides", "tg:"), """\d+(\.\d+)?"""),
            Field("bmi", listOf("bmi"), """\d+(\.\d+)?"""),
            Field("weight", listOf("weight"), """\d+(\.\d+)?"""),
        )
    }
}
