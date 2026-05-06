import Foundation
import Combine
import BuddyCore

@MainActor
final class RacerViewModel: ObservableObject {

    @Published private(set) var state: RacerState
    @Published var localInput: RacerInput
    @Published var rejectMessage: String?

    let host: Peer
    let guest: Peer
    let localPlayerId: UUID

    private var ticker: Timer?

    init(host: Peer, guest: Peer, localPlayerId: UUID, transport: Transport) {
        self.host = host
        self.guest = guest
        self.localPlayerId = localPlayerId
        self.state = RacerPhysics.initialState(host: host, guest: guest)
        self.localInput = RacerInput(player: localPlayerId, throttle: 0, brake: 0, steering: 0)

        // Mini Racer rejects BLE.
        if transport == .ble {
            self.rejectMessage = "Mini Racer needs Wi-Fi or Hotspot — BLE is too slow for real-time play. Pick a turn-based game (Chess or Dice Kingdom) or switch to Wi-Fi."
        }
    }

    /// Start the host's 30 Hz physics loop. Guests would normally receive
    /// state snapshots from the host instead.
    func startTicking() {
        guard rejectMessage == nil else { return }
        stopTicking()
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickOnce() }
        }
    }

    func stopTicking() {
        ticker?.invalidate()
        ticker = nil
    }

    func setThrottle(_ v: Double) {
        localInput = RacerInput(player: localInput.player, throttle: v, brake: localInput.brake, steering: localInput.steering)
        updateLocalCarInput()
    }
    func setBrake(_ v: Double) {
        localInput = RacerInput(player: localInput.player, throttle: localInput.throttle, brake: v, steering: localInput.steering)
        updateLocalCarInput()
    }
    func setSteering(_ v: Double) {
        localInput = RacerInput(player: localInput.player, throttle: localInput.throttle, brake: localInput.brake, steering: v)
        updateLocalCarInput()
    }

    private func updateLocalCarInput() {
        // Stash the latest input on the local car so the next tick uses it.
        if var car = state.cars[localPlayerId] {
            car.lastInput = localInput
            state.cars[localPlayerId] = car
        }
    }

    private func tickOnce() {
        state = RacerPhysics.tick(state, dtMillis: 33)
    }
}
