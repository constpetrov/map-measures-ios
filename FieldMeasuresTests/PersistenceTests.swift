import Foundation
import SwiftData
import Testing
@testable import FieldMeasures

@Suite(.serialized)
struct PersistenceTests {
    struct SaveFailed: Error {}

    private let failing = Persistence(save: { _ in throw SaveFailed() }, write: { _, _ in throw SaveFailed() })

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Measure.self,
            configurations: ModelConfiguration(UUID().uuidString, isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
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

    private func fetchAll(_ context: ModelContext) throws -> [Measure] {
        try context.fetch(FetchDescriptor<Measure>())
    }

    @Test func pointsSurviveReopeningTheStore() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("test.store")
        let originalID: UUID

        do {
            let container = try ModelContainer(for: Measure.self, configurations: ModelConfiguration("reopen", url: url))
            let context = ModelContext(container)
            let original = sample("68 dB,\ntraffic")
            originalID = original.id
            let noAltitude = Measure(
                createdAt: Date(timeIntervalSince1970: 1_790_000_100),
                latitude: -33.5, longitude: 151.25, altitude: nil, accuracy: 42, text: "dark"
            )
            try Persistence().commit({
                context.insert(original)
                context.insert(noAltitude)
            }, in: context)
        }

        let reopened = try ModelContainer(for: Measure.self, configurations: ModelConfiguration("reopen", url: url))
        let stored = try ModelContext(reopened).fetch(FetchDescriptor<Measure>(sortBy: [SortDescriptor(\.createdAt)]))
        #expect(stored.count == 2)
        let first = try #require(stored.first)
        #expect(first.id == originalID)
        #expect(first.createdAt == Date(timeIntervalSince1970: 1_790_000_000))
        #expect(first.latitude == 52.520008)
        #expect(first.longitude == 13.404954)
        #expect(first.altitude == 34.2)
        #expect(first.accuracy == 5)
        #expect(first.text == "68 dB,\ntraffic")
        #expect(stored.last?.altitude == nil)
    }

    @Test func insertedPointsGetDistinctIDs() throws {
        let context = try makeContext()
        try Persistence().commit({
            context.insert(sample("a"))
            context.insert(sample("b"))
        }, in: context)
        let ids = try fetchAll(context).map(\.id)
        #expect(Set(ids).count == 2)
    }

    @Test func failedInsertLeavesNothingStored() throws {
        let context = try makeContext()
        #expect(throws: SaveFailed.self) {
            try failing.commit({ context.insert(sample()) }, in: context)
        }
        #expect(try fetchAll(context).isEmpty)
    }

    @Test func failedEditKeepsPreviousText() throws {
        let context = try makeContext()
        let point = sample("before")
        try Persistence().commit({ context.insert(point) }, in: context)

        #expect(throws: SaveFailed.self) {
            try failing.commit({ point.text = "after" }, in: context)
        }
        #expect(try fetchAll(context).map(\.text) == ["before"])
    }

    @Test func failedDeleteKeepsPoint() throws {
        let context = try makeContext()
        let point = sample()
        try Persistence().commit({ context.insert(point) }, in: context)

        #expect(throws: SaveFailed.self) {
            try failing.commit({ context.delete(point) }, in: context)
        }
        #expect(try fetchAll(context).count == 1)
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
