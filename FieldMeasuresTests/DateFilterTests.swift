import Foundation
import Testing
@testable import FieldMeasures

struct DateFilterTests {
    private let calendar = TestCalendar.berlin
    private let now = TestCalendar.date(2026, 10, 24, 15, 30)

    private func matches(_ filter: DateFilter, _ date: Date, now: Date? = nil) -> Bool {
        filter.matches(date, now: now ?? self.now, calendar: calendar)
    }

    private func custom(from: Date, to: Date) -> DateFilter {
        .custom(CustomRange(from: from, to: to, calendar: calendar))
    }

    @Test func allMatchesEverything() {
        #expect(matches(.all, .distantPast))
        #expect(matches(.all, .distantFuture))
        #expect(DateFilter.all.bounds(now: now, calendar: calendar) == nil)
    }

    @Test func todayIncludesMidnightToday() {
        #expect(matches(.today, TestCalendar.date(2026, 10, 24, 0, 0, 0)))
    }

    @Test func todayExcludesLastSecondOfYesterday() {
        #expect(!matches(.today, TestCalendar.date(2026, 10, 23, 23, 59, 59)))
    }

    @Test func todayIncludesLastSecondOfToday() {
        #expect(matches(.today, TestCalendar.date(2026, 10, 24, 23, 59, 59)))
    }

    @Test func last7DaysIncludesMidnightSixDaysAgo() {
        #expect(matches(.last7Days, TestCalendar.date(2026, 10, 18, 0, 0, 0)))
    }

    @Test func last7DaysExcludesLastSecondSevenDaysAgo() {
        #expect(!matches(.last7Days, TestCalendar.date(2026, 10, 17, 23, 59, 59)))
    }

    @Test func customIncludesStartOfFromDay() {
        let filter = custom(from: TestCalendar.date(2026, 10, 10), to: TestCalendar.date(2026, 10, 12))
        #expect(matches(filter, TestCalendar.date(2026, 10, 10, 0, 0, 0)))
    }

    @Test func customIncludesLastSecondOfToDay() {
        let filter = custom(from: TestCalendar.date(2026, 10, 10), to: TestCalendar.date(2026, 10, 12))
        #expect(matches(filter, TestCalendar.date(2026, 10, 12, 23, 59, 59)))
    }

    @Test func customExcludesDayBeforeFrom() {
        let filter = custom(from: TestCalendar.date(2026, 10, 10), to: TestCalendar.date(2026, 10, 12))
        #expect(!matches(filter, TestCalendar.date(2026, 10, 9, 23, 59, 59)))
    }

    @Test func customExcludesDayAfterTo() {
        let filter = custom(from: TestCalendar.date(2026, 10, 10), to: TestCalendar.date(2026, 10, 12))
        #expect(!matches(filter, TestCalendar.date(2026, 10, 13, 0, 0, 0)))
    }

    @Test func customSingleDayMatchesWholeDay() {
        let day = TestCalendar.date(2026, 10, 10)
        let filter = custom(from: day, to: day)
        #expect(matches(filter, TestCalendar.date(2026, 10, 10, 0, 0, 0)))
        #expect(matches(filter, TestCalendar.date(2026, 10, 10, 23, 59, 59)))
        #expect(!matches(filter, TestCalendar.date(2026, 10, 11, 0, 0, 0)))
    }

    @Test func todayOnDaylightSavingStartIs23Hours() throws {
        // Europe/Berlin moves clocks forward on 2026-03-29.
        let dstNow = TestCalendar.date(2026, 3, 29, 12, 0)
        let bounds = try #require(DateFilter.today.bounds(now: dstNow, calendar: calendar))
        #expect(bounds.end.timeIntervalSince(bounds.start) == 23 * 3600)
        #expect(matches(.today, TestCalendar.date(2026, 3, 29, 23, 30), now: dstNow))
        #expect(!matches(.today, TestCalendar.date(2026, 3, 30, 0, 0), now: dstNow))
    }

    @Test func last7DaysAcrossDaylightSavingEndStartsAtMidnight() throws {
        // Europe/Berlin moves clocks back on 2026-10-25.
        let bounds = try #require(DateFilter.last7Days.bounds(now: TestCalendar.date(2026, 10, 27, 9, 0), calendar: calendar))
        #expect(bounds.start == TestCalendar.date(2026, 10, 21, 0, 0, 0))
        #expect(bounds.end == TestCalendar.date(2026, 10, 28, 0, 0, 0))
    }
}
