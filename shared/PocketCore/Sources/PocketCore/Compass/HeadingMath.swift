// HeadingMath — pure heading + bearing math. No CoreLocation imports here;
// callers feed in raw degrees / coordinates so this file is fully testable.
import Foundation

public struct GeoCoordinate: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public enum HeadingMath {
    /// Convert a magnetic compass heading to true (geographic) heading using
    /// magnetic declination (positive east, negative west).
    public static func magneticToTrue(magneticDegrees: Double, declination: Double) -> Double {
        normalize(magneticDegrees + declination)
    }

    /// Initial bearing along a great-circle from `a` to `b`, in degrees [0, 360).
    public static func bearingBetween(_ a: GeoCoordinate, _ b: GeoCoordinate) -> Double {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let theta = atan2(y, x) * 180 / .pi
        return normalize(theta)
    }

    /// 8-point cardinal label for the given heading in degrees.
    public static func cardinalLabel(forDegrees degrees: Double) -> String {
        let labels = ["N","NE","E","SE","S","SW","W","NW"]
        let normalized = normalize(degrees)
        let idx = Int((normalized + 22.5) / 45) % 8
        return labels[idx]
    }

    public static func normalize(_ degrees: Double) -> Double {
        var d = degrees.truncatingRemainder(dividingBy: 360)
        if d < 0 { d += 360 }
        return d
    }
}
