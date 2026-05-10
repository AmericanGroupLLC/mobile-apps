import SwiftUI
import FitFusionCore

/// Settings → Health Profile. Lets the user declare opt-in conditions so the
/// app filters unsafe workouts and tunes diet suggestions. Always shows the
/// doctor-disclaimer banner. Data stays on-device.
struct HealthProfileView: View {

    @StateObject private var store = HealthConditionsStore.shared
    @State private var showDoctorReminder = false

    var body: some View {
        Form {
            Section {
                Label {
                    Text("Always check with your doctor before starting a new workout or diet plan, especially if you have a declared condition.")
                        .font(.footnote)
                } icon: {
                    Image(systemName: "stethoscope")
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Medical disclaimer")
            } footer: {
                if store.doctorReviewIsStale {
                    Text("It's been a while since you confirmed this list with a doctor. Consider reviewing it.")
                        .foregroundStyle(.orange)
                        .font(.caption2)
                }
            }

            Section("Cardiovascular") {
                conditionRow(.hypertension)
                conditionRow(.lowBloodPressure)
                conditionRow(.heartCondition)
            }
            Section("Metabolic") {
                conditionRow(.diabetesT1)
                conditionRow(.diabetesT2)
                conditionRow(.obesity)
            }
            Section("Respiratory") {
                conditionRow(.asthma)
            }
            Section("Musculoskeletal / injuries") {
                conditionRow(.kneeInjury)
                conditionRow(.ankleInjury)
                conditionRow(.shoulderInjury)
                conditionRow(.backPain)
                conditionRow(.osteoporosis)
            }
            Section("Other") {
                conditionRow(.pregnancy)
                conditionRow(.kidneyIssue)
                conditionRow(.liverIssue)
                conditionRow(.anemia)
            }
            Section("None") {
                Toggle(isOn: Binding(
                    get: { store.conditions == [.none] },
                    set: { _ in store.toggle(.none) }
                )) {
                    Label("No conditions to declare", systemImage: HealthCondition.none.symbol)
                }
            }

            Section("Doctor review") {
                Button {
                    store.markReviewedWithDoctor()
                    showDoctorReminder = true
                } label: {
                    Label("I checked this list with my doctor", systemImage: "checkmark.seal")
                }
                if let last = store.lastDoctorReview {
                    Text("Last reviewed: \(last.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }

            if store.hasAnyCondition {
                Section("What this changes") {
                    Label("Suggested workouts will skip exercises that conflict with your conditions",
                          systemImage: "figure.strengthtraining.traditional")
                    Label("Diet suggestions tab shows guidance tailored to each condition",
                          systemImage: "fork.knife")
                    Label("All filtering happens on-device — never uploaded",
                          systemImage: "lock.shield")
                }
            }
        }
        .navigationTitle("Health profile")
        .alert("Saved", isPresented: $showDoctorReminder) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("We'll remind you to re-check this list in 6 months.")
        }
    }

    @ViewBuilder
    private func conditionRow(_ c: HealthCondition) -> some View {
        Toggle(isOn: Binding(
            get: { store.conditions.contains(c) },
            set: { _ in store.toggle(c) }
        )) {
            Label(c.label, systemImage: c.symbol)
        }
    }
}

#Preview {
    NavigationStack { HealthProfileView() }
}
