import MapKit
import os
import SwiftData
import SwiftUI
import UIKit

enum MapStyleChoice: String {
    case standard
    case satellite
}

/// The app's only screen: a full-screen map with the user's position and one pin per filtered point.
struct MapScreen: View {
    enum ActiveSheet: Identifiable, Hashable {
        case add
        case detail(UUID)
        case filterList
        case export

        var id: Self { self }
    }

    @Environment(LocationManager.self) private var location
    @Environment(\.openURL) private var openURL
    @Query(sort: \Measure.createdAt, order: .reverse) private var measures: [Measure]
    @AppStorage("mapStyle") private var mapStyle = MapStyleChoice.standard.rawValue
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    /// Last settled camera region; `nil` until the map reports one.
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedID: UUID?
    @State private var activeSheet: ActiveSheet?
    /// Not persisted: every launch starts on All.
    @State private var filterKind = FilterKind.all
    @State private var customRange = CustomRange(from: .now, to: .now, calendar: .current)

    private let signposter = OSSignposter(subsystem: Bundle.main.bundleIdentifier ?? "FieldMeasures", category: .pointsOfInterest)

    private var isSatellite: Bool { mapStyle == MapStyleChoice.satellite.rawValue }

    private var filter: DateFilter { filterKind.filter(custom: customRange) }

    /// The one filtered array that feeds the pins, the list and the export.
    private var filteredMeasures: [Measure] {
        let filter = filter
        guard !filter.isAll else { return measures }
        let now = Date.now
        let calendar = Calendar.current
        return measures.filter { filter.matches($0.createdAt, now: now, calendar: calendar) }
    }

    var body: some View {
        let filtered = filteredMeasures
        Map(position: $position, selection: $selectedID) {
            UserAnnotation()
            ForEach(visibleMeasures(in: filtered)) { measure in
                Marker(
                    pinLabel(for: measure.text),
                    coordinate: CLLocationCoordinate2D(latitude: measure.latitude, longitude: measure.longitude)
                )
                .tint(.red)
                .annotationTitles(showsPinLabels ? .visible : .hidden)
                .tag(measure.id)
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
        .onChange(of: selectedID) { _, id in
            if let id {
                activeSheet = .detail(id)
            }
        }
        .onChange(of: filter) {
            let interval = signposter.beginInterval("FilterChange")
            Task { @MainActor in
                signposter.endInterval("FilterChange", interval)
            }
        }
        .sheet(item: $activeSheet, onDismiss: { selectedID = nil }) { sheet in
            switch sheet {
            case .add:
                AddMeasureSheet()
            case .detail(let id):
                if let measure = measures.first(where: { $0.id == id }) {
                    MeasureDetailSheet(measure: measure)
                }
            case .filterList:
                FilterListSheet(
                    filterKind: $filterKind,
                    customRange: $customRange,
                    measures: filtered,
                    onSelect: center(on:)
                )
            case .export:
                ExportSheet(measures: filtered)
            }
        }
    }

    private var showsPinLabels: Bool {
        visibleRegion.map { showsLabels(latitudeDelta: $0.span.latitudeDelta) } ?? false
    }

    /// Points inside the visible region plus half a span of margin on each side.
    private func visibleMeasures(in filtered: [Measure]) -> [Measure] {
        guard let region = visibleRegion else { return [] }
        let box = CoordinateBox(
            centerLatitude: region.center.latitude,
            centerLongitude: region.center.longitude,
            latitudeDelta: region.span.latitudeDelta,
            longitudeDelta: region.span.longitudeDelta,
            scale: 2
        )
        return filtered.filter { box.contains(latitude: $0.latitude, longitude: $0.longitude) }
    }

    /// Centres the map on a point, keeping the current zoom.
    private func center(on measure: Measure) {
        activeSheet = nil
        let span = visibleRegion?.span ?? MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        position = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: measure.latitude, longitude: measure.longitude),
            span: span
        ))
    }

    private var toolbar: some View {
        HStack(spacing: 24) {
            Button {
                mapStyle = (isSatellite ? MapStyleChoice.standard : .satellite).rawValue
            } label: {
                Image(systemName: isSatellite ? "map" : "globe.europe.africa")
            }
            .accessibilityLabel(isSatellite ? "Show standard map" : "Show satellite map")

            Button {
                activeSheet = .filterList
            } label: {
                Image(systemName: filter.isAll
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill")
            }
            .accessibilityLabel("Filter and list")
            .accessibilityValue(filter.isAll ? "All points" : "Filter active")

            Button {
                activeSheet = .export
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .disabled(filteredMeasures.isEmpty)
            .accessibilityLabel("Export")

            Spacer()

            Button {
                activeSheet = .add
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
