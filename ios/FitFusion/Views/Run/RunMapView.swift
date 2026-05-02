import SwiftUI
import MapKit

struct RunMapView: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        Map {
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(LinearGradient(colors: [.orange, .pink],
                                           startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
            if let start = coordinates.first {
                Marker("Start", coordinate: start).tint(.green)
            }
            if let end = coordinates.last, coordinates.count > 1 {
                Marker("End", coordinate: end).tint(.red)
            }
        }
        .overlay(alignment: .topTrailing) {
            if coordinates.isEmpty {
                Text("No route recorded")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(8)
                    .background(.thinMaterial, in: Capsule())
                    .padding(8)
            }
        }
    }
}
