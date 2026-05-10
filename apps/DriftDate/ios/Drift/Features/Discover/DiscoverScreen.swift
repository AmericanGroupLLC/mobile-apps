import SwiftUI
import DriftCore

struct DiscoverScreen: View {
    @EnvironmentObject private var session: AppSession
    @State private var layer: Layer = .zip
    @State private var candidates: [Profile] = []
    @State private var loading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Layer", selection: $layer) {
                    ForEach(Layer.allCases, id: \.self) { l in
                        Text(l.rawValue.capitalized).tag(l)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if loading {
                    ProgressView().padding(.top, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(candidates) { p in
                                ProfileCard(profile: p, layer: layer)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .task(id: layer) { await reload() }
            .onChange(of: layer) { _, new in
                AnalyticsService.shared.track(.layerSwitched(from: layer, to: new))
            }
        }
    }

    private func reload() async {
        guard let viewer = session.currentProfile else { return }
        loading = true
        candidates = (try? await DiscoverService.shared.candidates(in: layer, viewer: viewer)) ?? []
        loading = false
    }
}
