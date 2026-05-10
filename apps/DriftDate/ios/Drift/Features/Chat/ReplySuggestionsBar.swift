import SwiftUI
import DriftCore

struct ReplySuggestionsBar: View {
    let suggestions: ReplySuggestion?
    let onTap: (String) -> Void

    var body: some View {
        if let s = suggestions {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    pill("Casual",  s.casual,  kind: .casual)
                    pill("Context", s.context, kind: .context)
                    pill("Playful", s.playful, kind: .playful)
                }.padding(.horizontal)
            }.frame(height: 56)
        }
    }

    @ViewBuilder
    private func pill(_ label: String, _ text: String, kind: AnalyticsEvent.ReplyKind) -> some View {
        Button {
            AnalyticsService.shared.track(.replySuggestionUsed(tone: suggestions?.tone ?? .slow, kind: kind))
            onTap(text)
        } label: {
            VStack(alignment: .leading) {
                Text(label).font(.caption2).foregroundStyle(.secondary)
                Text(text).font(.caption).lineLimit(2)
            }
            .padding(8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}
