import Foundation
import DriftCore

/// Live-selfie capture is hosted in `Features/Onboarding/SelfieView.swift`.
/// This service is the network glue for the `verify-selfie` Edge Function.
final class VerificationService {
    static let shared = VerificationService()

    struct Request: Encodable {
        let selfie_image_id: String
        let comparison_photo_id: String
    }
    struct Response: Decodable {
        let verified: Bool
        let similarity: Int?
    }

    /// Uploads `selfieJpeg` to Supabase Storage and invokes the Edge Function.
    func verify(selfieJpeg: Data, comparisonPhotoId: UUID) async throws -> Response {
        guard let _ = SupabaseClient.shared else { throw VerifyError.noClient }
        // (Storage upload is omitted in skeleton; production would use the
        // Storage REST endpoint and obtain the resulting object id.)
        let selfieId = UUID().uuidString
        let req = Request(selfie_image_id: selfieId, comparison_photo_id: comparisonPhotoId.uuidString)
        AnalyticsService.shared.track(.verificationStarted)
        let r = try await SupabaseClient.shared!.invokeFunction("verify-selfie", body: req, as: Response.self)
        if r.verified {
            AnalyticsService.shared.track(.verificationSucceeded(similarityPct: r.similarity ?? 0))
        } else {
            AnalyticsService.shared.track(.verificationFailed(reason: "below_threshold"))
        }
        return r
    }

    enum VerifyError: Error { case noClient }
}
