import Foundation

/// Writes points as GPX 1.1 waypoints, oldest first.
nonisolated enum GPXWriter {
    static func data(for points: [ExportPoint]) -> Data {
        let utc = TimeZone(identifier: "UTC")!
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="FieldMeasures" xmlns="http://www.topografix.com/GPX/1/1">

        """
        for point in ExportText.oldestFirst(points) {
            let latitude = ExportText.decimal(point.latitude, places: 6)
            let longitude = ExportText.decimal(point.longitude, places: 6)
            xml += "  <wpt lat=\"\(latitude)\" lon=\"\(longitude)\">\n"
            // GPX 1.1 requires this child order: ele, time, name, desc.
            if let altitude = point.altitude {
                xml += "    <ele>\(ExportText.decimal(altitude, places: 1))</ele>\n"
            }
            xml += "    <time>\(ExportText.timestamp(point.createdAt, timeZone: utc))</time>\n"
            xml += "    <name>\(escape(gpxName(for: point.text)))</name>\n"
            xml += "    <desc>\(escape(point.text))</desc>\n"
            xml += "  </wpt>\n"
        }
        xml += "</gpx>\n"
        return Data(xml.utf8)
    }

    /// Escapes the five XML special characters; `&` first so entities aren't escaped twice.
    static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
