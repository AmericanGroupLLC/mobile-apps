import SwiftUI
import FitFusionCore

struct SleepRecoveryView: View {
    @EnvironmentObject var hk: iOSHealthKitManager
    @State private var sleep: iOSHealthKitManager.SleepSnapshot?
    @State private var recovery: RecoveryService.Recovery?
    @State private var showWindDown = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let r = recovery {
                        RecoveryScoreView(recovery: r)
                    }
                    if let s = sleep {
                        SleepStagesChart(snapshot: s)
                    } else {
                        ContentUnavailableView(
                            "No sleep data yet",
                            systemImage: "moon.zzz",
                            description: Text("Sleep with your Apple Watch overnight to see stages and recovery here.")
                        )
                    }

                    Button {
                        showWindDown = true
                    } label: {
                        Label("Wind Down · Mindful Session", systemImage: "leaf.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.indigo, .purple],
                                                       startPoint: .leading, endPoint: .trailing),
                                        in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.white)
                    }
                }
                .padding()
            }
            .navigationTitle("Sleep & Recovery")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await refresh() } } label: { Image(systemName: "arrow.clockwise") }
                }
            }
            .sheet(isPresented: $showWindDown) {
                WindDownSheet().presentationDetents([.medium, .large])
            }
            .task { await refresh() }
            .refreshable { await refresh() }
        }
    }

    private func refresh() async {
        sleep = try? await hk.fetchLastNightSleep()
        recovery = try? await RecoveryService.shared.compute(using: hk)
    }
}
