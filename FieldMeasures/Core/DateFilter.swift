import Foundation

/// The date filter applied to the map, the list and exports.
nonisolated enum DateFilter: Equatable, Sendable {
    case all
    case today
    case last7Days
    case custom(CustomRange)

    /// A half-open range of creation times, `start <= date < end`.
    struct Bounds: Equatable {
        var start: Date
        var end: Date
    }

    /// `nil` for `.all`. Day boundaries come from `calendar`, so daylight-saving days are 23 or 25 hours long.
    func bounds(now: Date, calendar: Calendar) -> Bounds? {
        let today = calendar.startOfDay(for: now)
        switch self {
        case .all:
            return nil
        case .today:
            return Bounds(start: today, end: Self.dayAfter(today, calendar: calendar))
        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            return Bounds(start: start, end: Self.dayAfter(today, calendar: calendar))
        case .custom(let range):
            return Bounds(start: range.from, end: Self.dayAfter(range.to, calendar: calendar))
        }
    }

    func matches(_ date: Date, now: Date, calendar: Calendar) -> Bool {
        guard let bounds = bounds(now: now, calendar: calendar) else { return true }
        return date >= bounds.start && date < bounds.end
    }

    var isAll: Bool { self == .all }

    private static func dayAfter(_ day: Date, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
    }
}
