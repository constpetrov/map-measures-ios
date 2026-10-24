import MapKit
import SwiftData
import SwiftUI
import UIKit

enum MapStyleChoice: String {
    case standard
    case satellite
}

/// The app's only screen: a full-screen map with the user's position and one pin per point.
struct MapScreen: View {
    @Environment(LocationManager.self) private var location
    @Environment(\.openURL) private var openURL
    @Query(sort: \Measure.createdAt, order: .reverse) private var measures: [Measure]
    @AppStorage("mapStyle") private var mapStyle = MapStyleChoice.standard.rawValue
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var isAdding = false
    /// Last settled camera region; `nil` until the map reports one.
    @State private var visibleRegion: MKCoordinateRegion?

    /// Pin titles show only at or below this latitude span. Replaced by the Core label rule in task-3.1.
    private let detailedPinLatitudeDelta = 0.01

    private var isSatellite: Bool { mapStyle == MapStyleChoice.satellite.rawValue }

    var body: some View {
        Map(position: $position) {
            UserAnnotation()
            ForEach(visibleMeasures) { measure in
                Marker(
                    measure.text,
                    coordinate: CLLocationCoordinate2D(latitude: measure.latitude, longitude: measure.longitude)
                )
                .tint(.red)
                .annotationTitles(showsDetailedPins ? .visible : .hidden)
            }
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            visibleRegion = context.region
        }
        .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .safeAreaInset(edge: .top) {
            if location.isAccessOff {
                locationOffBanner
            }
        }
        .safeAreaInset(edge: .bottom) {
            toolbar
        }
        .sheet(isPresented: $isAdding) {
            AddMeasureSheet()
        }
    }

    private var showsDetailedPins: Bool {
        (visibleRegion?.span.latitudeDelta ?? .infinity) <= detailedPinLatitudeDelta
    }

    /// Points inside the visible region plus half a span of margin, so panning doesn't reveal empty edges.
    private var visibleMeasures: [Measure] {
        guard let region = visibleRegion else { return [] }
        let box = CoordinateBox(
            centerLatitude: region.center.latitude,
            centerLongitude: region.center.longitude,
            latitudeDelta: region.span.latitudeDelta,
            longitudeDelta: region.span.longitudeDelta,
            scale: 2
        )
        return measures.filter { box.contains(latitude: $0.latitude, longitude: $0.longitude) }
    }

    private var toolbar: some View {
        HStack(spacing: 24) {
            Button {
                mapStyle = (isSatellite ? MapStyleChoice.standard : .satellite).rawValue
            } label: {
                Image(systemName: isSatellite ? "map" : "globe.europe.africa")
            }
            .accessibilityLabel(isSatellite ? "Show standard map" : "Show satellite map")

            Spacer()

            Button {
                isAdding = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(location.isAuthorized ? Color.accentColor : Color.gray))
                    .foregroundStyle(.white)
            }
            .disabled(!location.isAuthorized)
            .accessibilityLabel("Add point")
        }
        .font(.title3)
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var locationOffBanner: some View {
        HStack {
            Label("Location access is off", systemImage: "location.slash")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .background(.regularMaterial)
    }
}
