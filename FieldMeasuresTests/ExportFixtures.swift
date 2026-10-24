import Foundation
@testable import FieldMeasures

enum ExportFixtures {
    static let berlinNoon = ExportPoint(
        id: UUID(),
        createdAt: TestCalendar.date(2026, 10, 24, 11, 15, 2),
        latitude: 52.520008,
        longitude: 13.404954,
        altitude: 34.25,
        accuracy: 4.6,
        text: "320 lx, north entrance, overcast"
    )

    static func point(
        _ text: String = "x",
        at date: Date = TestCalendar.date(2026, 10, 24, 12),
        altitude: Double? = 10
    ) -> ExportPoint {
        ExportPoint(id: UUID(), createdAt: date, latitude: 1, longitude: 2, altitude: altitude, accuracy: 5, text: text)
    }

    /// The same number formatted for a comma-decimal locale, to show the writers' output differs from it.
    static func germanLocaleNumbers() -> String {
        String(format: "%.1f", locale: Locale(identifier: "de_DE"), 1.5)
    }
}
