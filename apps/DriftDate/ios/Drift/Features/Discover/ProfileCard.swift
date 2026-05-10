import SwiftUI
import DriftCore

struct ProfileCard: View {
    let profile: Profile
    let layer: Layer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(profile.displayName).font(.title3.bold())
                if profile.isVerified {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                }
                Spacer()
                Text(layerChipLabel(layer)).font(.caption2.bold())
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }
            Text(profile.intent.rawValue.capitalized).font(.subheadline).foregroundStyle(.secondary)
            if !profile.vibeTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(profile.vibeTags, id: \.self) { tag in
                            Text(tag).font(.caption2).padding(6)
                                .background(.tertiary, in: Capsule())
                        }
                    }
                }
            }
            WaveActions(target: profile, layer: layer)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func layerChipLabel(_ l: Layer) -> String {
        switch l {
        case .zip:    return "same ZIP"
        case .county: return "same county"
        case .state:  return "same state"
        case .server: return "server"
        }
    }
}
