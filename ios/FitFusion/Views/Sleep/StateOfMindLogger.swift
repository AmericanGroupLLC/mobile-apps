import SwiftUI
import HealthKit
import FitFusionCore

/// 2-axis State of Mind picker (valence \u{00d7} arousal). Mirrors Apple's State of
/// Mind UX in the Health app: the user drags a dot in a square plane and picks
/// a label. Writes both `HKStateOfMindSample` (iOS 17+) and a CloudKit-synced
/// `StateOfMindEntity`.
struct StateOfMindLogger: View {
    @EnvironmentObject var hk: iOSHealthKitManager
    @EnvironmentObject var cloud: CloudStore
    @Environment(\.dismiss) private var dismiss

    @State private var valence: Double = 0      // -1 \u{2026} 1
    @State private var arousal: Double = 0      // -1 \u{2026} 1
    @State private var label: MoodLabel = .calm
    @State private var note: String = ""
    @State private var written = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Text("Drag the dot to capture how you feel.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    valenceArousalGrid
                        .frame(height: 280)
                        .padding(.horizontal)

                    HStack {
                        axisLabel("Calm", systemImage: "wind.snow")
                        Spacer()
                        axisLabel("Energized", systemImage: "bolt.fill")
                    }
                    .padding(.horizontal)
                    .font(.caption2).foregroundStyle(.secondary)

                    HStack {
                        axisLabel("Unpleasant", systemImage: "cloud.rain")
                        Spacer()
                        axisLabel("Pleasant", systemImage: "sun.max.fill")
                    }
                    .padding(.horizontal)
                    .font(.caption2).foregroundStyle(.secondary)

                    Picker("Label", selection: $label) {
                        ForEach(MoodLabel.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)

                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    Button {
                        Task { await save() }
                    } label: {
                        Label(written ? "Saved" : "Save State of Mind",
                              systemImage: written ? "checkmark.seal.fill" : "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.indigo, .purple],
                                                       startPoint: .leading, endPoint: .trailing),
                                        in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                    .disabled(written)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("How are you?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }

    private var valenceArousalGrid: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let xs = w / 2 + CGFloat(valence) * (w / 2 - 18)
            let ys = h / 2 - CGFloat(arousal) * (h / 2 - 18)

            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(LinearGradient(colors: [.purple.opacity(0.55), .pink.opacity(0.45),
                                                  .yellow.opacity(0.45), .green.opacity(0.55)],
                                          startPoint: .topLeading, endPoint: .bottomTrailing))
                Path { p in
                    p.move(to: CGPoint(x: w / 2, y: 0));   p.addLine(to: CGPoint(x: w / 2, y: h))
                    p.move(to: CGPoint(x: 0,     y: h / 2)); p.addLine(to: CGPoint(x: w, y: h / 2))
                }
                .stroke(.white.opacity(0.4), lineWidth: 1)

                Circle()
                    .fill(.white)
                    .frame(width: 28, height: 28)
                    .shadow(radius: 4)
                    .position(x: xs, y: ys)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let nv = Double((value.location.x - w / 2) / (w / 2 - 18))
                        let na = Double(-(value.location.y - h / 2) / (h / 2 - 18))
                        valence = max(-1, min(1, nv))
                        arousal = max(-1, min(1, na))
                        label = MoodLabel.fromQuadrant(valence: valence, arousal: arousal)
                    }
            )
        }
    }

    private func axisLabel(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage).labelStyle(.titleAndIcon)
    }

    private func save() async {
        // 1) HKStateOfMindSample (iOS 18+).
        if #available(iOS 18.0, *) {
            await hk.writeStateOfMind(label: label.healthKitLabel,
                                      valence: valence)
        }
        // 2) Mirrored CloudKit-synced entity for cross-device dashboards.
        _ = cloud.addStateOfMind(label: label.title,
                                 valence: valence,
                                 arousal: arousal,
                                 context: note.isEmpty ? nil : note)
        written = true
    }
}

/// User-facing label set; maps each option to an HKStateOfMind.Label on iOS 18+.
enum MoodLabel: CaseIterable {
    case happy, calm, content, sad, angry, anxious, energized

    var title: String {
        switch self {
        case .happy: return "Happy"
        case .calm: return "Calm"
        case .content: return "Content"
        case .sad: return "Sad"
        case .angry: return "Angry"
        case .anxious: return "Anxious"
        case .energized: return "Energized"
        }
    }

    @available(iOS 18.0, *)
    var healthKitLabel: HKStateOfMind.Label {
        switch self {
        case .happy: return .happy
        case .calm: return .calm
        case .content: return .content
        case .sad: return .sad
        case .angry: return .angry
        case .anxious: return .anxious
        case .energized: return .excited
        }
    }

    /// Default suggestion for the picked grid quadrant; the user can override.
    static func fromQuadrant(valence: Double, arousal: Double) -> MoodLabel {
        switch (valence >= 0, arousal >= 0) {
        case (true, true):   return .happy
        case (true, false):  return .calm
        case (false, true):  return .anxious
        case (false, false): return .sad
        }
    }
}
