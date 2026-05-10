package com.americangroupllc.drift.core.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class Layer {
    @SerialName("zip")    ZIP,
    @SerialName("county") COUNTY,
    @SerialName("state")  STATE,
    @SerialName("server") SERVER;
}

@Serializable
enum class Intent {
    @SerialName("dating")     DATING,
    @SerialName("serious")    SERIOUS,
    @SerialName("friendship") FRIENDSHIP,
    @SerialName("open")       OPEN;
}

@Serializable
enum class Tone {
    @SerialName("slow")          SLOW,
    @SerialName("energetic")     ENERGETIC,
    @SerialName("deep")          DEEP,
    @SerialName("meetup_ready")  MEETUP_READY;
}

@Serializable
enum class WaveStatus {
    @SerialName("pending") PENDING,
    @SerialName("matched") MATCHED,
    @SerialName("passed")  PASSED;
}
