import SwiftUI
import BuddyCore

struct RacerCanvasView: View {
    @ObservedObject var vm: RacerViewModel

    var body: some View {
        Canvas { context, size in
            let scaleX = size.width  / RacerPhysics.trackWidth
            let scaleY = size.height / RacerPhysics.trackHeight

            // Track background.
            let trackRect = CGRect(origin: .zero, size: size)
            context.fill(Path(trackRect), with: .color(.black.opacity(0.85)))
            context.stroke(Path(trackRect), with: .color(.white.opacity(0.4)), lineWidth: 2)

            // Cars.
            for (id, car) in vm.state.cars {
                let isLocal = (id == vm.localPlayerId)
                let color: Color = isLocal ? .accentColor : .white
                let cx = CGFloat(car.x) * scaleX
                let cy = CGFloat(car.y) * scaleY
                let body = Path(ellipseIn: CGRect(x: cx - 6, y: cy - 4, width: 12, height: 8))
                context.fill(body, with: .color(color))
                // Heading indicator.
                let nose = CGPoint(
                    x: cx + cos(car.heading) * 10,
                    y: cy + sin(car.heading) * 10
                )
                var p = Path(); p.move(to: CGPoint(x: cx, y: cy)); p.addLine(to: nose)
                context.stroke(p, with: .color(color), lineWidth: 2)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .aspectRatio(RacerPhysics.trackWidth / RacerPhysics.trackHeight, contentMode: .fit)
    }
}
