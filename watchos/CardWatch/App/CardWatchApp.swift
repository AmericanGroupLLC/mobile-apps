import SwiftUI
import CardCore

@main
struct CardWatchApp: App {
    @StateObject private var repository = WatchCardRepository.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                FeedView()
                    .navigationTitle("Card")
            }
            .environmentObject(repository)
        }
    }
}
