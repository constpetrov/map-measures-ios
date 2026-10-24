import Foundation
import Testing
@testable import FieldMeasures

struct ExportFileNameTests {
    private let calendar = TestCalendar.berlin

    @Test func singleDateUsesOneDate() {
        let points = [
            ExportFixtures.point(at: TestCalendar.date(2026, 10, 24, 8)),
            ExportFixtures.point(at: TestCalendar.date(2026, 10, 24, 20)),
        ]
        #expect(exportFileName(for: points, format: .gpx, calendar: calendar) == "measures_2026-10-24.gpx")
    }

    @Test func dateRangeUsesEarliestAndLatestInAnyOrder() {
        let points = [
            ExportFixtures.point(at: TestCalendar.date(2026, 10, 24)),
            ExportFixtures.point(at: TestCalendar.date(2026, 10, 1)),
            ExportFixtures.point(at: TestCalendar.date(2026, 10, 9)),
        ]
        #expect(exportFileName(for: points, format: .csv, calendar: calendar) == "measures_2026-10-01_2026-10-24.csv")
    }

    @Test func usesLocalDateNotUTC() {
        // 00:30 in Berlin on 24 Oct is still 23 Oct in UTC.
        let points = [ExportFixtures.point(at: TestCalendar.date(2026, 10, 24, 0, 30))]
        #expect(exportFileName(for: points, format: .gpx, calendar: calendar) == "measures_2026-10-24.gpx")
    }

    @Test func zeroPadsMonthAndDay() {
        let points = [ExportFixtures.point(at: TestCalendar.date(2026, 3, 5, 12))]
        #expect(exportFileName(for: points, format: .csv, calendar: calendar) == "measures_2026-03-05.csv")
    }
}
