import SwiftUI
import ARKit
import SceneKit

struct MeasureView: View {
    @State private var distanceMeters: Double? = nil
    @State private var unit: Unit = .cm
    @State private var arAvailable: Bool = ARWorldTrackingConfiguration.isSupported

    enum Unit: String, CaseIterable, Identifiable { case cm, inches; var id: String { rawValue } }

    var body: some View {
        ZStack {
            if arAvailable {
                MeasureARRepresentable(distanceMeters: $distanceMeters)
                    .ignoresSafeArea()
            } else {
                MeasureRulerView()
            }
            VStack {
                Spacer()
                bottomBar
            }
        }
        .navigationTitle("Measure")
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            Text(displayDistance).font(.title.weight(.semibold)).padding(.horizontal, 24).padding(.vertical, 8)
                .background(.ultraThinMaterial).clipShape(Capsule())
            Picker("Unit", selection: $unit) {
                Text("cm").tag(Unit.cm)
                Text("in").tag(Unit.inches)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
        }
        .padding(.bottom, 24)
    }

    private var displayDistance: String {
        guard let d = distanceMeters else { return "Tap two points" }
        switch unit {
        case .cm:     return String(format: "%.1f cm", d * 100)
        case .inches: return String(format: "%.2f in", d * 39.3701)
        }
    }
}

struct MeasureARRepresentable: UIViewControllerRepresentable {
    @Binding var distanceMeters: Double?

    func makeUIViewController(context: Context) -> MeasureARViewController {
        let vc = MeasureARViewController()
        vc.onDistance = { d in distanceMeters = d }
        return vc
    }

    func updateUIViewController(_ uiViewController: MeasureARViewController, context: Context) {}
}
