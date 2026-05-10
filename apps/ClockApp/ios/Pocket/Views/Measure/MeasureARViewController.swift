import UIKit
import ARKit
import SceneKit

final class MeasureARViewController: UIViewController, ARSCNViewDelegate {
    var onDistance: ((Double?) -> Void)?

    private let sceneView = ARSCNView()
    private var startNode: SCNNode?
    private var endNode: SCNNode?
    private var lineNode: SCNNode?

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.frame = view.bounds
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.delegate = self
        view.addSubview(sceneView)

        let crosshair = UILabel()
        crosshair.text = "+"
        crosshair.font = .systemFont(ofSize: 40)
        crosshair.textColor = .white
        crosshair.sizeToFit()
        crosshair.center = view.center
        crosshair.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        view.addSubview(crosshair)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let cfg = ARWorldTrackingConfiguration()
        cfg.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(cfg)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    @objc private func handleTap() {
        let center = view.center
        guard let query = sceneView.raycastQuery(from: center, allowing: .estimatedPlane, alignment: .any),
              let result = sceneView.session.raycast(query).first else { return }

        let pos = SCNVector3(result.worldTransform.columns.3.x,
                             result.worldTransform.columns.3.y,
                             result.worldTransform.columns.3.z)

        if startNode == nil {
            startNode = makeMarker(at: pos)
            sceneView.scene.rootNode.addChildNode(startNode!)
            endNode?.removeFromParentNode(); endNode = nil
            lineNode?.removeFromParentNode(); lineNode = nil
            onDistance?(nil)
        } else if endNode == nil {
            endNode = makeMarker(at: pos)
            sceneView.scene.rootNode.addChildNode(endNode!)
            if let s = startNode?.position {
                let dx = Double(pos.x - s.x), dy = Double(pos.y - s.y), dz = Double(pos.z - s.z)
                let d = (dx * dx + dy * dy + dz * dz).squareRoot()
                onDistance?(d)
            }
        } else {
            // reset
            startNode?.removeFromParentNode(); startNode = nil
            endNode?.removeFromParentNode(); endNode = nil
            lineNode?.removeFromParentNode(); lineNode = nil
            onDistance?(nil)
        }
    }

    private func makeMarker(at pos: SCNVector3) -> SCNNode {
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.systemGreen
        let n = SCNNode(geometry: sphere)
        n.position = pos
        return n
    }
}
