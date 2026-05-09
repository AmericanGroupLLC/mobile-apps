import SwiftUI

struct ToolsLauncherView: View {
    let cards: [ToolCard] = [
        .init(title: "Clock",      icon: "clock",                color: .orange),
        .init(title: "Calculator", icon: "function",             color: .indigo),
        .init(title: "Measure",    icon: "ruler",                color: .green),
        .init(title: "Compass",    icon: "location.north.line",  color: .red),
        .init(title: "Level",      icon: "level",                color: .blue)
    ]

    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(cards) { card in
                        NavigationLink(value: card) {
                            VStack(spacing: 12) {
                                Image(systemName: card.icon)
                                    .font(.system(size: 36))
                                    .foregroundColor(card.color)
                                Text(card.title).font(.headline).foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Pocket")
            .navigationDestination(for: ToolCard.self) { card in
                Group {
                    switch card.title {
                    case "Clock":      ClockHomeView()
                    case "Calculator": CalculatorView()
                    case "Measure":    MeasureView()
                    case "Compass":    CompassView()
                    case "Level":      LevelView()
                    default:           Text(card.title)
                    }
                }
                .navigationTitle(card.title)
            }
        }
    }
}

struct ToolCard: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}
