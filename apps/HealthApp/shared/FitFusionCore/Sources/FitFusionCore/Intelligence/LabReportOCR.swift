import Foundation
#if canImport(UIKit) && canImport(Vision)
import UIKit
import Vision

/// On-device lab report OCR. Snap a printed lab summary (Quest, LabCorp,
/// Kaiser) → extract the values Care+ surfaces in the per-condition
/// CarePlanCard: A1C, fasting glucose, BP systolic/diastolic, total
/// cholesterol, LDL, HDL, triglycerides, BMI, weight.
///
/// Same Vision pipeline as `NutritionLabelOCR` and `InsuranceCardOCR`;
/// new shape only differs in the schema fed to `StructuredExtractor`.
@MainActor
public final class LabReportOCR {

    public static let shared = LabReportOCR()
    private init() {}

    public struct Result: Sendable {
        public var a1c: Double?
        public var fastingGlucose: Double?
        public var bpSystolic: Int?
        public var bpDiastolic: Int?
        public var cholesterolTotal: Double?
        public var ldl: Double?
        public var hdl: Double?
        public var triglycerides: Double?
        public var bmi: Double?
        public var weightKg: Double?
        public var rawText: String

        public init(rawText: String = "") { self.rawText = rawText }
    }

    public func parse(image: UIImage) async -> Result {
        guard let cg = image.cgImage else { return .init() }
        let raw = await ocr(cg)
        return await Self.extract(from: raw)
    }

    /// Pure-function extraction so it's unit-testable from text fixtures.
    public static func extract(from text: String) async -> Result {
        let extractor = StructuredExtractorRegistry.shared
        let map = await extractor.extract(text: text, schema: schema)
        var r = Result(rawText: text)
        r.a1c = double(map["a1c"] ?? nil)
        r.fastingGlucose = double(map["fastingGlucose"] ?? nil)
        r.cholesterolTotal = double(map["cholesterol"] ?? nil)
        r.ldl = double(map["ldl"] ?? nil)
        r.hdl = double(map["hdl"] ?? nil)
        r.triglycerides = double(map["triglycerides"] ?? nil)
        r.bmi = double(map["bmi"] ?? nil)
        r.weightKg = double(map["weight"] ?? nil)
        if let bp = map["bp"] ?? nil {
            // Expect "138/88" style.
            let parts = bp.split(separator: "/")
            if parts.count == 2 {
                r.bpSystolic = Int(parts[0].trimmingCharacters(in: .whitespaces))
                r.bpDiastolic = Int(parts[1].trimmingCharacters(in: .whitespaces))
            }
        }
        return r
    }

    private static let schema: [Field] = [
        Field(name: "a1c",
              keywords: ["a1c", "hba1c", "hemoglobin a1c"],
              valuePattern: #"\d+\.\d+"#),
        Field(name: "fastingGlucose",
              keywords: ["fasting glucose", "fasting blood sugar", "fbg", "glucose"],
              valuePattern: #"\d+(\.\d+)?"#),
        Field(name: "bp",
              keywords: ["bp", "blood pressure"],
              valuePattern: #"\d{2,3}\s*/\s*\d{2,3}"#),
        Field(name: "cholesterol",
              keywords: ["total cholesterol", "cholesterol total", "tc:"],
              valuePattern: #"\d+(\.\d+)?"#),
        Field(name: "ldl",
              keywords: ["ldl"],
              valuePattern: #"\d+(\.\d+)?"#),
        Field(name: "hdl",
              keywords: ["hdl"],
              valuePattern: #"\d+(\.\d+)?"#),
        Field(name: "triglycerides",
              keywords: ["triglycerides", "tg:"],
              valuePattern: #"\d+(\.\d+)?"#),
        Field(name: "bmi",
              keywords: ["bmi"],
              valuePattern: #"\d+(\.\d+)?"#),
        Field(name: "weight",
              keywords: ["weight"],
              valuePattern: #"\d+(\.\d+)?"#),
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

    private static func double(_ s: String?) -> Double? {
        guard let s = s?.replacingOccurrences(of: ",", with: ".") else { return nil }
        return Double(s)
    }
}
#endif
