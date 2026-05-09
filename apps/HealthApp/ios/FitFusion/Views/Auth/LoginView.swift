import SwiftUI
import FitFusionCore

struct LoginView: View {
    @EnvironmentObject var auth: AuthStore
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerArt
                        .padding(.top, 40)

                    VStack(spacing: 14) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                        if let err = auth.errorMessage {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            Task { await auth.login(email: email, password: password) }
                        } label: {
                            HStack {
                                if auth.loading { ProgressView().controlSize(.small).tint(.white) }
                                Text("Sign In").bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing),
                                        in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                        }
                        .disabled(email.isEmpty || password.isEmpty || auth.loading)

                        Button("Create an account") { showRegister = true }
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Divider().padding(.vertical, 4)

                        Button {
                            auth.continueAsGuest()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                Text("Continue as Guest").bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.indigo)
                        }
                        Text("No account, no email \u{2014} everything stays on this device. You can sign in for cloud sync later from Settings.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .sheet(isPresented: $showRegister) { RegisterView() }
        }
    }

    private var headerArt: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.orange, .pink, .purple],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 96, height: 96)
                Image(systemName: "flame.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text("MyHealth").font(.largeTitle).fontWeight(.heavy)
            Text("Your Personal Fitness OS")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
