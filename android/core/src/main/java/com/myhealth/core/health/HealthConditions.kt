package com.myhealth.core.health

import kotlinx.serialization.Serializable

/**
 * Mirror of iOS `HealthCondition`. Same string raw values so the JSON portability
 * schema (myhealth.schema.json) round-trips cleanly between platforms.
 */
@Serializable
enum class HealthCondition(val label: String, val symbol: String) {
    none("No declared conditions", "✓"),
    hypertension("High blood pressure", "❤"),
    lowBloodPressure("Low blood pressure", "❤"),
    heartCondition("Heart condition", "❤"),
    diabetesT1("Type 1 diabetes", "💧"),
    diabetesT2("Type 2 diabetes", "💧"),
    asthma("Asthma", "🫁"),
    pregnancy("Pregnancy", "🤰"),
    kneeInjury("Knee injury / pain", "🦵"),
    backPain("Lower back pain", "🚶"),
    shoulderInjury("Shoulder injury / pain", "💪"),
    ankleInjury("Ankle injury / pain", "🦶"),
    osteoporosis("Osteoporosis", "🦴"),
    obesity("Obesity (BMI ≥ 30)", "⚖"),
    kidneyIssue("Kidney issue (CKD)", "🩺"),
    liverIssue("Liver issue", "🩺"),
    anemia("Anemia", "💧");
}

/**
 * Curated medical-safety map for exercise IDs. Mirrors iOS `ExerciseMedia.cautions`
 * and `.benefits`. Shared at the data level so both platforms produce the same
 * "Recommended for you" results from the same input conditions.
 */
object ExerciseMedicalMap {

    val cautions: Map<String, Set<HealthCondition>> = mapOf(
        "back-squat"        to setOf(HealthCondition.hypertension, HealthCondition.heartCondition,
                                     HealthCondition.pregnancy, HealthCondition.osteoporosis,
                                     HealthCondition.kneeInjury, HealthCondition.backPain),
        "front-squat"       to setOf(HealthCondition.hypertension, HealthCondition.heartCondition,
                                     HealthCondition.pregnancy, HealthCondition.kneeInjury,
                                     HealthCondition.backPain),
        "deadlift"          to setOf(HealthCondition.hypertension, HealthCondition.heartCondition,
                                     HealthCondition.pregnancy, HealthCondition.backPain,
                                     HealthCondition.osteoporosis),
        "rdl"               to setOf(HealthCondition.backPain, HealthCondition.pregnancy,
                                     HealthCondition.osteoporosis),
        "bench-press"       to setOf(HealthCondition.shoulderInjury, HealthCondition.heartCondition),
        "ohp"               to setOf(HealthCondition.shoulderInjury, HealthCondition.hypertension,
                                     HealthCondition.heartCondition),
        "pullup"            to setOf(HealthCondition.shoulderInjury, HealthCondition.pregnancy,
                                     HealthCondition.osteoporosis),
        "skullcrusher"      to setOf(HealthCondition.shoulderInjury),
        "jump-rope"         to setOf(HealthCondition.kneeInjury, HealthCondition.ankleInjury,
                                     HealthCondition.pregnancy, HealthCondition.heartCondition),
        "treadmill-run"     to setOf(HealthCondition.kneeInjury, HealthCondition.ankleInjury,
                                     HealthCondition.heartCondition, HealthCondition.obesity),
        "downward-dog"      to setOf(HealthCondition.hypertension, HealthCondition.pregnancy),
        "hanging-leg-raise" to setOf(HealthCondition.shoulderInjury, HealthCondition.backPain,
                                     HealthCondition.pregnancy),
        "lunge"             to setOf(HealthCondition.kneeInjury, HealthCondition.pregnancy),
        "goblet-squat"      to setOf(HealthCondition.kneeInjury, HealthCondition.pregnancy,
                                     HealthCondition.backPain),
        "couch-stretch"     to setOf(HealthCondition.kneeInjury),
        "pigeon-pose"       to setOf(HealthCondition.kneeInjury, HealthCondition.pregnancy),
    )

    val benefits: Map<String, Set<HealthCondition>> = mapOf(
        "child-pose"        to setOf(HealthCondition.backPain),
        "cat-cow"           to setOf(HealthCondition.backPain, HealthCondition.pregnancy),
        "thread-needle"     to setOf(HealthCondition.backPain, HealthCondition.shoulderInjury),
        "hip-flexor-stretch" to setOf(HealthCondition.backPain),
        "rower"             to setOf(HealthCondition.hypertension, HealthCondition.obesity,
                                     HealthCondition.diabetesT2),
        "lateral-raise"     to setOf(HealthCondition.osteoporosis),
        "calf-raise"        to setOf(HealthCondition.osteoporosis),
        "hip-thrust"        to setOf(HealthCondition.backPain),
        "pushup"            to setOf(HealthCondition.diabetesT2),
        "dumbbell-press"    to setOf(HealthCondition.diabetesT2, HealthCondition.obesity),
        "neck-rolls"        to setOf(HealthCondition.asthma),
        "shoulder-doorway"  to setOf(HealthCondition.asthma),
    )

    fun isSafe(exerciseId: String, conditions: Set<HealthCondition>): Boolean {
        val bad = cautions[exerciseId] ?: return true
        return bad.intersect(conditions).isEmpty()
    }

    fun conflictsFor(exerciseId: String, conditions: Set<HealthCondition>): Set<HealthCondition> =
        (cautions[exerciseId] ?: emptySet()).intersect(conditions)

    fun benefitsFor(exerciseId: String, conditions: Set<HealthCondition>): Set<HealthCondition> =
        (benefits[exerciseId] ?: emptySet()).intersect(conditions)
}

/** Hosted media URLs for exercise demos. Mirrors iOS `ExerciseMedia.gifURL`. */
object ExerciseMedia {
    private const val BASE_URL = "https://americangroupllc.github.io/HealthApp/assets/exercises"
    fun gifUrl(exerciseId: String): String = "$BASE_URL/$exerciseId.gif"
    fun thumbnailUrl(exerciseId: String): String = "$BASE_URL/$exerciseId.jpg"
}
