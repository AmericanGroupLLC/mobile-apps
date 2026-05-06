import SwiftUI
import BuddyAICore

struct ModelDownloadScreen: View {
    let onDone: () -> Void
    @EnvironmentObject private var llama: LlamaService
    @State private var progress: Double = 0
    @State private var error: String?
    @State private var downloading = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "icloud.and.arrow.down").font(.system(size: 64))
            Text("Downloading the language model").font(.title2).bold()
            Text("Approximately 1 GB. Wi-Fi only.").foregroundStyle(.secondary)
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .padding(.horizontal, 32)
            Text("\(Int(progress * 100))%")
            if let error {
                Text(error).foregroundStyle(.red).font(.footnote).multilineTextAlignment(.center)
            }
            Spacer()
            if !downloading {
                Button("Start download") { Task { await start() } }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .task {
            // Skip the download flow if a model is already on disk
            // (happens in dev builds via scripts/fetch-models.sh).
            if llama.modelLoaded { onDone() }
        }
    }

    private func start() async {
        downloading = true
        let downloader = ModelDownloader(manifest: llama.manifest, store: llama.store)
        do {
            _ = try await downloader.download { p in
                Task { @MainActor in self.progress = p.fraction }
            }
            await llama.warmupIfModelPresent()
            onDone()
        } catch {
            self.error = "\(error)"
            downloading = false
        }
    }
}
