import Foundation

public protocol CrashTransport: AnyObject {
    func capture(_ error: Error)
    func capture(_ message: String)
}

public final class CrashReportingService {
    public static let shared = CrashReportingService()

    public var optedIn: Bool = false
    private weak var transport: CrashTransport?

    public func attach(_ transport: CrashTransport?) { self.transport = transport }

    public func capture(_ error: Error)    { if optedIn { transport?.capture(error) } }
    public func capture(_ message: String) { if optedIn { transport?.capture(message) } }

    #if canImport(Sentry)
    /// Wires up Sentry. Called from the host app's AppDelegate when
    /// `SENTRY_DSN` is non-empty. App target adds the actual SDK.
    public func useSentry(dsn: String) {
        // App target handles real SDK init.
    }
    #endif
}
