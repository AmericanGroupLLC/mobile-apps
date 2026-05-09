import SwiftUI
import FitFusionCore

struct WorkoutLibraryView: View {
    @State private var category: WorkoutCategory? = nil
    @State private var level: WorkoutLevel? = nil

    var filtered: [WorkoutTemplate] {
        WorkoutLibrary.templates.filter { t in
            (category == nil || t.category == category) &&
            (level == nil || t.level == level)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                filterRow
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filtered) { template in
                        NavigationLink {
                            WorkoutDetailView(template: template)
                        } label: {
                            WorkoutCard(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }

    private var filterRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    chip("All", selected: category == nil) { category = nil }
                    ForEach(WorkoutCategory.allCases) { c in
                        chip(c.label, selected: category == c) { category = (category == c ? nil : c) }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    chip("Any level", selected: level == nil) { level = nil }
                    ForEach(WorkoutLevel.allCases) { l in
                        chip(l.label, selected: level == l) { level = (level == l ? nil : l) }
                    }
                }
            }
        }
    }

    private func chip(_ text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.footnote).bold()
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(selected ? AnyShapeStyle(LinearGradient(colors: [.orange, .pink],
                                                                     startPoint: .leading, endPoint: .trailing))
                                     : AnyShapeStyle(.regularMaterial),
                            in: Capsule())
                .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

private struct WorkoutCard: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
                .padding(8)
                .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
            Text(template.name).font(.headline).lineLimit(2)
            Text(template.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            HStack(spacing: 8) {
                Label("\(template.durationMin) min", systemImage: "clock")
                Label(template.level.label, systemImage: "chart.bar.fill")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var color: Color {
        switch template.category {
        case .strength: return .blue
        case .cardio:   return .red
        case .yoga:     return .purple
        case .mobility: return .green
        }
    }

    private var icon: String {
        switch template.category {
        case .strength: return "dumbbell.fill"
        case .cardio:   return "bolt.heart.fill"
        case .yoga:     return "figure.mind.and.body"
        case .mobility: return "figure.flexibility"
        }
    }
}
