import Foundation
#if canImport(UIKit) && canImport(Vision)
import UIKit
import Vision
import CoreML

/// On-device meal-photo recognition.
///
/// Uses `VNCoreMLRequest` over a small bundled `FoodClassifier.mlmodel`
/// (\u{2248}3-5 MB) to suggest the top-5 candidate foods for a captured photo. The
/// caller (typically `MealPhotoSheet`) lets the user pick the right one which
/// then routes through the existing `NutritionService` for ground-truth
/// macros from Open Food Facts.
///
/// **Privacy:** the image is never uploaded; only the user-chosen brand /
/// food name string is sent to Open Food Facts (same as today's barcode flow).
@MainActor
public final class MealPhotoRecognizer {

    public static let shared = MealPhotoRecognizer()

    public struct Candidate: Identifiable, Hashable {
        public let id = UUID()
        public let label: String
        public let confidence: Float
    }

    private var visionModel: VNCoreMLModel?

    private init() {
        if let url = Bundle.main.url(forResource: "FoodClassifier", withExtension: "mlmodelc"),
           let core = try? MLModel(contentsOf: url),
           let vn = try? VNCoreMLModel(for: core) {
            self.visionModel = vn
        }
    }

    /// Returns up to `topK` candidate labels for the supplied photo. When the
    /// bundled classifier isn't available, returns an empty array \u{2014} the UI
    /// falls back to manual text search.
    public func classify(image: UIImage, topK: Int = 5) async -> [Candidate] {
        guard let visionModel,
              let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { cont in
            let request = VNCoreMLRequest(model: visionModel) { req, _ in
                let classifications = (req.results as? [VNClassificationObservation]) ?? []
                let candidates = classifications.prefix(topK).map {
                    Candidate(label: $0.identifier, confidence: $0.confidence)
                }
                cont.resume(returning: Array(candidates))
            }
            request.imageCropAndScaleOption = .centerCrop
            let handler = VNImageRequestHandler(cgImage: cgImage,
                                                orientation: .up,
                                                options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do { try handler.perform([request]) }
                catch { cont.resume(returning: []) }
            }
        }
    }
}
#endif
