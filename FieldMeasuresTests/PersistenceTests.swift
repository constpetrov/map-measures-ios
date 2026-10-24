import Foundation
import SwiftData
import Testing
@testable import FieldMeasures

/// Uses each container's `mainContext`, like the app, and checks the store through a fresh context.
@Suite(.serialized)
struct PersistenceTests {
    struct SaveFailed: Error {}

    private let failing = Persistence(save: { _ in throw SaveFailed() }, write: { _, _ in throw SaveFailed() })

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Measure.self,
            configurations: ModelConfiguration(UUID().uuidString, isStoredInMemoryOnly: true)
        )
    }

    private func sample(_ text: String = "320 lx") -> Measure {
        Measure(
            createdAt: Date(timeIntervalSince1970: 1_790_000_000),
            latitude: 52.520008,
            longitude: 13.404954,
            altitude: 34.2,
            accuracy: 5,
            text: text
        )
    }

    /// What is actually in the store, not just in the main context.
    private func stored(_ container: ModelContainer) throws -> [Measure] {
        try ModelContext(container).fetch(FetchDescriptor<Measure>())
    }

    @Test func pointsSurviveReopeningTheStore() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("test.store")
        let originalID: UUID

        do {
            let container = try ModelContainer(for: Measure.self, configurations: ModelConfiguration("reopen", url: url))
            // On iOS 17.0, models must be created after their container exists.
            let original = sample("68 dB,\ntraffic")
            originalID = original.id
            try Persistence().insert(original, into: container.mainContext)
            try Persistence().insert(Measure(
                createdAt: Date(timeIntervalSince1970: 1_790_000_100),
                latitude: -33.5, longitude: 151.25, altitude: nil, accuracy: 42, text: "dark"
            ), into: container.mainContext)
        }

        let reopened = try ModelContainer(for: Measure.self, configurations: ModelConfiguration("reopen", url: url))
        let points = try ModelContext(reopened).fetch(FetchDescriptor<Measure>(sortBy: [SortDescriptor(\.createdAt)]))
        #expect(points.count == 2)
        let first = try #require(points.first)
        #expect(first.id == originalID)
        #expect(first.createdAt == Date(timeIntervalSince1970: 1_790_000_000))
        #expect(first.latitude == 52.520008)
        #expect(first.longitude == 13.404954)
        #expect(first.altitude == 34.2)
        #expect(first.accuracy == 5)
        #expect(first.text == "68 dB,\ntraffic")
        #expect(points.last?.altitude == nil)
    }

    @Test func insertedPointsGetDistinctIDs() throws {
        let container = try makeContainer()
        try Persistence().insert(sample("a"), into: container.mainContext)
        try Persistence().insert(sample("b"), into: container.mainContext)
        #expect(Set(try stored(container).map(\.id)).count == 2)
    }

    @Test func failedInsertLeavesNothingStoredOrPending() throws {
        let container = try makeContainer()
        let context = container.mainContext
        #expect(throws: SaveFailed.self) {
            try failing.insert(sample(), into: context)
        }
        #expect(try context.fetchCount(FetchDescriptor<Measure>()) == 0)
        try context.save()
        #expect(try stored(container).isEmpty)
    }

    @Test func editIsSaved() throws {
        let container = try makeContainer()
        let point = sample("before")
        try Persistence().insert(point, into: container.mainContext)
        try Persistence().update(in: container.mainContext, change: { point.text = "after" }, revert: { point.text = "before" })
        #expect(try stored(container).map(\.text) == ["after"])
    }

    @Test func failedEditKeepsPreviousText() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let point = sample("before")
        try Persistence().insert(point, into: context)

        #expect(throws: SaveFailed.self) {
            try failing.update(in: context, change: { point.text = "after" }, revert: { point.text = "before" })
        }
        #expect(point.text == "before")
        try context.save()
        #expect(try stored(container).map(\.text) == ["before"])
    }

    @Test func deleteRemovesFromStoreAndContext() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let point = sample()
        try Persistence().insert(point, into: context)

        try Persistence().delete(point, from: context)
        #expect(try context.fetchCount(FetchDescriptor<Measure>()) == 0)
        #expect(try stored(container).isEmpty)
        #expect(!context.hasChanges)
    }

    @Test func failedDeleteKeepsPointInStoreAndContext() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let point = sample()
        try Persistence().insert(point, into: context)

        #expect(throws: SaveFailed.self) {
            try failing.delete(point, from: context)
        }
        // Give any autosave a chance to run, as it would in the app.
        try await Task.sleep(for: .seconds(2))
        #expect(try context.fetchCount(FetchDescriptor<Measure>()) == 1)
        #expect(!context.hasChanges)
        try context.save()
        #expect(try stored(container).count == 1)
    }

    @Test func failedInsertAndEditAreNotAutosavedLater() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let point = sample("before")
        try Persistence().insert(point, into: context)
        #expect(throws: SaveFailed.self) {
            try failing.update(in: context, change: { point.text = "after" }, revert: { point.text = "before" })
        }
        #expect(throws: SaveFailed.self) {
            try failing.insert(sample("extra"), into: context)
        }
        try await Task.sleep(for: .seconds(2))
        #expect(try stored(container).map(\.text) == ["before"])
    }

    @Test func exportIsWrittenToTemporaryFolder() throws {
        let url = try Persistence().writeExport(Data("hello".utf8), named: "measures_2026-10-24.gpx")
        #expect(url.lastPathComponent == "measures_2026-10-24.gpx")
        #expect(url.path.hasPrefix(FileManager.default.temporaryDirectory.path))
        #expect(try Data(contentsOf: url) == Data("hello".utf8))
    }

    @Test func failedExportWritePropagatesError() {
        #expect(throws: SaveFailed.self) {
            _ = try failing.writeExport(Data("x".utf8), named: "x.csv")
        }
    }
}
