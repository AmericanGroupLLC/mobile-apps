import SwiftUI
import DriftCore

struct MessageBubble: View {
    let message: Message
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 40) }
            Text(message.text)
                .padding(10)
                .background(isMine ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 12))
                .foregroundColor(.primary)
            if !isMine { Spacer(minLength: 40) }
        }
    }
}
