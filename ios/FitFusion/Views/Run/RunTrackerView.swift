import SwiftUI
import FitFusionCore

struct RunTrackerView: View {
    var body: some View {
        NavigationStack {
            RunListView()
                .navigationTitle("Runs")
        }
    }
}
