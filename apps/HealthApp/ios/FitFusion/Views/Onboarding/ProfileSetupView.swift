import SwiftUI
import FitFusionCore

/// Edit-anytime profile screen. Reads/writes the on-device `ProfileEntity`
/// via `CloudStore`. Powers Biological Age input + readiness fallbacks.
struct ProfileSetupView: View {
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var sex: ProfileSex = .female
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 65
    @State private var goal: HealthGoal = .maintain
    @State private var unitsImperial = false
    @State private var savedToast = false

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                DatePicker("Date of birth", selection: $birthDate, displayedComponents: .date)
                Picker("Sex", selection: $sex) {
                    ForEach(ProfileSex.allCases) { Text($0.label).tag($0) }
                }
            }
            Section("Body") {
                Stepper(value: $heightCm, in: 120...220, step: 1) {
                    Text("Height: \(Int(heightCm)) cm")
                }
                Stepper(value: $weightKg, in: 30...200, step: 0.5) {
                    Text(String(format: "Weight: %.1f kg", weightKg))
                }
                Toggle("Imperial units", isOn: $unitsImperial)
            }
            Section("Goal") {
                Picker("Primary goal", selection: $goal) {
                    ForEach(HealthGoal.allCases) { Text($0.label).tag($0) }
                }
            }
            Section {
                Button {
                    save()
                    savedToast = true
                } label: {
                    Label("Save profile", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Saved", isPresented: $savedToast) {
            Button("OK", role: .cancel) {}
        }
        .onAppear { load() }
    }

    private func load() {
        guard let p = CloudStore.shared.fetchProfile() else { return }
        if let n = p.value(forKey: "name") as? String { name = n }
        if let dob = p.value(forKey: "birthDateISO") as? String,
           let parsed = ISO8601DateFormatter().date(from: dob) { birthDate = parsed }
        if let s = p.value(forKey: "sex") as? String,
           let parsed = ProfileSex(rawValue: s) { sex = parsed }
        if let h = p.value(forKey: "heightCm") as? Double { heightCm = h }
        if let w = p.value(forKey: "weightKg") as? Double { weightKg = w }
        if let g = p.value(forKey: "goal") as? String,
           let parsed = HealthGoal(rawValue: g) { goal = parsed }
        if let u = p.value(forKey: "unitsImperial") as? Bool { unitsImperial = u }
    }

    private func save() {
        CloudStore.shared.saveProfile(
            name: name,
            birthDateISO: ISO8601DateFormatter().string(from: birthDate),
            sex: sex.rawValue,
            heightCm: heightCm,
            weightKg: weightKg,
            goal: goal.rawValue,
            unitsImperial: unitsImperial
        )
    }
}
