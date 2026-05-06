import SwiftUI
import DriftCore

struct ProfileScreen: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        NavigationStack {
            if let p = session.currentProfile {
                List {
                    Section { Text(p.displayName).font(.title2) }
                    Section("Intent") { Text(p.intent.rawValue.capitalized) }
                    Section("Vibes")  { Text(p.vibeTags.joined(separator: ", ")) }
                    Section { NavigationLink("Edit profile") { EditProfileScreen() } }
                }.navigationTitle("Profile")
            } else { ProgressView() }
        }
    }
}
