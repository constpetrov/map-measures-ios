import Foundation

/// Writes points as RFC 4180 CSV with a UTF-8 byte-order mark, oldest first.
nonisolated enum CSVWriter {
    static let header = "created_at_utc,created_at_local,latitude,longitude,altitude_m,accuracy_m,description"
    static let byteOrderMark: [UInt8] = [0xEF, 0xBB, 0xBF]

    /// `timeZone` sets the `created_at_local` column (the device's current zone at export time).
    static func data(for points: [ExportPoint], timeZone: TimeZone) -> Data {
        let utc = TimeZone(identifier: "UTC")!
        var lines = [header]
        for point in ExportText.oldestFirst(points) {
            lines.append([
                ExportText.timestamp(point.createdAt, timeZone: utc),
                ExportText.timestamp(point.createdAt, timeZone: timeZone),
                ExportText.decimal(point.latitude, places: 6),
                ExportText.decimal(point.longitude, places: 6),
                point.altitude.map { ExportText.decimal($0, places: 1) } ?? "",
                ExportText.wholeNumber(point.accuracy),
                field(point.text),
            ].joined(separator: ","))
        }
        let text = lines.map { $0 + "\r\n" }.joined()
        return Data(byteOrderMark) + Data(text.utf8)
    }

    /// Quotes a field that contains a comma, double quote or line break, doubling inner quotes.
    static func field(_ value: String) -> String {
        guard value.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
