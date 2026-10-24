import Foundation
import SwiftData
import SwiftUI

/// The single place where store changes are saved and export files are written.
///
/// The save and write functions are injectable so tests and DEBUG launch flags can force failures.
nonisolated struct Persistence: Sendable {
    var save: @Sendable (ModelContext) throws -> Void = { try $0.save() }
    var write: @Sendable (Data, URL) throws -> Void = { try $0.write(to: $1, options: .atomic) }

    /// Applies `change`, then saves. On failure the context is rolled back to its last saved state
    /// and the error is rethrown, so the store is never left half-changed.
    func commit(_ change: () -> Void, in context: ModelContext) throws {
        let undoManager = UndoManager()
        undoManager.groupsByEvent = false
        let previousUndoManager = context.undoManager
        context.undoManager = undoManager
        defer { context.undoManager = previousUndoManager }

        undoManager.beginUndoGrouping()
        change()
        undoManager.endUndoGrouping()
        do {
            try save(context)
        } catch {
            undoManager.undo()
            throw error
        }
    }

    /// Writes `data` to a new folder in the temporary directory and returns the file URL.
    func writeExport(_ data: Data, named fileName: String) throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent(fileName)
        try write(data, url)
        return url
    }
}

extension EnvironmentValues {
    @Entry var persistence = Persistence()
}
