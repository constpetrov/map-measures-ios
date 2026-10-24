import Foundation

/// Number of characters of a description shown under its pin and used as the GPX waypoint name.
nonisolated let labelCharacterLimit = 12

/// Labels show only when the map's visible latitude span is at most this many degrees (about 1 km).
nonisolated let labelLatitudeDeltaThreshold = 0.01

/// The first 12 characters with line breaks as spaces, plus "…" when the description is longer.
nonisolated func pinLabel(for text: String) -> String {
    let prefix = singleLinePrefix(of: text)
    return text.count > labelCharacterLimit ? prefix + "…" : prefix
}

/// The first 12 characters with line breaks as spaces, without an ellipsis.
nonisolated func gpxName(for text: String) -> String {
    singleLinePrefix(of: text)
}

nonisolated func showsLabels(latitudeDelta: Double) -> Bool {
    latitudeDelta <= labelLatitudeDeltaThreshold
}

/// Counts Characters (what people see), so "\r\n" and emoji are one character each.
private nonisolated func singleLinePrefix(of text: String) -> String {
    String(text.prefix(labelCharacterLimit).map { $0.isNewline ? " " : $0 })
}
