package com.americangroupllc.buddyplay.core.domain

import com.americangroupllc.buddyplay.core.models.Peer
import kotlinx.serialization.Serializable
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Pure deterministic 2D top-down racer physics. `tick(state, dt, input)`
 * returns the next state. Identical inputs + identical dt produce identical
 * state on both peers, enabling client-side prediction + host reconciliation.
 *
 * Mirror of `shared/BuddyCore/Sources/BuddyCore/Domain/RacerPhysics.swift`.
 */
object RacerPhysics : GameStateReducer<RacerState, RacerInput> {

    const val TRACK_WIDTH: Double  = 100.0
    const val TRACK_HEIGHT: Double = 60.0
    const val MAX_SPEED: Double    = 30.0
    const val ACCELERATION: Double = 50.0
    const val BRAKING: Double      = 70.0
    const val IDLE_DECAY: Double   = 12.0
    const val TURN_RATE: Double    = 3.5
    const val BOUNCE_FACTOR: Double = 0.55

    override fun initialState(host: Peer, guest: Peer): RacerState =
        RacerState(
            host = host.id,
            guest = guest.id,
            cars = mutableMapOf(
                host.id  to RacerCar(20.0, 30.0, 0.0, 0.0, null),
                guest.id to RacerCar(80.0, 30.0, Math.PI, 0.0, null),
            ),
            laps = mutableMapOf(host.id to 0, guest.id to 0),
            tickCount = 0,
            winnerId = null,
        )

    override fun reduce(state: RacerState, input: RacerInput): GameStateReducer.Step<RacerState> {
        if (state.winnerId != null) throw GameStateReducer.Error.GameOver
        val s = state.copy(cars = HashMap(state.cars))
        s.cars[input.player] = s.cars[input.player]!!.copy(lastInput = input)
        val next = tick(s, dtMillis = 33)
        val outcome = next.winnerId?.let { GameStateReducer.Outcome.Winner(it) }
        return GameStateReducer.Step(next, outcome)
    }

    override fun isFinal(state: RacerState): Boolean = state.winnerId != null

    override fun currentTurn(state: RacerState): String? = null

    fun tick(state: RacerState, dtMillis: Int): RacerState {
        if (state.winnerId != null) return state
        val dt = dtMillis / 1000.0
        val s = state.copy(cars = HashMap(state.cars))
        for ((id, car) in s.cars.toMap()) {
            s.cars[id] = step(car, dt)
        }
        s.tickCount += 1
        return s
    }

    private fun step(car: RacerCar, dt: Double): RacerCar {
        var x = car.x; var y = car.y; var heading = car.heading; var speed = car.speed
        val input = car.lastInput

        if (input != null) heading += input.steering * TURN_RATE * dt

        if (input != null && input.throttle > 0) speed += ACCELERATION * input.throttle * dt
        else if (input != null && input.brake > 0) speed -= BRAKING * input.brake * dt
        else {
            if (speed > 0) speed = max(0.0, speed - IDLE_DECAY * dt)
            else if (speed < 0) speed = min(0.0, speed + IDLE_DECAY * dt)
        }
        speed = max(-MAX_SPEED * 0.5, min(MAX_SPEED, speed))

        x += cos(heading) * speed * dt
        y += sin(heading) * speed * dt

        if (x < 0)            { x = 0.0;          speed = -speed * BOUNCE_FACTOR }
        if (x > TRACK_WIDTH)  { x = TRACK_WIDTH;  speed = -speed * BOUNCE_FACTOR }
        if (y < 0)            { y = 0.0;          speed = -speed * BOUNCE_FACTOR }
        if (y > TRACK_HEIGHT) { y = TRACK_HEIGHT; speed = -speed * BOUNCE_FACTOR }

        return car.copy(x = x, y = y, heading = heading, speed = speed)
    }
}

@Serializable
data class RacerInput(
    val player: String,
    val throttle: Double,
    val brake: Double,
    val steering: Double,
) {
    init {
        require(throttle in 0.0..1.0) { "throttle out of range" }
        require(brake in 0.0..1.0)    { "brake out of range" }
        require(steering in -1.0..1.0) { "steering out of range" }
    }
}

@Serializable
data class RacerCar(
    val x: Double,
    val y: Double,
    val heading: Double,
    val speed: Double,
    val lastInput: RacerInput?,
)

@Serializable
data class RacerState(
    val host: String,
    val guest: String,
    val cars: MutableMap<String, RacerCar>,
    val laps: MutableMap<String, Int>,
    var tickCount: Int,
    var winnerId: String?,
)
