import SwiftUI
import BuddyAICore

struct ProfileSetupScreen: View {
    let onContinue: () -> Void
    @EnvironmentObject private var profilesModel: ProfilesModel
    @State private var name: String = ""
    @State private var kind: Profile.Kind = .adult
    @State private var pin: String = ""
    @State private var error: String?

    var body: some View {
        Form {
            Section("Your name") {
                TextField("Name", text: $name)
            }
            Section("Profile type") {
                Picker("Kind", selection: $kind) {
                    Text("Adult (default)").tag(Profile.Kind.adult)
                    Text("Kid-Safe (PIN-locked)").tag(Profile.Kind.kidSafe)
                }
                .pickerStyle(.inline)
            }
            if kind == .kidSafe {
                Section("4-digit PIN") {
                    SecureField("PIN", text: $pin).keyboardType(.numberPad)
                    Text("You'll need this PIN to switch back to the Adult profile.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            if let error {
                Section { Text(error).foregroundStyle(.red) }
            }
            Section {
                Button("Continue") { commit() }
                    .disabled(!isValid)
            }
        }
        .navigationTitle("Set up your profile")
    }

    private var isValid: Bool {
        let nameOk = !name.trimmingCharacters(in: .whitespaces).isEmpty
        let pinOk = kind != .kidSafe || pin.count == 4
        return nameOk && pinOk
    }

    private func commit() {
        do {
            try profilesModel.add(name: name, kind: kind, pin: kind == .kidSafe ? pin : nil)
            onContinue()
        } catch {
            self.error = "\(error)"
        }
    }
}
