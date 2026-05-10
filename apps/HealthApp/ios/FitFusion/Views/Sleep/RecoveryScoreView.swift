import SwiftUI
import FitFusionCore

struct RecoveryScoreView: View {
    let recovery: RecoveryService.Recovery

    var body: some View {
        VStack(spacing: 12) {
            Text("Recovery").font(.headline).frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.18), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: CGFloat(recovery.score) / 100)
                    .stroke(LinearGradient(colors: gradientColors,
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: recovery.score)
                VStack {
                    Text("\(recovery.score)").font(.system(size: 46, weight: .heavy, design: .rounded))
                    Text("/100").font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(width: 160, height: 160)

            Text(recovery.suggestion).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                tile("HRV", value: recovery.hrvAvg.map { String(format: "%.0f ms", $0) } ?? "—")
                tile("RHR", value: recovery.restingHr.map { "\(Int($0)) bpm" } ?? "—")
                tile("Sleep", value: recovery.sleepHours.map { String(format: "%.1f h", $0) } ?? "—")
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var gradientColors: [Color] {
        switch recovery.score {
        case ..<40: return [.red, .orange]
        case ..<70: return [.yellow, .orange]
        default:    return [.green, .mint]
        }
    }

    private func tile(_ title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline).bold()
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 50)
    }
}
