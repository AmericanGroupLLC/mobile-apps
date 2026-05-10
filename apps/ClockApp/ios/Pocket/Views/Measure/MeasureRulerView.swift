import SwiftUI

struct MeasureRulerView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("AR not available — on-screen ruler")
                .font(.subheadline).foregroundColor(.secondary)
            GeometryReader { geo in
                Canvas { ctx, size in
                    let stepPts: CGFloat = 28.346  // ~1 cm at 72 dpi (rough; calibration in Settings)
                    var x: CGFloat = 0
                    var cm = 0
                    while x <= size.width {
                        let isMajor = (cm % 5) == 0
                        let h: CGFloat = isMajor ? 30 : 16
                        ctx.stroke(
                            Path { p in
                                p.move(to: .init(x: x, y: 0))
                                p.addLine(to: .init(x: x, y: h))
                            },
                            with: .color(.primary), lineWidth: isMajor ? 1.5 : 0.8
                        )
                        if isMajor {
                            ctx.draw(Text("\(cm)").font(.caption2),
                                     at: .init(x: x + 6, y: h - 8))
                        }
                        x += stepPts
                        cm += 1
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding()
    }
}
