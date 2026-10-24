#if DEBUG
import Foundation
import SwiftData

/// DEBUG-only launch flags for checking failure alerts and performance in the simulator.
///
/// - `-FailSaves`: every store save throws.
/// - `-FailExportWrite`: every export file write throws.
/// - `-SeedPoints <n>`: when the store is empty, inserts n points spread evenly over the last 30 days,
///   within about 1 km of `-SeedCenter <lat>,<lon>` (default: Berlin, 52.520008,13.404954).
enum DebugOptions {
    struct ForcedFailure: LocalizedError {
        var errorDescription: String? { "Forced by a DEBUG launch flag." }
    }

    private static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static func persistence() -> Persistence {
        var persistence = Persistence()
        if arguments.contains("-FailSaves") {
            persistence.save = { _ in throw ForcedFailure() }
        }
        if arguments.contains("-FailExportWrite") {
            persistence.write = { _, _ in throw ForcedFailure() }
        }
        return persistence
    }

    static func seedIfRequested(_ container: ModelContainer) {
        guard let count = value(after: "-SeedPoints").flatMap(Int.init), count > 0 else { return }
        let center = value(after: "-SeedCenter")
            .map { $0.split(separator: ",").compactMap { Double($0) } }
            .flatMap { $0.count == 2 ? (latitude: $0[0], longitude: $0[1]) : nil }
            ?? (latitude: 52.520008, longitude: 13.404954)

        let context = container.mainContext
        guard (try? context.fetchCount(FetchDescriptor<Measure>())) == 0 else { return }

        let now = Date()
        let span: TimeInterval = 30 * 24 * 60 * 60
        let side = Int(Double(count).squareRoot().rounded(.up))
        for index in 0..<count {
            let row = Double(index / side) / Double(side) - 0.5
            let column = Double(index % side) / Double(side) - 0.5
            context.insert(Measure(
                createdAt: now.addingTimeInterval(-span * Double(index) / Double(count)),
                latitude: center.latitude + row * 0.018,
                longitude: center.longitude + column * 0.028,
                altitude: index.isMultiple(of: 5) ? nil : 34,
                accuracy: Double(3 + index % 30),
                text: "Seed \(index + 1): \(200 + index % 400) lx"
            ))
        }
        try? context.save()
    }

    private static func value(after flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}
#endif
