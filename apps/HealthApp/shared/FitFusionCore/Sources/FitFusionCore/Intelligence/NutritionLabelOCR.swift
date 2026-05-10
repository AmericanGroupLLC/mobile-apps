import Foundation
#if canImport(UIKit) && canImport(Vision)
import UIKit
import Vision

/// On-device nutrition-label OCR.
///
/// Uses `VNRecognizeTextRequest` (Vision's built-in text recognizer \u{2014} no model
/// download required) and a small regex pipeline to extract calories, protein,
/// carbohydrate, fat and (optionally) a UPC barcode from a photographed
/// nutrition label. When a UPC is detected, the caller can fall back to
/// `NutritionService.lookup(barcode:)` for an authoritative entry.
///
/// **Privacy:** all OCR runs locally; the image is never uploaded.
@MainActor
public final class NutritionLabelOCR {

    public static let shared = NutritionLabelOCR()
    private init() {}

    public struct Result: Sendable {
        public var kcal: Double?
        public var proteinG: Double?
        public var carbsG: Double?
        public var fatG: Double?
        public var detectedBarcode: String?
        public var rawText: String

        public init(kcal: Double? = nil, proteinG: Double? = nil,
                    carbsG: Double? = nil, fatG: Double? = nil,
                    detectedBarcode: String? = nil, rawText: String = "") {
            self.kcal = kcal
            self.proteinG = proteinG
            self.carbsG = carbsG
            self.fatG = fatG
            self.detectedBarcode = detectedBarcode
            self.rawText = rawText
        }
    }

    public func parse(image: UIImage) async -> Result {
        guard let cgImage = image.cgImage else { return .init() }
        return await withCheckedContinuation { cont in
            let request = VNRecognizeTextRequest { req, _ in
                let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                let joined = lines.joined(separator: "\n")
                cont.resume(returning: Self.extract(from: joined))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage,
                                                orientation: .up,
                                                options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do { try handler.perform([request]) }
                catch { cont.resume(returning: .init(rawText: "")) }
            }
        }
    }

    static func extract(from text: String) -> Result {
        var result = Result(rawText: text)
        let lower = text.lowercased()

        result.kcal     = firstNumber(near: ["calories", "energy", "kcal"], in: lower)
        result.proteinG = firstNumber(near: ["protein"], in: lower)
        result.carbsG   = firstNumber(near: ["carbohydrate", "carbs", "total carb"], in: lower)
        result.fatG     = firstNumber(near: ["total fat", "fat"], in: lower)

        // UPC: 8\u{2013}14 consecutive digits.
        if let range = lower.range(of: #"\b\d{8,14}\b"#, options: .regularExpression) {
            result.detectedBarcode = String(lower[range])
        }
        return result
    }

    /// Find the first number that follows any of the supplied keywords on the
    /// same physical line of the OCR output. Tolerates units like "g", "kcal".
    private static func firstNumber(near keywords: [String], in text: String) -> Double? {
        let lines = text.split(separator: "\n")
        for line in lines {
            let l = line.lowercased()
            guard keywords.contains(where: { l.contains($0) }) else { continue }
            if let range = l.range(of: #"[-+]?\d+(?:[.,]\d+)?"#, options: .regularExpression) {
                let raw = l[range].replacingOccurrences(of: ",", with: ".")
                return Double(raw)
            }
        }
        return nil
    }
}
#endif
