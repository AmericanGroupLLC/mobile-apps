import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity

/// Thin wrapper around WCSession.updateApplicationContext for pushing today's plan
/// + readiness from iPhone -> Apple Watch (and vice versa for small status payloads).
///
/// Also exposes a Combine-style `liveTickStream` (`AsyncStream`) that emits each
/// time a peer sends a small `sendMessage(_:replyHandler:)` payload \u{2014} used by
/// MyHealth's Workout Mirroring path so iOS can react to per-second
/// HR/calories/distance ticks emitted by `WorkoutController` on the watch.
@MainActor
public final class WatchBridge: NSObject, ObservableObject {
    public static let shared = WatchBridge()

    @Published public private(set) var lastReceivedContext: [String: Any] = [:]
    @Published public private(set) var isActivated = false

    /// Streamed live ticks from a paired peer (typically the watch's
    /// `WorkoutController` per-second snapshot). Subscribers get a fresh
    /// `LiveTick` each time `pushLiveTick(...)` is called on the other side.
    public struct LiveTick: Hashable, Sendable {
        public let elapsed: TimeInterval
        public let heartRate: Double
        public let calories: Double
        public let distanceMeters: Double
        public let activityRaw: UInt
        public init(elapsed: TimeInterval, heartRate: Double, calories: Double,
                    distanceMeters: Double, activityRaw: UInt) {
            self.elapsed = elapsed
            self.heartRate = heartRate
            self.calories = calories
            self.distanceMeters = distanceMeters
            self.activityRaw = activityRaw
        }
    }

    /// Lazy AsyncStream the receiver iterates with `for await tick in WatchBridge.shared.liveTickStream`.
    public var liveTickStream: AsyncStream<LiveTick> {
        AsyncStream { continuation in
            let id = UUID()
            self.tickContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in self?.tickContinuations.removeValue(forKey: id) }
            }
        }
    }

    private var tickContinuations: [UUID: AsyncStream<LiveTick>.Continuation] = [:]

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    /// Push today's planning context to the paired Watch (or back to iPhone).
    /// Keys are stable strings so the receiver can read them without a shared schema.
    public func push(readinessScore: Int? = nil,
                     readinessSuggestion: String? = nil,
                     todayPlanIds: [String]? = nil,
                     extra: [String: Any] = [:]) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        var context: [String: Any] = extra
        if let s = readinessScore { context["readinessScore"] = s }
        if let t = readinessSuggestion { context["readinessSuggestion"] = t }
        if let p = todayPlanIds { context["todayPlanIds"] = p }
        context["updatedAt"] = Date().timeIntervalSince1970

        do {
            try session.updateApplicationContext(context)
        } catch {
            // Swallow \u{2014} context updates are best-effort.
        }
    }

    /// Send a per-second live workout tick to the paired peer. No-op when
    /// the session isn't reachable (Watch off-wrist, app background-throttled).
    public func pushLiveTick(elapsed: TimeInterval,
                             heartRate: Double,
                             calories: Double,
                             distanceMeters: Double,
                             activityRaw: UInt) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }
        let payload: [String: Any] = [
            "kind": "liveTick",
            "elapsed": elapsed,
            "hr": heartRate,
            "calories": calories,
            "distance": distanceMeters,
            "activity": activityRaw,
        ]
        session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
    }
}

extension WatchBridge: WCSessionDelegate {
    nonisolated public func session(_ session: WCSession,
                                    activationDidCompleteWith activationState: WCSessionActivationState,
                                    error: Error?) {
        Task { @MainActor in
            self.isActivated = (activationState == .activated)
        }
    }

    nonisolated public func session(_ session: WCSession,
                                    didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            self.lastReceivedContext = applicationContext
        }
    }

    nonisolated public func session(_ session: WCSession,
                                    didReceiveMessage message: [String : Any]) {
        guard let kind = message["kind"] as? String, kind == "liveTick" else { return }
        let tick = WatchBridge.LiveTick(
            elapsed: (message["elapsed"] as? TimeInterval) ?? 0,
            heartRate: (message["hr"] as? Double) ?? 0,
            calories: (message["calories"] as? Double) ?? 0,
            distanceMeters: (message["distance"] as? Double) ?? 0,
            activityRaw: (message["activity"] as? UInt) ?? 0
        )
        Task { @MainActor in
            for cont in self.tickContinuations.values { cont.yield(tick) }
        }
    }

    #if os(iOS)
    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}

#else

/// Stub for platforms without WatchConnectivity.
@MainActor
public final class WatchBridge: ObservableObject {
    public static let shared = WatchBridge()

    public struct LiveTick: Hashable, Sendable {
        public let elapsed: TimeInterval
        public let heartRate: Double
        public let calories: Double
        public let distanceMeters: Double
        public let activityRaw: UInt
        public init(elapsed: TimeInterval, heartRate: Double, calories: Double,
                    distanceMeters: Double, activityRaw: UInt) {
            self.elapsed = elapsed; self.heartRate = heartRate
            self.calories = calories; self.distanceMeters = distanceMeters
            self.activityRaw = activityRaw
        }
    }

    public var liveTickStream: AsyncStream<LiveTick> {
        AsyncStream { _ in /* never emits on this platform */ }
    }

    @Published public private(set) var lastReceivedContext: [String: Any] = [:]
    @Published public private(set) var isActivated = false
    private init() {}
    public func push(readinessScore: Int? = nil,
                     readinessSuggestion: String? = nil,
                     todayPlanIds: [String]? = nil,
                     extra: [String: Any] = [:]) {}
    public func pushLiveTick(elapsed: TimeInterval,
                             heartRate: Double,
                             calories: Double,
                             distanceMeters: Double,
                             activityRaw: UInt) {}
}

#endif
