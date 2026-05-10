import SwiftUI
import DriftCore

struct BlockedUsersScreen: View {
    @State private var blocked: [Profile] = []

    var body: some View {
        List(blocked) { p in
            HStack {
                Text(p.displayName)
                Spacer()
                Button("Unblock") { /* DELETE /rest/v1/blocked_users */ }
            }
        }
        .navigationTitle("Blocked")
        .overlay {
            if blocked.isEmpty {
                ContentUnavailableView("Nobody blocked",
                    systemImage: "hand.raised.slash",
                    description: Text("People you block will appear here."))
            }
        }
    }
}
