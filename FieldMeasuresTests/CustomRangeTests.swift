import Foundation
import Testing
@testable import FieldMeasures

struct CustomRangeTests {
    private let calendar = TestCalendar.berlin
    private let range = CustomRange(
        from: TestCalendar.date(2026, 10, 10), to: TestCalendar.date(2026, 10, 12), calendar: TestCalendar.berlin
    )

    @Test func fromMovedOneDayBeforeToKeepsTo() {
        let moved = range.settingFrom(TestCalendar.date(2026, 10, 11), calendar: calendar)
        #expect(moved.from == TestCalendar.date(2026, 10, 11))
        #expect(moved.to == TestCalendar.date(2026, 10, 12))
    }

    @Test func fromMovedOntoToKeepsTo() {
        let moved = range.settingFrom(TestCalendar.date(2026, 10, 12, 18, 0), calendar: calendar)
        #expect(moved.from == TestCalendar.date(2026, 10, 12))
        #expect(moved.to == TestCalendar.date(2026, 10, 12))
    }

    @Test func fromMovedPastToMovesToAlong() {
        let moved = range.settingFrom(TestCalendar.date(2026, 10, 15, 9, 0), calendar: calendar)
        #expect(moved.from == TestCalendar.date(2026, 10, 15))
        #expect(moved.to == TestCalendar.date(2026, 10, 15))
        #expect(moved.from <= moved.to)
    }

    @Test func toBeforeFromIsIgnored() {
        let moved = range.settingTo(TestCalendar.date(2026, 10, 9, 23, 59), calendar: calendar)
        #expect(moved == range)
    }

    @Test func toOnFromDayIsAccepted() {
        let moved = range.settingTo(TestCalendar.date(2026, 10, 10, 8, 0), calendar: calendar)
        #expect(moved.to == TestCalendar.date(2026, 10, 10))
    }

    @Test func sameDayWithDifferentTimesIsOneDayRange() {
        let sameDay = CustomRange(
            from: TestCalendar.date(2026, 10, 10, 15, 0), to: TestCalendar.date(2026, 10, 10, 9, 0), calendar: calendar
        )
        #expect(sameDay.from == TestCalendar.date(2026, 10, 10))
        #expect(sameDay.to == TestCalendar.date(2026, 10, 10))
    }

    @Test func invertedInitIsClampedToOneDay() {
        let inverted = CustomRange(from: TestCalendar.date(2026, 10, 12), to: TestCalendar.date(2026, 10, 10), calendar: calendar)
        #expect(inverted.to == inverted.from)
    }
}
