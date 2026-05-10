import SwiftUI
import FitFusionCore

struct RegisterView: View {
    @EnvironmentObject var auth: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Create Account").font(.headline)

                TextField("Name", text: $name)
                TextField("Email", text: $email).textContentType(.emailAddress)
                SecureField("Password (6+)", text: $password)

                if let err = auth.errorMessage {
                    Text(err).font(.caption2).foregroundStyle(.red).multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await auth.register(name: name, email: email, password: password)
                        if auth.isAuthenticated { dismiss() }
                    }
                } label: {
                    HStack {
                        if auth.loading { ProgressView().controlSize(.small) }
                        Text("Sign Up").bold()
                    }.frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(name.isEmpty || email.isEmpty || password.count < 6 || auth.loading)

                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
