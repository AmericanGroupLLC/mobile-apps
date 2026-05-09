import SwiftUI
import DriftCore

/// 5-page onboarding container.
struct OnboardingFlowView: View {
    @EnvironmentObject private var session: AppSession
    @State private var page = 0
    @State private var phone = ""
    @State private var verifiedSelfie = false

    var body: some View {
        TabView(selection: $page) {
            WelcomeView(advance: { page = 1 }).tag(0)
            PhoneOTPView(phone: $phone, advance: { page = 2 }).tag(1)
            PhotosOnboardingView(advance: { page = 3 }).tag(2)
            SelfieView(verified: $verifiedSelfie, advance: { page = 4 }).tag(3)
            LayersIntentView(advance: { Task { await finish() } }).tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .ignoresSafeArea()
    }

    private func finish() async {
        let p = Profile(displayName: "You", intent: .dating)
        try? await ProfileService.shared.upsert(p)
        AnalyticsService.shared.track(.onboardingCompleted)
        session.onboardingFinished(profile: p)
    }
}

struct WelcomeView: View {
    let advance: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Drift").font(.system(size: 56, weight: .semibold, design: .serif))
            Text("Meet people at your pace, in your orbit.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Spacer()
            Button("Get started", action: advance).buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct PhoneOTPView: View {
    @Binding var phone: String
    let advance: () -> Void
    @State private var code = ""
    @State private var sentOTP = false
    var body: some View {
        VStack(spacing: 16) {
            Text("Phone").font(.title.bold())
            TextField("+1 415 555 0100", text: $phone).keyboardType(.phonePad)
                .textFieldStyle(.roundedBorder)
            if sentOTP {
                TextField("6-digit code", text: $code).keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Button("Verify") { Task {
                    try? await AuthService.shared.verifyOTP(phone: phone, code: code); advance() } }
                    .buttonStyle(.borderedProminent)
            } else {
                Button("Send code") {
                    Task { try? await AuthService.shared.sendOTP(toPhone: phone); sentOTP = true }
                }.buttonStyle(.borderedProminent)
            }
        }.padding()
    }
}

struct PhotosOnboardingView: View {
    let advance: () -> Void
    var body: some View {
        VStack {
            Text("Add 6 photos").font(.title.bold())
            PhotoGridEditor()
            Button("Continue", action: advance).buttonStyle(.borderedProminent)
        }.padding()
    }
}

struct SelfieView: View {
    @Binding var verified: Bool
    let advance: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Text("Verify your selfie").font(.title.bold())
            Text("We compare a fresh selfie to one of your photos via AWS Rekognition. Only the boolean result is stored.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button(verified ? "Verified" : "Take selfie") {
                Task {
                    let r = try? await VerificationService.shared.verify(selfieJpeg: Data(), comparisonPhotoId: UUID())
                    verified = r?.verified ?? false
                }
            }.buttonStyle(.borderedProminent)
            Button("Continue", action: advance).disabled(!verified)
        }.padding()
    }
}

struct LayersIntentView: View {
    let advance: () -> Void
    @State private var intent: Intent = .dating
    @State private var layers: Set<Layer> = Set(Layer.allCases)
    var body: some View {
        Form {
            Section("Intent") {
                Picker("", selection: $intent) {
                    ForEach(Intent.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
            }
            Section("Discoverable in") {
                ForEach(Layer.allCases, id: \.self) { layer in
                    Toggle(layer.rawValue.capitalized, isOn: Binding(
                        get: { layers.contains(layer) },
                        set: { on in if on { layers.insert(layer) } else { layers.remove(layer) } }
                    ))
                }
            }
            Button("Finish", action: advance).buttonStyle(.borderedProminent)
        }
    }
}
