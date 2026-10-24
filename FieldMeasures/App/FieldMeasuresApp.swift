import SwiftData
import SwiftUI

@main
struct FieldMeasuresApp: App {
    @State private var location = LocationManager()
    private let container: ModelContainer
    private let persistence: Persistence

    init() {
        do {
            container = try ModelContainer(for: Measure.self)
        } catch {
            fatalError("Could not open the points store: \(error)")
        }
        #if DEBUG
        persistence = DebugOptions.persistence()
        DebugOptions.seedIfRequested(container)
        #else
        persistence = Persistence()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MapScreen()
                .environment(location)
                .environment(\.persistence, persistence)
        }
        .modelContainer(container)
    }
}
