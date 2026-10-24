import CoreLocation
import Observation

/// A position fix that is safe to save: valid horizontal accuracy, altitude only when it is valid.
struct LocationFix: Equatable {
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var accuracy: Double

    /// Returns `nil` for an invalid fix (negative horizontal accuracy).
    init?(_ location: CLLocation) {
        guard location.horizontalAccuracy >= 0 else { return nil }
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        altitude = location.verticalAccuracy >= 0 ? location.altitude : nil
        accuracy = location.horizontalAccuracy
    }
}

/// Owns the app's single `CLLocationManager` and publishes authorization and the latest valid fix.
@Observable
final class LocationManager: NSObject {
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var latestFix: LocationFix?

    @ObservationIgnored private let manager = CLLocationManager()

    /// Denied or restricted. With Location Services off system-wide, iOS also reports `.denied`.
    var isAccessOff: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    override init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
    }

    private func handleAuthorization(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            manager.stopUpdatingLocation()
            latestFix = nil
        }
    }
}

// The manager is created on the main thread, so Core Location calls the delegate there.
extension LocationManager: @MainActor CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorization(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let fix = locations.reversed().lazy.compactMap(LocationFix.init).first {
            latestFix = fix
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {}
}
