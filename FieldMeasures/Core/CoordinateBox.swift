import Foundation

/// A latitude/longitude rectangle used to draw only the points near the visible map region.
nonisolated struct CoordinateBox: Equatable {
    var minLatitude: Double
    var maxLatitude: Double
    var minLongitude: Double
    var maxLongitude: Double

    /// A box around a region's centre, `scale` times the region's span (1.5 adds half a span of margin).
    init(centerLatitude: Double, centerLongitude: Double, latitudeDelta: Double, longitudeDelta: Double, scale: Double = 1) {
        let halfLatitude = latitudeDelta * scale / 2
        let halfLongitude = longitudeDelta * scale / 2
        minLatitude = centerLatitude - halfLatitude
        maxLatitude = centerLatitude + halfLatitude
        minLongitude = centerLongitude - halfLongitude
        maxLongitude = centerLongitude + halfLongitude
    }

    func contains(latitude: Double, longitude: Double) -> Bool {
        guard latitude >= minLatitude, latitude <= maxLatitude else { return false }
        if maxLongitude - minLongitude >= 360 { return true }
        // Shift the longitude into the box's range so boxes crossing ±180° still work.
        for shifted in [longitude, longitude - 360, longitude + 360] where shifted >= minLongitude && shifted <= maxLongitude {
            return true
        }
        return false
    }
}
