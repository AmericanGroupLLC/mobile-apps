import SwiftUI
import DriftCore

struct WaveActions: View {
    let target: Profile
    let layer: Layer
    @EnvironmentObject private var session: AppSession

    var body: some View {
        HStack(spacing: 16) {
            Button { Task { await pass() } } label: {
                Label("Pass", systemImage: "xmark")
            }.buttonStyle(.bordered)

            Spacer()

            Button { Task { await wave() } } label: {
                Label("Wave", systemImage: "hand.wave.fill")
            }.buttonStyle(.borderedProminent)
        }
    }

    private func wave() async {
        guard let viewer = session.currentProfile else { return }
        _ = try? await DiscoverService.shared.wave(from: viewer, to: target, layer: layer)
    }
    private func pass() async {
        // no-op in v1; record locally so it doesn't reappear
    }
}
