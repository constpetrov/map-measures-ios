import Foundation

/// `measures_<earliest>_<latest>.<ext>`, or `measures_<date>.<ext>` when all points share one local date.
nonisolated func exportFileName(for points: [ExportPoint], format: ExportFileFormat, calendar: Calendar) -> String {
    let dates = points.map(\.createdAt)
    guard let earliest = dates.min(), let latest = dates.max() else {
        return "measures.\(format.fileExtension)"
    }
    let first = localDay(earliest, calendar: calendar)
    let last = localDay(latest, calendar: calendar)
    let range = first == last ? first : "\(first)_\(last)"
    return "measures_\(range).\(format.fileExtension)"
}

/// `yyyy-MM-dd` from calendar components, so the device's calendar style and locale can't change it.
private nonisolated func localDay(_ date: Date, calendar: Calendar) -> String {
    let parts = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
}
