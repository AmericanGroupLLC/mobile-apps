import SwiftUI
import FitFusionCore

/// 5-minute breath / mindful session that writes to HealthKit's `mindfulSession`.
@MainActor
struct WindDownSheet: View {
    @EnvironmentObject var hk: iOSHealthKitManager
    @EnvironmentObject var cloud: CloudStore
    @Environment(\.dismiss) private var dismiss

    @State private var phase: BreathPhase = .idle
    @State private var startedAt: Date?
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var written = false
    @State private var showStateOfMind = false

    private let totalSeconds: TimeInterval = 5 * 60

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.indigo, .purple, .pink],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 220, height: 220)
                        .scaleEffect(phase.scale)
                        .animation(.easeInOut(duration: phase.duration), value: phase)
                    Text(phase.label)
                        .font(.title2).bold().foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    Text(format(elapsed)).font(.title3).bold()
                    ProgressView(value: min(elapsed, totalSeconds), total: totalSeconds)
                        .tint(.purple)
                }
                .padding(.horizontal, 40)

                if written {
                    Label("Saved a 5-minute mindful session to Health", systemImage: "checkmark.seal.fill")
                        .font(.footnote).foregroundStyle(.green)
                }

                Button { showStateOfMind = true } label: {
                    Label("Log State of Mind", systemImage: "brain.head.profile")
                        .font(.footnote)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(.indigo.opacity(0.18), in: Capsule())
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showStateOfMind) {
                    StateOfMindLogger()
                        .environmentObject(hk)
                        .environmentObject(cloud)
                }

                HStack(spacing: 16) {
                    Button(role: .destructive) { stop() } label: {
                        Text("End")
                            .frame(maxWidth: .infinity).padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    Button { start() } label: {
                        Label(phase == .idle ? "Begin" : "Restart",
                              systemImage: phase == .idle ? "play.fill" : "arrow.clockwise")
                            .frame(maxWidth: .infinity).padding()
                            .background(LinearGradient(colors: [.indigo, .purple],
                                                       startPoint: .leading, endPoint: .trailing),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Wind Down")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { stop(); dismiss() }
                }
            }
        }
        .onDisappear { timer?.invalidate() }
    }

    private func start() {
        startedAt = Date()
        elapsed = 0
        written = false
        cycleBreath()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                if let s = startedAt {
                    elapsed = Date().timeIntervalSince(s)
                    if elapsed >= totalSeconds && !written {
                        await hk.writeMindfulSession(start: s, end: Date())
                        written = true
                    }
                }
            }
        }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        if let s = startedAt, !written {
            // Save the partial session if at least 1 minute completed.
            if elapsed >= 60 {
                Task {
                    await hk.writeMindfulSession(start: s, end: Date())
                    written = true
                }
            }
        }
        phase = .idle
        startedAt = nil
        elapsed = 0
    }

    private func cycleBreath() {
        Task {
            while startedAt != nil {
                phase = .inhale
                try? await Task.sleep(nanoseconds: UInt64(BreathPhase.inhale.duration * 1_000_000_000))
                phase = .hold
                try? await Task.sleep(nanoseconds: UInt64(BreathPhase.hold.duration * 1_000_000_000))
                phase = .exhale
                try? await Task.sleep(nanoseconds: UInt64(BreathPhase.exhale.duration * 1_000_000_000))
            }
        }
    }

    private func format(_ s: TimeInterval) -> String {
        let m = Int(s) / 60, sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}

private enum BreathPhase {
    case idle, inhale, hold, exhale

    var scale: CGFloat {
        switch self {
        case .idle, .exhale: return 0.7
        case .inhale, .hold: return 1.05
        }
    }

    var duration: TimeInterval {
        switch self {
        case .idle:   return 0.4
        case .inhale: return 4
        case .hold:   return 4
        case .exhale: return 6
        }
    }

    var label: String {
        switch self {
        case .idle:   return "Press Begin"
        case .inhale: return "Inhale"
        case .hold:   return "Hold"
        case .exhale: return "Exhale"
        }
    }
}
