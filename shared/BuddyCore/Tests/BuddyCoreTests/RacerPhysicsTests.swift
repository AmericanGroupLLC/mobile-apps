import XCTest
@testable import BuddyCore

final class RacerPhysicsTests: XCTestCase {

    private func newGame() -> (RacerState, UUID, UUID) {
        let h = Peer(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                     displayName: "H", platform: .ios, lastSeenAt: Date())
        let g = Peer(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                     displayName: "G", platform: .android, lastSeenAt: Date())
        return (RacerPhysics.initialState(host: h, guest: g), h.id, g.id)
    }

    func testTickIsDeterministic() {
        var (s1, h, g) = newGame()
        var (s2, _, _) = newGame()
        let input = RacerInput(player: h, throttle: 1.0, brake: 0, steering: 0.2)
        s1.cars[h]?.lastInput = input
        s2.cars[h]?.lastInput = input
        for _ in 0..<60 {
            s1 = RacerPhysics.tick(s1, dtMillis: 33)
            s2 = RacerPhysics.tick(s2, dtMillis: 33)
        }
        XCTAssertEqual(s1.cars[h]?.x, s2.cars[h]?.x)
        XCTAssertEqual(s1.cars[h]?.y, s2.cars[h]?.y)
        XCTAssertEqual(s1.cars[h]?.heading, s2.cars[h]?.heading)
        XCTAssertEqual(s1.cars[g]?.x, s2.cars[g]?.x)
    }

    func testThrottleAccelerates() {
        var (s, h, _) = newGame()
        s.cars[h]?.lastInput = RacerInput(player: h, throttle: 1.0, brake: 0, steering: 0)
        let initialSpeed = s.cars[h]!.speed
        for _ in 0..<10 { s = RacerPhysics.tick(s, dtMillis: 33) }
        XCTAssertGreaterThan(s.cars[h]!.speed, initialSpeed)
    }

    func testWallBouncesVelocity() {
        var (s, h, _) = newGame()
        // Place car next to right wall heading right at top speed.
        s.cars[h] = RacerCar(
            x: RacerPhysics.trackWidth - 0.1,
            y: 30, heading: 0, speed: RacerPhysics.maxSpeed,
            lastInput: nil
        )
        s = RacerPhysics.tick(s, dtMillis: 33)
        XCTAssertLessThanOrEqual(s.cars[h]!.x, RacerPhysics.trackWidth)
        XCTAssertLessThan(s.cars[h]!.speed, 0, "wall bounce should reverse velocity")
    }

    func testIdleDecaySlowsCar() {
        var (s, h, _) = newGame()
        s.cars[h]?.speed = 20
        s.cars[h]?.lastInput = nil
        for _ in 0..<10 { s = RacerPhysics.tick(s, dtMillis: 33) }
        XCTAssertLessThan(s.cars[h]!.speed, 20)
    }
}
