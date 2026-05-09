import Foundation

/// Pure-logic location fuzzing. Same input → same output. Never returns
/// the original lat/lon back to the caller.
///
/// `LocationFuzzer.fuzz(...)` is intentionally a value transformation: the
/// caller passes lat/lon, and the result struct does NOT contain coordinate
/// fields. The fuzzer is the canonical client-side path. The server's
/// `fuzz-location` Edge Function exists only as defence-in-depth.
public struct FuzzedLocation: Codable, Equatable, Sendable {
    public let zipPrefix3: String?
    public let countyFips: String?
    public let stateCode:  String?

    public init(zipPrefix3: String? = nil, countyFips: String? = nil, stateCode: String? = nil) {
        self.zipPrefix3 = zipPrefix3
        self.countyFips = countyFips
        self.stateCode  = stateCode
    }

    public static let empty = FuzzedLocation()
}

public enum LocationFuzzer {

    /// Truncate a ZIP-5 (or ZIP-9) string to its 3-char prefix.
    public static func truncateZip(_ zip: String?) -> String? {
        guard let zip else { return nil }
        let digits = zip.filter { $0.isNumber }
        guard digits.count >= 3 else { return nil }
        return String(digits.prefix(3))
    }

    /// Convenience: fuzz from already-resolved fields. Used when the
    /// caller already knows the ZIP and/or county and just wants a
    /// `FuzzedLocation` value with the truncation guarantees.
    public static func fuzz(
        zip5: String? = nil,
        countyFips: String? = nil,
        stateCode: String? = nil
    ) -> FuzzedLocation {
        let zip3 = truncateZip(zip5)
        let cf   = countyFips.flatMap { $0.count == 5 ? $0 : nil }
        let sc   = stateCode.flatMap { $0.count == 2 ? $0.uppercased() : nil }
        return FuzzedLocation(zipPrefix3: zip3, countyFips: cf, stateCode: sc)
    }

    /// Validate a lat/lon pair. Out-of-range or NaN inputs return nil so the
    /// caller can short-circuit any network call.
    public static func validateCoordinate(lat: Double, lon: Double) -> Bool {
        lat.isFinite && lon.isFinite &&
        lat >= -90  && lat <=  90  &&
        lon >= -180 && lon <= 180
    }
}
