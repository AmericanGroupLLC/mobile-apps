import Foundation

/// Crash + non-fatal-error reporting slot. v1 attaches
/// `NoopCrashReportingService`; v1.1 will optionally attach Sentry behind a
/// Settings opt-in.
///
/// IMPORTANT: BuddyPlay v1 does NOT send any crash reports. This file
/// declares the interface only.
public protocol CrashReportingService {
    func capture(error: Error, context: [String: String])
    func breadcrumb(_ message: String, category: String)
}

public final class NoopCrashReportingService: CrashReportingService {
    public init() {}
    public func capture(error: Error, context: [String: String]) {}
    public func breadcrumb(_ message: String, category: String) {}
}

#if canImport(Sentry)
// Real implementation lands in v1.1 once the user opts in via Settings.
// import Sentry
// public final class SentryCrashReportingService: CrashReportingService { ... }
#endif
