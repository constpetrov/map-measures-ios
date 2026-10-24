import Foundation

/// Fixes with a horizontal accuracy worse than this many metres get a warning. Saving is still allowed.
nonisolated let lowAccuracyThreshold: Double = 20

nonisolated func isLowAccuracy(_ horizontalAccuracy: Double) -> Bool {
    horizontalAccuracy > lowAccuracyThreshold
}
