import SwiftUI
import FitFusionCore

/// Catch-all hub for surfaces that don't fit the 4 primary tabs.
/// Tap-through navigation; each item routes to its own NavigationStack.
struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Health") {
                    NavigationLink {
                        VitalsView()
                    } label: { Label("Vitals & Biological Age", systemImage: "waveform.path.ecg.rectangle.fill") }

                    NavigationLink {
                        RunListView()
                    } label: { Label("Runs", systemImage: "figure.run") }

                    NavigationLink {
                        NutritionView()
                    } label: { Label("Nutrition (Eat)", systemImage: "fork.knife") }
                }

                Section("Care") {
                    NavigationLink {
                        MedicineListView()
                    } label: { Label("Medicines", systemImage: "pills.fill") }

                    NavigationLink {
                        ActivityListView()
                    } label: { Label("Activities", systemImage: "figure.walk.motion") }

                    NavigationLink {
                        HealthArticlesListView()
                    } label: { Label("Health articles", systemImage: "newspaper.fill") }
                }

                Section("Social") {
                    NavigationLink {
                        SocialView()
                    } label: { Label("Friends \u{00b7} Challenges \u{00b7} Badges",
                                      systemImage: "person.2.fill") }
                }

                Section("App") {
                    NavigationLink {
                        ProfileSetupView()
                    } label: { Label("Profile", systemImage: "person.crop.circle") }

                    NavigationLink {
                        SettingsView()
                    } label: { Label("Settings", systemImage: "gear") }
                }
            }
            .navigationTitle("More")
        }
    }
}
