import Messages
import UIKit
import SwiftUI

/// `MSMessagesAppViewController` that renders an "Activity Card" for a finished
/// workout (image preview + headline stats), inserted into the iMessage
/// compose field. The receiver sees a rich bubble with the same gradient
/// styling MyHealth uses elsewhere (see `MirroredWorkoutView`).
class MessagesViewController: MSMessagesAppViewController {

    private var hostingController: UIHostingController<ActivityCardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        renderHost()
    }

    private func renderHost() {
        let card = ActivityCardView(workoutTitle: "Full-Body Strength",
                                    durationMin: 32,
                                    calories: 412,
                                    avgHR: 138)
        let host = UIHostingController(rootView: card)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        host.didMove(toParent: self)
        hostingController = host
    }

    func compose() {
        guard let conversation = activeConversation else { return }
        let message = MSMessage()
        let layout = MSMessageTemplateLayout()
        layout.image = renderImage()
        layout.caption = "Just finished a MyHealth workout \u{1F525}"
        layout.subcaption = "32 min \u{00b7} 412 kcal \u{00b7} 138 bpm avg"
        message.layout = layout
        conversation.insert(message) { _ in }
    }

    private func renderImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 360))
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: CGSize(width: 600, height: 360))
            UIColor.systemOrange.setFill()
            ctx.fill(rect)
            let title = "MyHealth Workout"
            (title as NSString).draw(at: CGPoint(x: 24, y: 24), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 36),
                .foregroundColor: UIColor.white,
            ])
        }
    }
}

private struct ActivityCardView: View {
    let workoutTitle: String
    let durationMin: Int
    let calories: Int
    let avgHR: Int

    var body: some View {
        VStack(spacing: 12) {
            Text("MyHealth").font(.headline).foregroundStyle(.white)
            Text(workoutTitle).font(.title2).bold().foregroundStyle(.white)
            HStack(spacing: 22) {
                stat(value: "\(durationMin)", unit: "min")
                stat(value: "\(calories)", unit: "kcal")
                stat(value: "\(avgHR)", unit: "bpm")
            }
            Text("Tap to share to iMessage")
                .font(.caption).foregroundStyle(.white.opacity(0.85))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [.orange, .pink, .purple],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private func stat(value: String, unit: String) -> some View {
        VStack {
            Text(value).font(.title3).bold().foregroundStyle(.white)
            Text(unit).font(.caption2).foregroundStyle(.white.opacity(0.85))
        }
    }
}
