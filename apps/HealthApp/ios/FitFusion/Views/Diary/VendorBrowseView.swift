import SwiftUI
import FitFusionCore

/// Diet → Vendor browse. Fetches the sample vendor list from the backend
/// filtered by the user's declared HealthConditionsStore set.
struct VendorBrowseView: View {

    @StateObject private var conditions = HealthConditionsStore.shared
    @State private var vendors: [VendorClient.Vendor] = []
    @State private var loading = true
    @State private var error: String?

    private let tint = CarePlusPalette.dietCoral

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CarePlusSpacing.md) {
                Text("Meal vendors").font(CarePlusType.title)
                Text(filterSummary).font(.caption).foregroundStyle(.secondary)

                if loading { ProgressView("Loading…").padding() }
                if let err = error {
                    Text(err).font(.caption).foregroundStyle(CarePlusPalette.danger)
                }

                ForEach(vendors) { v in
                    NavigationLink {
                        ComingSoon(title: v.name, symbol: "fork.knife", tint: tint, etaWeek: 2)
                    } label: {
                        vendorRow(v)
                    }.buttonStyle(.plain)
                }
            }
            .padding(CarePlusSpacing.lg)
        }
        .navigationTitle("Vendors")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private var filterSummary: String {
        let cond = conditions.conditions.filter { $0 != .none }.map(\.label)
        return cond.isEmpty
            ? "Showing all vendors. Declare conditions in Profile to filter."
            : "Filtered for: " + cond.joined(separator: ", ")
    }

    private func vendorRow(_ v: VendorClient.Vendor) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(tint.opacity(0.14)).frame(width: 48, height: 48)
                Image(systemName: "fork.knife").foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(v.name).font(.headline)
                Text(v.cuisine ?? "—").font(.caption).foregroundStyle(.secondary)
                if let c = v.calories_per_meal_avg {
                    Text("\(c) kcal avg").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(CarePlusPalette.surfaceElevated, in: RoundedRectangle(cornerRadius: 12))
    }

    private func load() async {
        loading = true; defer { loading = false }
        let names = conditions.conditions.filter { $0 != .none }.map(\.rawValue)
        do {
            self.vendors = try await VendorClient.shared.menu(conditions: names)
            self.error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
