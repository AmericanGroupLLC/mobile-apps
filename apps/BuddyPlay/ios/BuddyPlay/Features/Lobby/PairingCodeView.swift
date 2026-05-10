import SwiftUI

/// Big monospaced pairing code (`BUDD-7Q2K`) for the lobby.
struct PairingCodeView: View {
    let code: String

    var body: some View {
        VStack(spacing: 8) {
            Text("Pairing code")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(code)
                .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
