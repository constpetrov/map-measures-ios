import Foundation
import SwiftData

/// One measurement point saved at the user's position.
@Model
final class Measure {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var latitude: Double
    var longitude: Double
    /// Metres above sea level; `nil` when the fix had no valid vertical accuracy.
    var altitude: Double?
    /// Horizontal accuracy of the fix, in metres.
    var accuracy: Double
    var text: String

    init(
        id: UUID = UUID(),
        createdAt: Date,
        latitude: Double,
        longitude: Double,
        altitude: Double?,
        accuracy: Double,
        text: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.accuracy = accuracy
        self.text = text
    }
}
