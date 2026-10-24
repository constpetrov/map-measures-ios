import Foundation

/// A description is valid when it has at least one character that is not whitespace or a line break.
nonisolated func isValidDescription(_ text: String) -> Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}
