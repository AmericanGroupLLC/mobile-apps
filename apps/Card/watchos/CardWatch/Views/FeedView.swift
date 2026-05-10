import SwiftUI
import CardCore

struct FeedView: View {
    @EnvironmentObject private var repository: WatchCardRepository
    @State private var showComposer = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(repository.cards) { card in
                    HStack(alignment: .top, spacing: 6) {
                        if card.kind == .task {
                            Image(systemName: card.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(card.isCompleted ? .green : .secondary)
                        }
                        Text(card.text)
                            .lineLimit(3)
                        Spacer(minLength: 0)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .swipeActions { Button(role: .destructive) { repository.delete(card) } label: {
                        Label("Delete", systemImage: "trash")
                    } }
                }
            }
            .padding(.horizontal, 4)
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    showComposer = true
                } label: {
                    Label("Capture", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showComposer) {
            ComposerView()
        }
        .onAppear { repository.reload() }
    }
}
