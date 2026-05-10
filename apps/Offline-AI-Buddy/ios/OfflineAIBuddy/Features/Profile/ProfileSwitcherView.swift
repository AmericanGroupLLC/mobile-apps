import SwiftUI
import BuddyAICore

struct ProfileSwitcherView: View {
    @EnvironmentObject private var profilesModel: ProfilesModel
    @State private var pinPromptingFor: Profile?

    var body: some View {
        NavigationStack {
            List {
                ForEach(profilesModel.profiles) { p in
                    Button {
                        select(p)
                    } label: {
                        HStack {
                            Image(systemName: p.kind == .adult ? "person.fill" : "figure.child")
                            Text(p.name)
                            Spacer()
                            if p.id == profilesModel.activeProfileId {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profiles")
            .sheet(item: $pinPromptingFor) { p in
                PinPromptView(profile: p) { pin in
                    if profilesModel.verify(pin: pin, for: p) {
                        profilesModel.setActive(p)
                        pinPromptingFor = nil
                    }
                }
            }
        }
    }

    private func select(_ p: Profile) {
        let active = profilesModel.activeProfile
        // Switching from Kid → Adult requires the PIN of the *currently
        // active* Kid profile.
        if active?.kind == .kidSafe && p.kind == .adult {
            pinPromptingFor = active
        } else {
            profilesModel.setActive(p)
        }
    }
}
