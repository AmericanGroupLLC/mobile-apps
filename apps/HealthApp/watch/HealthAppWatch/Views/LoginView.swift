import SwiftUI
import FitFusionCore

struct LoginView: View {
    @EnvironmentObject var auth: AuthStore
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showRegister = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.pink)
                Text("MyHealth")
                    .font(.headline)
                Text("Sign in to your wrist hub")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .submitLabel(.next)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .submitLabel(.go)

                if let err = auth.errorMessage {
                    Text(err).font(.caption2).foregroundStyle(.red).multilineTextAlignment(.center)
                }

                Button {
                    Task { await auth.login(email: email, password: password) }
                } label: {
                    HStack {
                        if auth.loading { ProgressView().controlSize(.small) }
                        Text("Sign In").bold()
                    }.frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(email.isEmpty || password.isEmpty || auth.loading)

                Button("Create account") { showRegister = true }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
    }
}
