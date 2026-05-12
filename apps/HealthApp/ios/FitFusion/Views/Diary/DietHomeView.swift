import SwiftUI
import FitFusionCore

/// Diet tab home matching the design-spec mockup:
///  • kcal-progress headline + "for your X" condition banner
///  • Macro tiles (protein / carbs / fat)
///  • Water tracker tile
///  • "Order nearby" vendor strip (deep-links to VendorBrowseView)
///
/// Existing `FoodDiaryView` remains the editable diary; this is the
/// at-a-glance home users land on when they tap the Diet tab.
struct DietHomeView: View {

    @StateObject private var conditions = HealthConditionsStore.shared
    @State private var showHeaderProfile = false
    @State private var showHeaderBell = false

    // Placeholder today-totals — wired to CloudStore in week 2.
    private let kcalConsumed: Int = 1420
    private let kcalGoal: Int = 1800
    private let proteinG: Int = 82
    private let carbsG: Int = 140
    private let fatG: Int = 42
    @AppStorage("diet.waterCups") private var waterCups: Int = 5
    private let waterGoal: Int = 8

    private let tint = CarePlusPalette.dietCoral

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppHeader(tab: .diet,
                          onProfile: { showHeaderProfile = true },
                          onBell: { showHeaderBell = true })

                ScrollView {
                    VStack(alignment: .leading, spacing: CarePlusSpacing.lg) {
                        kcalHeader
                        if let banner = conditionBanner { banner }
                        macroTiles
                        waterTile
                        orderNearby
                        NavigationLink {
                            FoodDiaryView()
                        } label: {
                            HStack {
                                Image(systemName: "book.closed.fill").foregroundStyle(tint)
                                Text("Open food diary").font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .padding(CarePlusSpacing.md)
                            .background(CarePlusPalette.surfaceElevated,
                                        in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
                        }.buttonStyle(.plain)
                    }
                    .padding(CarePlusSpacing.lg)
                }
            }
            .background(CarePlusPalette.surface.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showHeaderProfile) { NavigationStack { ProfileScreen() } }
            .sheet(isPresented: $showHeaderBell) {
                NewsDrawerSheet().presentationDetents([.medium, .large])
            }
        }
        .tint(tint)
    }

    private var kcalHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Today · \(kcalConsumed) / \(kcalGoal) kcal").font(CarePlusType.titleSM)
            ProgressView(value: Double(kcalConsumed), total: Double(kcalGoal))
                .tint(tint)
        }
    }

    /// Top-priority condition banner. Picks the first relevant condition
    /// from `HealthConditionsStore`. Mirrors mockup ("For your hypertension
    /// — low-sodium meals nearby").
    private var conditionBanner: AnyView? {
        let priority: [HealthCondition] = [.diabetesT2, .diabetesT1, .hypertension,
                                           .heartCondition, .kidneyIssue]
        guard let c = priority.first(where: { conditions.conditions.contains($0) }) else {
            return nil
        }
        let copy: String = {
            switch c {
            case .hypertension:     return "Low-sodium meals nearby"
            case .heartCondition:   return "Mediterranean & DASH plates"
            case .diabetesT1, .diabetesT2: return "Lower-glycemic meals nearby"
            case .kidneyIssue:      return "Low-K, low-P meals nearby"
            default:                return "Suggestions tailored to you"
            }
        }()
        return AnyView(
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("For your \(c.label.lowercased())")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint)
                    Text(copy).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(CarePlusSpacing.md)
            .background(tint.opacity(0.10),
                        in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
        )
    }

    private var macroTiles: some View {
        HStack(spacing: CarePlusSpacing.sm) {
            macroTile("Protein", "\(proteinG)g")
            macroTile("Carbs", "\(carbsG)g")
            macroTile("Fat", "\(fatG)g")
        }
    }

    private func macroTile(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(CarePlusPalette.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
    }

    private var waterTile: some View {
        HStack(spacing: 12) {
            Image(systemName: "drop.fill").foregroundStyle(CarePlusPalette.info)
            VStack(alignment: .leading, spacing: 2) {
                Text("Water").font(.headline)
                Text("\(waterCups) of \(waterGoal) cups").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                waterCups = min(waterGoal + 4, waterCups + 1)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2).foregroundStyle(CarePlusPalette.info)
            }
        }
        .padding(CarePlusSpacing.md)
        .background(CarePlusPalette.info.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
    }

    private var orderNearby: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Order nearby").font(CarePlusType.titleSM)
                Spacer()
                NavigationLink("See all") { VendorBrowseView() }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }
            VStack(spacing: 6) {
                vendorPreview("Sweetgreen", "Harvest bowl · 480 kcal")
                vendorPreview("Mendocino Farms", "Salmon plate · 540 kcal")
            }
        }
    }

    private func vendorPreview(_ name: String, _ subtitle: String) -> some View {
        NavigationLink {
            VendorBrowseView()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(CarePlusSpacing.md)
            .background(CarePlusPalette.surfaceElevated,
                        in: RoundedRectangle(cornerRadius: CarePlusRadius.md))
        }.buttonStyle(.plain)
    }
}
