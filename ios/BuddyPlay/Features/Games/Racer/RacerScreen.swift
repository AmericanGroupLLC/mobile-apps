import SwiftUI
import BuddyCore

struct RacerScreen: View {
    @StateObject private var vm: RacerViewModel
    @Environment(\.dismiss) private var dismiss

    init(host: Peer, guest: Peer, localPlayerId: UUID, transport: Transport) {
        _vm = StateObject(wrappedValue: RacerViewModel(
            host: host, guest: guest, localPlayerId: localPlayerId, transport: transport
        ))
    }

    var body: some View {
        VStack(spacing: 16) {
            if let reject = vm.rejectMessage {
                rejectBanner(reject)
            } else {
                RacerCanvasView(vm: vm)
                controls
            }
        }
        .padding(16)
        .navigationTitle("Mini Racer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.startTicking() }
        .onDisappear { vm.stopTicking() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Quit", role: .destructive) { dismiss() }
            }
        }
    }

    private func rejectBanner(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("Mini Racer needs Wi-Fi or Hotspot")
                .font(.headline)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Back to lobby") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(20)
    }

    private var controls: some View {
        HStack(spacing: 24) {
            steeringPad
            Spacer()
            VStack(spacing: 12) {
                Button(action: { vm.setThrottle(1) }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 56))
                }
                .simultaneousGesture(DragGesture(minimumDistance: 0)
                    .onEnded { _ in vm.setThrottle(0) })
                Button(action: { vm.setBrake(1) }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.red)
                }
                .simultaneousGesture(DragGesture(minimumDistance: 0)
                    .onEnded { _ in vm.setBrake(0) })
            }
        }
    }

    private var steeringPad: some View {
        HStack(spacing: 12) {
            Button(action: { vm.setSteering(-1) }) {
                Image(systemName: "arrow.left.circle.fill").font(.system(size: 56))
            }
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onEnded { _ in vm.setSteering(0) })
            Button(action: { vm.setSteering(1) }) {
                Image(systemName: "arrow.right.circle.fill").font(.system(size: 56))
            }
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onEnded { _ in vm.setSteering(0) })
        }
    }
}
