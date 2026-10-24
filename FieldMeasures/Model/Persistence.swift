import Foundation
import SwiftData
import SwiftUI

/// The single place where store changes are saved and export files are written.
///
/// Each change is undone explicitly when its save fails, because `ModelContext.rollback()` doesn't
/// discard pending changes on iOS 17.0. The save and write functions are injectable so tests and
/// DEBUG launch flags can force failures.
nonisolated struct Persistence: Sendable {
    var save: @Sendable (ModelContext) throws -> Void = { try $0.save() }
    var write: @Sendable (Data, URL) throws -> Void = { try $0.write(to: $1, options: .atomic) }

    /// Inserts and saves. On failure the pending insert is discarded.
    func insert<Model: PersistentModel>(_ model: Model, into context: ModelContext) throws {
        context.insert(model)
        do {
            try save(context)
        } catch {
            context.delete(model)
            throw error
        }
    }

    /// Applies `change` and saves. On failure `revert` restores the previous values.
    func update(in context: ModelContext, change: () -> Void, revert: () -> Void) throws {
        change()
        do {
            try save(context)
        } catch {
            revert()
            throw error
        }
    }

    /// Deletes in a separate context first, so a failed save leaves `context` untouched.
    /// Only after that succeeds is the model removed from `context`, which updates its queries.
    func delete<Model: PersistentModel>(_ model: Model, from context: ModelContext) throws {
        let scratch = ModelContext(context.container)
        // Without this, a failed delete would still be autosaved later from the dropped context.
        scratch.autosaveEnabled = false
        if let copy = scratch.model(for: model.persistentModelID) as? Model {
            scratch.delete(copy)
            try save(scratch)
        }
        context.delete(model)
        // The row is already gone from the store; this only clears the pending delete in `context`.
        try? context.save()
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
