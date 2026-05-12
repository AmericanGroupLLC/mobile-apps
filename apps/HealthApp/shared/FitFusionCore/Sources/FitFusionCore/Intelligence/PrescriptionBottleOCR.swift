import Foundation
#if canImport(UIKit) && canImport(Vision)
import UIKit
import Vision

/// On-device prescription-bottle OCR. Snap the front label of a US
/// prescription bottle → extract drug name (top line), strength
/// ("500 mg"), dosage instructions ("Take 1 tablet by mouth twice
/// daily"), prescriber, and refills count. Pre-fills `AddMedicineView`.
///
/// Image stays on-device. Parsed values land in `MedicineEntity`
/// through the existing CloudStore path.
@MainActor
public final class PrescriptionBottleOCR {

    public static let shared = PrescriptionBottleOCR()
    private init() {}

    public struct Result: Sendable {
        public var drugName: String?
        public var strength: String?       // e.g. "500 mg"
        public var instructions: String?   // sig
        public var prescriber: String?
        public var refillsRemaining: Int?
        public var rxNumber: String?
        public var rawText: String

        public init(rawText: String = "") { self.rawText = rawText }
    }

    public func parse(image: UIImage) async -> Result {
        guard let cg = image.cgImage else { return .init() }
        let raw = await ocr(cg)
        return await Self.extract(from: raw)
    }

    public static func extract(from text: String) async -> Result {
        var r = Result(rawText: text)
        // Drug name: first non-numeric line of meaningful length, often
        // in ALL-CAPS on the printed label.
        r.drugName = text.split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .first(where: { $0.count > 3 && $0.contains(where: \.isLetter) && !$0.contains(where: \.isNumber) })

        let extractor = StructuredExtractorRegistry.shared
        let map = await extractor.extract(text: text, schema: schema)
        r.strength = map["strength"] ?? nil
        r.instructions = map["instructions"] ?? nil
        r.prescriber = map["prescriber"] ?? nil
        r.rxNumber = map["rx"] ?? nil
        if let rf = map["refills"] ?? nil {
            r.refillsRemaining = Int(rf.trimmingCharacters(in: .whitespaces))
        }
        return r
    }

    private static let schema: [Field] = [
        Field(name: "strength",
              keywords: [""], // no keyword — pulled by pattern alone via fallback below
              valuePattern: #"\d+\s*(mg|mcg|g|ml)"#),
        Field(name: "instructions",
              keywords: ["take ", "use ", "apply ", "inject ", "instill "],
              valuePattern: #".+"#),
        Field(name: "prescriber",
              keywords: ["dr.", "dr ", "prescriber", "rx by"],
              valuePattern: #"[A-Za-z .\-,]{2,40}"#),
        Field(name: "refills",
              keywords: ["refills:", "refills ", "refill"],
              valuePattern: #"\d+"#),
        Field(name: "rx",
              keywords: ["rx#", "rx #", "rx:"],
              valuePattern: #"\d{6,12}"#),
    ]

    private func ocr(_ cg: CGImage) async -> String {
        await withCheckedContinuation { cont in
            let req = VNRecognizeTextRequest { req, _ in
                let lines = ((req.results as? [VNRecognizedTextObservation]) ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                cont.resume(returning: lines.joined(separator: "\n"))
            }
            req.recognitionLevel = .accurate
            req.usesLanguageCorrection = true
            let h = VNImageRequestHandler(cgImage: cg, orientation: .up, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do { try h.perform([req]) } catch { cont.resume(returning: "") }
            }
        }
    }
}
#endif
