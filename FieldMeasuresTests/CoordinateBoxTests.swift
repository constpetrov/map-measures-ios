import Testing
@testable import FieldMeasures

struct CoordinateBoxTests {
    private let berlin = CoordinateBox(
        centerLatitude: 52.52, centerLongitude: 13.40, latitudeDelta: 0.02, longitudeDelta: 0.04, scale: 1.5
    )

    @Test func containsPointsInsideTheScaledBox() {
        #expect(berlin.contains(latitude: 52.52, longitude: 13.40))
        #expect(berlin.contains(latitude: 52.534, longitude: 13.429))
    }

    @Test func excludesPointsOutside() {
        #expect(!berlin.contains(latitude: 52.54, longitude: 13.40))
        #expect(!berlin.contains(latitude: 52.52, longitude: 13.44))
    }

    @Test func handlesBoxesCrossingTheAntimeridian() {
        let fiji = CoordinateBox(centerLatitude: -17, centerLongitude: 179.9, latitudeDelta: 1, longitudeDelta: 1)
        #expect(fiji.contains(latitude: -17, longitude: -179.8))
        #expect(!fiji.contains(latitude: -17, longitude: 178))
    }
}
