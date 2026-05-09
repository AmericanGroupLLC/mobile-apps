import SwiftUI
import CardCore

struct CardRow: View {
    @EnvironmentObject private var repository: CardRepository
    @EnvironmentObject private var settings: SettingsModel
    let card: Card

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if card.kind == .task {
                Button {
                    repository.toggleCompleted(card)
                } label: {
                    Image(systemName: card.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(card.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(card.isCompleted ? "Mark task as not done" : "Mark task as done")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(card.text)
                    .strikethrough(card.isCompleted, color: .secondary)
                    .foregroundStyle(card.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    KindChip(kind: card.kind)
                    if card.kind == .reminder, let at = card.reminderAt {
                        Label(at.formatted(.dateTime.month().day()
                                .hour(.defaultDigits(amPM: settings.use24Hour ? .omitted : .narrow))
                                .minute()),
                              systemImage: "bell")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct KindChip: View {
    let kind: CardKind
    var body: some View {
        Text(label.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
    private var label: String {
        switch kind { case .note: "note"; case .task: "task"; case .reminder: "reminder" }
    }
    private var color: Color {
        switch kind { case .note: .gray; case .task: .blue; case .reminder: .orange }
    }
}
