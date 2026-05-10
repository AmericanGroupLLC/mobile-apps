import SwiftUI
import BuddyAICore

@main
struct OfflineAIBuddyApp: App {

    @StateObject private var bootstrap = AppBootstrap()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(bootstrap)
                .environmentObject(bootstrap.llamaService)
                .environmentObject(bootstrap.profilesModel)
                .environmentObject(bootstrap.entitlement)
                .environmentObject(bootstrap.quotaService)
                .environmentObject(bootstrap.voiceService)
        }
    }
}

/// Single composition root. Wires the BuddyAICore actors + services
/// together. v1.1 may switch to a real DI container; v1's surface is
/// small enough that an `@StateObject` graph is fine.
@MainActor
final class AppBootstrap: ObservableObject {
    let llamaService: LlamaService
    let profilesModel: ProfilesModel
    let entitlement: EntitlementBootstrap
    let quotaService: QuotaService
    let voiceService: VoiceService
    let keyboardBridge: KeyboardBridge

    init() {
        let manifest = ModelManifest.defaultV1
        let store = try! ModelStore()
        let runner = LlamaRunner(backend: StubLlamaBackend(), manifest: manifest)
        self.llamaService = LlamaService(runner: runner, store: store, manifest: manifest)
        self.profilesModel = ProfilesModel()
        self.entitlement = EntitlementBootstrap()
        self.quotaService = QuotaService()
        self.voiceService = VoiceService()
        self.keyboardBridge = KeyboardBridge(llama: llamaService)
        keyboardBridge.startListening()
    }
}
