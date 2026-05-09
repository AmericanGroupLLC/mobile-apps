import Foundation

/// Bundled offline-readable starter health articles. Used when the device is
/// offline or guest mode is on and the user opens the Articles tab. The
/// online MyHealthfinder route layers fresh, location-aware topics on top.
public enum HealthArticleSeed {

    public struct Article: Identifiable, Hashable {
        public let id: String
        public let title: String
        public let category: String
        public let summary: String
        public let body: String      // markdown-ish
    }

    public static let articles: [Article] = [
        .init(
            id: "stay-active-7-days",
            title: "Move Every Day for 7 Days",
            category: "Activity",
            summary: "A gentle 7-day plan to make daily movement a habit.",
            body: """
            Daily movement is the single biggest lever for long-term health. \
            You don't need a gym \u{2014} a brisk walk, a few flights of stairs, or \
            a 10-minute home circuit will do.

            **Day 1.** Walk 15 minutes after lunch.
            **Day 2.** Add 5 minutes of stretching after the walk.
            **Day 3.** Try one strength move (push-ups or squats) \u{00d7} 10 reps.
            **Day 4.** Walk 20 minutes.
            **Day 5.** Strength move + 5 minute breathing.
            **Day 6.** A 30-minute "movement snack" \u{2014} anything you enjoy.
            **Day 7.** Reflect, log a mood, plan next week.
            """
        ),
        .init(
            id: "sleep-hygiene",
            title: "Sleep Hygiene Basics",
            category: "Sleep",
            summary: "Six small habits that improve sleep tonight.",
            body: """
            1. Same bedtime + wake time, even on weekends.
            2. Bright light in the morning, dim light at night.
            3. Caffeine cutoff 8 hours before bed.
            4. Bedroom: cool (~18\u{00a0}\u{00b0}C), dark, quiet.
            5. Wind-down routine: 30 minutes of low-stim activity.
            6. No screens for the last 30 minutes \u{2014} read a book instead.
            """
        ),
        .init(
            id: "hydration-truth",
            title: "How Much Water Do You Really Need?",
            category: "Nutrition",
            summary: "Evidence-based hydration guidelines.",
            body: """
            "Drink 8 cups a day" is folklore. Most adults need roughly \
            **30 ml per kg of body weight** per day, including water from food \
            and other drinks. Active people, hot weather, and high-protein \
            diets push that number up.

            Watch for: pale-yellow urine = good; dark yellow = drink more; \
            crystal-clear all day = you may be over-drinking.
            """
        ),
        .init(
            id: "strength-basics",
            title: "Strength Training for Beginners",
            category: "Training",
            summary: "Two sessions a week, six exercises, big returns.",
            body: """
            The minimum effective dose for adults: **2 strength sessions per week**. \
            Start with these six compound moves:

            * Squat (bodyweight \u{2192} goblet \u{2192} barbell)
            * Hinge (Romanian deadlift)
            * Push (push-up \u{2192} dumbbell press)
            * Pull (row variations)
            * Carry (suitcase carry)
            * Anti-rotation (Pallof press)

            3 sets of 8\u{2013}12 reps each. Rest 60\u{2013}90 seconds. Add a small bit \
            of weight or one more rep each week.
            """
        ),
        .init(
            id: "stress-recovery",
            title: "Stress, HRV, and Recovery",
            category: "Wellness",
            summary: "Why your watch tracks HRV and what to do with it.",
            body: """
            Heart Rate Variability (HRV) reflects how your nervous system is \
            balancing recovery and arousal. Higher = more recovered.

            Boosters: 7\u{2013}9 hours of sleep, slow nasal breathing, sunlight, \
            zone-2 cardio, social connection, omega-3, magnesium.

            Tankers: alcohol, late caffeine, poor sleep, chronic stress, \
            heavy training without recovery.
            """
        ),
        .init(
            id: "med-adherence",
            title: "Sticking With Your Meds",
            category: "Care",
            summary: "Practical tips for daily medicine adherence.",
            body: """
            * Anchor doses to existing routines (toothbrush, coffee, dinner).
            * Use a pill organiser for the week.
            * Set notifications with the **Take** action so logging is one tap.
            * Travel: keep a 3-day supply on you, not in checked luggage.
            * Talk to your pharmacist about combining refills on one day.
            """
        ),
    ]
}
