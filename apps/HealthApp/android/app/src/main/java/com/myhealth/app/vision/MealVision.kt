package com.myhealth.app.vision

import android.graphics.Bitmap
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.label.ImageLabel
import com.google.mlkit.vision.label.ImageLabeling
import com.google.mlkit.vision.label.defaults.ImageLabelerOptions
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * On-device meal-photo classifier. Returns a list of label / confidence pairs
 * that the UI can pass to the existing food-search backend (Open Food Facts /
 * USDA FDC) to look up macros. Never sends pixels to the network.
 */
@Singleton
class MealClassifier @Inject constructor() {
    private val labeler = ImageLabeling.getClient(
        ImageLabelerOptions.Builder().setConfidenceThreshold(0.5f).build()
    )

    data class Hit(val label: String, val confidence: Float)

    suspend fun classify(bitmap: Bitmap, rotationDegrees: Int = 0): List<Hit> =
        suspendCancellableCoroutine { cont ->
            val image = InputImage.fromBitmap(bitmap, rotationDegrees)
            labeler.process(image)
                .addOnSuccessListener { labels: List<ImageLabel> ->
                    cont.resume(labels.map { Hit(it.text, it.confidence) })
                }
                .addOnFailureListener { e -> cont.resumeWithException(e) }
        }
}

/**
 * On-device nutrition-label OCR. Pulls the same kcal / fat / carbs / protein
 * regex matches as the iOS implementation.
 */
@Singleton
class NutritionLabelOcr @Inject constructor() {
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    data class Result(
        val kcal: Double? = null,
        val fatG: Double? = null,
        val carbsG: Double? = null,
        val proteinG: Double? = null,
        val detectedBarcode: String? = null,
    )

    suspend fun read(bitmap: Bitmap, rotationDegrees: Int = 0): Result =
        suspendCancellableCoroutine { cont ->
            val image = InputImage.fromBitmap(bitmap, rotationDegrees)
            recognizer.process(image)
                .addOnSuccessListener { visionText ->
                    cont.resume(extract(visionText.text))
                }
                .addOnFailureListener { e -> cont.resumeWithException(e) }
        }

    fun extract(text: String): Result {
        val kcal = Regex("""(?i)calorie[s]?\s*[:\s]*([\d,.]+)""")
            .find(text)?.groupValues?.get(1)?.toDoubleOrNull()
        val fat = Regex("""(?i)total fat\s*[:\s]*([\d,.]+)""")
            .find(text)?.groupValues?.get(1)?.replace(",", ".")?.toDoubleOrNull()
        val carbs = Regex("""(?i)total carbohydrate[s]?\s*[:\s]*([\d,.]+)""")
            .find(text)?.groupValues?.get(1)?.replace(",", ".")?.toDoubleOrNull()
        val protein = Regex("""(?i)protein\s*[:\s]*([\d,.]+)""")
            .find(text)?.groupValues?.get(1)?.replace(",", ".")?.toDoubleOrNull()
        val barcode = Regex("""\b(\d{12,13})\b""").find(text)?.groupValues?.get(1)
        return Result(kcal, fat, carbs, protein, barcode)
    }
}
