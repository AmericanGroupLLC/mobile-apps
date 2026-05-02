import SwiftUI
import FitFusionCore

struct RegisterView: View {
    @EnvironmentObject var auth: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Your details") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password (6+)", text: $password)
                }
                if let err = auth.errorMessage {
                    Section { Text(err).foregroundStyle(.red) }
                }
                Section {
                    Button {
                        Task {
                            await auth.register(name: name, email: email, password: password)
                            if auth.isAuthenticated { dismiss() }
                        }
                    } label: {
                        HStack {
                            if auth.loading { ProgressView().controlSize(.small) }
                            Text("Create Account").bold()
                        }.frame(maxWidth: .infinity)
                    }
                    .disabled(name.isEmpty || email.isEmpty || password.count < 6 || auth.loading)
                }
            }
            .navigationTitle("Sign up")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
