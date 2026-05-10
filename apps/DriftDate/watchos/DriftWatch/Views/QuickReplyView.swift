import SwiftUI
import DriftCore

/// 1-tap accept on a pending Wave + three suggested replies (Casual /
/// Context / Playful) once the conversation exists.
struct QuickReplyView: View {
    let wave: Wave
    @State private var suggestions: ReplySuggestion?

    var body: some View {
        VStack(spacing: 8) {
            Text(wave.layer.rawValue.capitalized).font(.caption2).foregroundStyle(.secondary)
            if wave.status == .pending {
                Button("Wave back") { /* PATCH /rest/v1/waves */ }
                    .buttonStyle(.borderedProminent)
            } else if let s = suggestions {
                replyRow("Casual",  s.casual)
                replyRow("Context", s.context)
                replyRow("Playful", s.playful)
            } else {
                ProgressView()
            }
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func replyRow(_ label: String, _ text: String) -> some View {
        Button { /* send */ } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption2).foregroundStyle(.secondary)
                Text(text).font(.caption).lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
    }
}
