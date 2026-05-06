import SwiftUI
import DriftCore

struct ReportSheet: View {
    let target: Profile
    @Environment(\.dismiss) private var dismiss
    @State private var reason: String = "spam"
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Reason", selection: $reason) {
                    Text("Spam").tag("spam")
                    Text("Harassment").tag("harassment")
                    Text("Underage").tag("underage")
                    Text("Inappropriate content").tag("inappropriate")
                    Text("Other").tag("other")
                }
                TextField("Optional note (≤ 2000 chars)", text: $note, axis: .vertical)
                Button("Submit") {
                    AnalyticsService.shared.track(.reportFiled(reason: reason))
                    dismiss()
                }
            }
            .navigationTitle("Report \(target.displayName)")
        }
    }
}
