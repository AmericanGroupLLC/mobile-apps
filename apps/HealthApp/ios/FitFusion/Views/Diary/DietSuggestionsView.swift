import SwiftUI
import FitFusionCore

/// Diet suggestions tailored to the user's declared conditions. Pure
/// on-device — pulls from `DietSuggestionsService.catalog`. Always shows
/// the doctor-disclaimer banner. No personal data leaves the device.
struct DietSuggestionsView: View {

    @StateObject private var conditions = HealthConditionsStore.shared

    private var suggestions: [DietSuggestion] {
        DietSuggestionsService.suggestions(for: conditions.conditions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                disclaimerBanner

                if suggestions.isEmpty {
                    Text("Declare a health condition in Settings → Health profile to get tailored guidance.")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(suggestions) { s in
                        suggestionCard(s)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Diet suggestions")
    }

    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "stethoscope")
                .foregroundStyle(.orange)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("General guidance \u{2014} not medical advice")
                    .font(.subheadline).fontWeight(.semibold)
                Text("Always confirm dietary changes with your doctor or registered dietitian, especially if you take medication or have multiple conditions.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }

    private func suggestionCard(_ s: DietSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: s.condition.symbol)
                    .foregroundStyle(.tint)
                Text(s.condition.label).font(.headline)
                Spacer()
                Text(s.pattern.label)
                    .font(.caption2).fontWeight(.semibold)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.tint.opacity(0.15),
                                in: Capsule())
            }

            Text(s.notes).font(.footnote).foregroundStyle(.secondary)

            DisclosureGroup("Foods to favor") {
                ForEach(s.prefer, id: \.self) { f in
                    Label(f, systemImage: "leaf.fill")
                        .font(.callout)
                        .foregroundStyle(.green)
                }
            }
            DisclosureGroup("Foods to limit") {
                ForEach(s.avoid, id: \.self) { f in
                    Label(f, systemImage: "xmark.octagon")
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
            DisclosureGroup("Daily targets") {
                ForEach(s.dailyTargets, id: \.self) { t in
                    Label(t, systemImage: "target")
                        .font(.callout)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack { DietSuggestionsView() }
}
