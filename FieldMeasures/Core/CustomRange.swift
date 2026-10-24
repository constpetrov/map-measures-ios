import Foundation

/// A From–To date range whose To is never before From. Both dates are stored as the start of their day.
nonisolated struct CustomRange: Equatable, Sendable {
    private(set) var from: Date
    private(set) var to: Date

    init(from: Date, to: Date, calendar: Calendar) {
        self.from = calendar.startOfDay(for: from)
        self.to = max(calendar.startOfDay(for: to), self.from)
    }

    /// Moves From. When the new From's day is after To's day, To moves to the same day.
    func settingFrom(_ date: Date, calendar: Calendar) -> CustomRange {
        var range = self
        range.from = calendar.startOfDay(for: date)
        if range.to < range.from {
            range.to = range.from
        }
        return range
    }

    /// Moves To, unless the new To's day is before From's day; then the range is unchanged.
    func settingTo(_ date: Date, calendar: Calendar) -> CustomRange {
        let day = calendar.startOfDay(for: date)
        guard day >= from else { return self }
        var range = self
        range.to = day
        return range
    }
}
