import Foundation

/// Pure deterministic 2D top-down racer physics. `tick(state, dt, input)`
/// returns the next state. Identical inputs + identical dt produce identical
/// state on both peers, enabling client-side prediction + host reconciliation.
public enum RacerPhysics: GameStateReducer {
    public typealias State = RacerState
    public typealias Input = RacerInput

    /// Track dimensions. v1 ships a single rectangular arena.
    public static let trackWidth: Double  = 100.0
    public static let trackHeight: Double = 60.0

    /// Physics constants — tuned for "fun > realistic".
    public static let maxSpeed: Double      = 30.0
    public static let acceleration: Double  = 50.0
    public static let braking: Double       = 70.0
    public static let idleDecay: Double     = 12.0
    public static let turnRate: Double      = 3.5  // rad/s
    public static let bounceFactor: Double  = 0.55

    public static func initialState(host: Peer, guest: Peer) -> RacerState {
        RacerState(
            host: host.id,
            guest: guest.id,
            cars: [
                host.id:  RacerCar(x: 20, y: 30, heading: 0, speed: 0),
                guest.id: RacerCar(x: 80, y: 30, heading: .pi, speed: 0),
            ],
            laps: [host.id: 0, guest.id: 0],
            tickCount: 0,
            winnerId: nil
        )
    }

    /// `reduce` adapts the protocol API: apply the input, advance one fixed
    /// 33 ms tick, and surface the winner if one was just declared.
    public static func reduce(_ state: RacerState, input: RacerInput) throws -> Step {
        if state.winnerId != nil { throw Error.gameOver }
        var s = state
        s.cars[input.player]?.lastInput = input
        let next = tick(s, dtMillis: 33)
        let outcome: Outcome? = next.winnerId.map { .winner($0) }
        return (next, outcome)
    }

    public static func isFinal(_ state: RacerState) -> Bool {
        state.winnerId != nil
    }

    /// Real-time game — no `currentTurn`.
    public static func currentTurn(_ state: RacerState) -> UUID? { nil }

    // MARK: - Tick

    /// Fixed-timestep physics step. Used directly by the host's game loop;
    /// the guest replays it for client-side prediction.
    public static func tick(_ state: RacerState, dtMillis: Int) -> RacerState {
        if state.winnerId != nil { return state }
        let dt = Double(dtMillis) / 1000.0
        var s = state
        for (id, car) in s.cars {
            s.cars[id] = step(car, dt: dt)
        }
        s.tickCount += 1
        return s
    }

    private static func step(_ car: RacerCar, dt: Double) -> RacerCar {
        var c = car
        let input = c.lastInput

        // Steering.
        if let i = input {
            c.heading += i.steering * turnRate * dt
        }

        // Throttle / brake.
        if let i = input, i.throttle > 0 {
            c.speed += acceleration * i.throttle * dt
        } else if let i = input, i.brake > 0 {
            c.speed -= braking * i.brake * dt
        } else {
            // Idle decay.
            if c.speed > 0 { c.speed = max(0, c.speed - idleDecay * dt) }
            else if c.speed < 0 { c.speed = min(0, c.speed + idleDecay * dt) }
        }
        c.speed = max(-maxSpeed * 0.5, min(maxSpeed, c.speed))

        // Position update.
        c.x += cos(c.heading) * c.speed * dt
        c.y += sin(c.heading) * c.speed * dt

        // Wall bounce.
        if c.x < 0           { c.x = 0;            c.speed = -c.speed * bounceFactor }
        if c.x > trackWidth  { c.x = trackWidth;   c.speed = -c.speed * bounceFactor }
        if c.y < 0           { c.y = 0;            c.speed = -c.speed * bounceFactor }
        if c.y > trackHeight { c.y = trackHeight;  c.speed = -c.speed * bounceFactor }

        return c
    }
}

// MARK: - Types

public struct RacerInput: Codable, Equatable, Sendable {
    public let player: UUID
    /// 0..1 forward throttle.
    public let throttle: Double
    /// 0..1 brake.
    public let brake: Double
    /// -1..1 steering (negative = left, positive = right).
    public let steering: Double

    public init(player: UUID, throttle: Double, brake: Double, steering: Double) {
        self.player = player
        self.throttle = max(0, min(1, throttle))
        self.brake = max(0, min(1, brake))
        self.steering = max(-1, min(1, steering))
    }
}

public struct RacerCar: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var heading: Double // radians
    public var speed: Double
    public var lastInput: RacerInput?

    public init(x: Double, y: Double, heading: Double, speed: Double, lastInput: RacerInput? = nil) {
        self.x = x; self.y = y; self.heading = heading; self.speed = speed; self.lastInput = lastInput
    }
}

public struct RacerState: Codable, Equatable, Sendable {
    public let host: UUID
    public let guest: UUID
    public var cars: [UUID: RacerCar]
    public var laps: [UUID: Int]
    public var tickCount: Int
    /// Set when the race is over. v1 has no automatic finish line; the
    /// lobby will mark a winner manually after a fixed-time race.
    public var winnerId: UUID?
}
