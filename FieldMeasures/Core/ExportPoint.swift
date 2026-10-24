import Foundation

/// A stored point as plain values, so export code doesn't depend on SwiftData.
nonisolated struct ExportPoint: Equatable, Sendable {
    var id: UUID
    var createdAt: Date
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var accuracy: Double
    var text: String
}

nonisolated enum ExportFileFormat: String, CaseIterable, Identifiable, Sendable {
    case gpx
    case csv

    var id: Self { self }
    var fileExtension: String { rawValue }
    var title: String { rawValue.uppercased() }
}

/// Number and time formatting shared by the export writers. Never depends on the device locale.
nonisolated enum ExportText {
    private static let posix = Locale(identifier: "en_US_POSIX")

    static func decimal(_ value: Double, places: Int) -> String {
        String(format: "%.\(places)f", locale: posix, value)
    }

    static func wholeNumber(_ value: Double) -> String {
        String(format: "%.0f", locale: posix, value.rounded())
    }

    /// ISO 8601 with seconds, e.g. `2026-10-24T09:15:02Z` in UTC or `2026-10-24T11:15:02+02:00` elsewhere.
    static func timestamp(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    static func oldestFirst(_ points: [ExportPoint]) -> [ExportPoint] {
        points.sorted { $0.createdAt < $1.createdAt }
    }
}
