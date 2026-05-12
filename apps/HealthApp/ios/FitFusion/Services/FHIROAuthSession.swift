import Foundation
#if canImport(AuthenticationServices)
import AuthenticationServices
import UIKit

/// Wraps `ASWebAuthenticationSession` for the SMART-on-FHIR PKCE flow.
/// Caller hands in an `authorizationURL` (built by `FHIROAuthClient`); we
/// open the system browser, intercept the callback to the
/// `myhealth://oauth/fhir/callback` scheme, extract the code, and return.
@MainActor
public final class FHIROAuthSession: NSObject, ASWebAuthenticationPresentationContextProviding {

    public struct Result {
        public let code: String
        public let state: String
    }

    public enum SessionError: Error {
        case cancelled
        case missingCode
        case stateMismatch
        case unknown
    }

    public static let shared = FHIROAuthSession()

    private var current: ASWebAuthenticationSession?

    /// Run the system OAuth flow. Throws on cancel / failure / state mismatch.
    public func authenticate(authorizationURL: URL, callbackScheme: String,
                             expectedState: String) async throws -> Result {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Result, Error>) in
            let session = ASWebAuthenticationSession(
                url: authorizationURL,
                callbackURLScheme: callbackScheme
            ) { callback, error in
                if let error = error {
                    if let asError = error as? ASWebAuthenticationSessionError,
                       asError.code == .canceledLogin {
                        cont.resume(throwing: SessionError.cancelled)
                    } else {
                        cont.resume(throwing: error)
                    }
                    return
                }
                guard let url = callback,
                      let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let code = comps.queryItems?.first(where: { $0.name == "code" })?.value else {
                    cont.resume(throwing: SessionError.missingCode)
                    return
                }
                let state = comps.queryItems?.first(where: { $0.name == "state" })?.value ?? ""
                if !expectedState.isEmpty && state != expectedState {
                    cont.resume(throwing: SessionError.stateMismatch)
                    return
                }
                cont.resume(returning: Result(code: code, state: state))
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.current = session
            session.start()
        }
    }

    nonisolated public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if Thread.isMainThread {
            return mainAnchor()
        }
        return DispatchQueue.main.sync { mainAnchor() }
    }

    nonisolated private func mainAnchor() -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ?? scenes.first?.windows.first
        return window ?? ASPresentationAnchor()
    }
}
#endif
