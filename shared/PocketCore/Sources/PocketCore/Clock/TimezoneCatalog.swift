// TimezoneCatalog — searchable list of IANA zones grouped by region.
import Foundation

public struct TimezoneEntry: Hashable, Sendable {
    public let identifier: String      // e.g. "America/Los_Angeles"
    public let displayCity: String     // "Los Angeles"
    public let region: String          // "Americas"

    public init(identifier: String) {
        self.identifier = identifier
        let parts = identifier.split(separator: "/")
        self.region = parts.first.map(String.init) ?? "Other"
        self.displayCity = (parts.last.map(String.init) ?? identifier).replacingOccurrences(of: "_", with: " ")
    }
}

public enum TimezoneCatalog {
    /// Filters TimeZone.knownTimeZoneIdentifiers and returns sorted entries.
    public static func all() -> [TimezoneEntry] {
        TimeZone.knownTimeZoneIdentifiers
            .filter { $0.contains("/") } // skip "GMT", "UTC", etc.
            .map(TimezoneEntry.init(identifier:))
            .sorted { $0.identifier < $1.identifier }
    }

    public static func search(_ query: String, in entries: [TimezoneEntry] = all()) -> [TimezoneEntry] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return entries }
        return entries.filter {
            $0.displayCity.lowercased().contains(q) ||
            $0.identifier.lowercased().contains(q) ||
            $0.region.lowercased().contains(q)
        }
    }
}
