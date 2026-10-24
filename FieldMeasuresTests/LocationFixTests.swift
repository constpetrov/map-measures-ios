import CoreLocation
import Testing
@testable import FieldMeasures

struct LocationFixTests {
    private func location(horizontal: Double, vertical: Double) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 52.52, longitude: 13.405),
            altitude: 34.2,
            horizontalAccuracy: horizontal,
            verticalAccuracy: vertical,
            timestamp: Date()
        )
    }

    @Test func validFixKeepsAllValues() throws {
        let fix = try #require(LocationFix(location(horizontal: 5, vertical: 3)))
        #expect(fix.latitude == 52.52)
        #expect(fix.longitude == 13.405)
        #expect(fix.altitude == 34.2)
        #expect(fix.accuracy == 5)
    }

    @Test func invalidVerticalAccuracyDropsAltitude() throws {
        let fix = try #require(LocationFix(location(horizontal: 5, vertical: -1)))
        #expect(fix.altitude == nil)
    }

    @Test func invalidHorizontalAccuracyIsIgnored() {
        #expect(LocationFix(location(horizontal: -1, vertical: 3)) == nil)
    }
}
