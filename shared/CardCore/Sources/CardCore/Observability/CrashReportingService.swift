// CrashReportingService — canImport-gated stub for Sentry. Off by default.
// See SENTRY.md to wire the SDK in.
import Foundation

public protocol CrashTransport: AnyObject {
    func capture(error: Error)
    func capture(message: String)
}

public final class CrashReportingService {
    public static let shared = CrashReportingService()
    public var optedIn: Bool = false
    private var transport: CrashTransport?

    public init() {}

    public func attach(transport: CrashTransport?) { self.transport = transport }

    public func capture(_ error: Error) {
        guard optedIn, let t = transport else { return }
        t.capture(error: error)
    }

    public func capture(_ message: String) {
        guard optedIn, let t = transport else { return }
        t.capture(message: message)
    }
}

#if canImport(Sentry)
import Sentry
extension CrashReportingService {
    public func useSentry(dsn: String, environment: String = "production") {
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = environment
            options.attachStacktrace = true
            options.enableAutoPerformanceTracing = false
        }
        attach(transport: SentryTransport())
    }
}
private final class SentryTransport: CrashTransport {
    func capture(error: Error) { SentrySDK.capture(error: error) }
    func capture(message: String) { SentrySDK.capture(message: message) }
}
#endif
