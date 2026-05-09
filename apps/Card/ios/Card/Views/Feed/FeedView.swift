import SwiftUI
import CardCore

struct FeedView: View {
    @EnvironmentObject private var repository: CardRepository
    @State private var draft: String = ""
    @State private var selectedCard: Card?

    var body: some View {
        VStack(spacing: 0) {
            ComposerView(text: $draft) {
                repository.capture(text: draft)
                draft = ""
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            Divider()
            List {
                ForEach(repository.cards) { card in
                    CardRow(card: card)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedCard = card }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                repository.delete(card)
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                }
            }
            .listStyle(.plain)
        }
        .sheet(item: $selectedCard) { card in
            CardActionSheet(card: card)
        }
        .onAppear { repository.reload() }
    }
}

#Preview {
    FeedView()
        .environmentObject(CardRepository.shared)
        .environmentObject(SettingsModel.shared)
}
