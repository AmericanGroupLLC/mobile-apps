import Foundation
#if canImport(UIKit) && canImport(Vision)
import UIKit
import Vision

/// On-device insurance card OCR. Mirrors `NutritionLabelOCR.swift` —
/// `VNRecognizeTextRequest` plus a small regex set tuned for the
/// payer / member ID / group # / BIN / PCN / RxGrp fields most US
/// commercial cards print on the front face.
///
/// **Privacy:** image and OCR text are never uploaded. Parsed structured
/// fields land in the PHI Core Data store via `PHIStore.saveInsuranceCard`;
/// the raw OCR text lands in the Keychain via
/// `KeychainStore.Service.insurance` so it can be re-parsed without
/// re-snapping the card.
@MainActor
public final class InsuranceCardOCR {

    public static let shared = InsuranceCardOCR()
    private init() {}

    public struct Result: Sendable {
        public var payer: String?
        public var memberId: String?
        public var groupNumber: String?
        public var bin: String?
        public var pcn: String?
        public var rxGrp: String?
        public var rawText: String

        public init(payer: String? = nil, memberId: String? = nil,
                    groupNumber: String? = nil, bin: String? = nil,
                    pcn: String? = nil, rxGrp: String? = nil,
                    rawText: String = "") {
            self.payer = payer
            self.memberId = memberId
            self.groupNumber = groupNumber
            self.bin = bin
            self.pcn = pcn
            self.rxGrp = rxGrp
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
                                                orientation: .up, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do { try handler.perform([request]) }
                catch { cont.resume(returning: .init(rawText: "")) }
            }
        }
    }

    /// Pure-function extraction so it's unit-testable from JVM-style
    /// fixtures without needing a real `UIImage`.
    static func extract(from text: String) -> Result {
        var result = Result(rawText: text)

        // Member ID: look for "Member ID", "Member #", "Subscriber ID",
        // "ID #", or just "ID:". Captures alphanumeric token (8–20 chars).
        result.memberId = matchAfter(
            keys: ["member id", "member #", "member no", "subscriber id",
                   "subscriber #", "id #", "id:", "id no"],
            pattern: #"[A-Z0-9\-]{6,20}"#,
            in: text
        )
        // Group number
        result.groupNumber = matchAfter(
            keys: ["group #", "group no", "group:", "group number"],
            pattern: #"[A-Z0-9\-]{4,15}"#,
            in: text
        )
        // BIN — always 6 digits, often labelled "Rx BIN" / "BIN #".
        result.bin = matchAfter(
            keys: ["bin #", "bin:", "rx bin"],
            pattern: #"\d{6}"#,
            in: text
        )
        // PCN — alphanumeric, often labelled "PCN".
        result.pcn = matchAfter(
            keys: ["pcn:", "pcn #", "rx pcn"],
            pattern: #"[A-Z0-9]{2,15}"#,
            in: text
        )
        // RxGrp — alphanumeric, label "RxGrp" / "Rx Group".
        result.rxGrp = matchAfter(
            keys: ["rxgrp", "rx grp", "rx group"],
            pattern: #"[A-Z0-9\-]{2,15}"#,
            in: text
        )
        // Payer: first non-empty line that doesn't contain digits is a
        // decent heuristic for cards whose payer name is at the top.
        if let payer = text.split(separator: "\n")
            .map(String.init)
            .first(where: { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.isEmpty &&
                       !trimmed.contains(where: \.isNumber) &&
                       trimmed.count > 2
            }) {
            result.payer = payer.trimmingCharacters(in: .whitespaces)
        }
        return result
    }

    /// Find the first occurrence of any key (case-insensitive) and return
    /// the regex match that follows it on the same line.
    private static func matchAfter(keys: [String], pattern: String, in text: String) -> String? {
        let lines = text.split(separator: "\n").map(String.init)
        let upper = text  // we case-insensitively match the keys via `.lowercased()` below
        _ = upper
        for line in lines {
            let lower = line.lowercased()
            guard let key = keys.first(where: { lower.contains($0) }) else { continue }
            let after = String(lower[lower.range(of: key)!.upperBound...])
            // Re-extract on the original-case substring of the line so the
            // returned token preserves original casing.
            let originalAfter = line.suffix(after.count)
            if let r = String(originalAfter).range(of: pattern, options: .regularExpression) {
                return String(originalAfter[r])
            }
        }
        return nil
    }
}
#endif
