import Foundation
import Testing
@testable import FieldMeasures

struct GPXWriterTests {
    private func gpx(_ points: [ExportPoint]) -> String {
        String(decoding: GPXWriter.data(for: points), as: UTF8.self)
    }

    /// Collects waypoint elements so tests read what an XML reader sees, not raw text.
    private final class WaypointReader: NSObject, XMLParserDelegate {
        struct Waypoint { var attributes: [String: String] = [:]; var children: [(String, String)] = [] }
        var waypoints: [Waypoint] = []
        private var text = ""

        func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
            if name == "wpt" { waypoints.append(Waypoint(attributes: attributes)) }
            text = ""
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) { text += string }

        func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
            if ["ele", "time", "name", "desc"].contains(name) { waypoints[waypoints.count - 1].children.append((name, text)) }
        }
    }

    private func read(_ points: [ExportPoint]) throws -> [WaypointReader.Waypoint] {
        let parser = XMLParser(data: GPXWriter.data(for: points))
        let reader = WaypointReader()
        parser.delegate = reader
        #expect(parser.parse(), "GPX is not well-formed: \(parser.parserError.map(String.init(describing:)) ?? "")")
        return reader.waypoints
    }

    @Test func writesOneWaypointWithChildrenInSchemaOrder() throws {
        let waypoints = try read([ExportFixtures.berlinNoon])
        let waypoint = try #require(waypoints.first)
        #expect(waypoints.count == 1)
        #expect(waypoint.attributes == ["lat": "52.520008", "lon": "13.404954"])
        #expect(waypoint.children.map(\.0) == ["ele", "time", "name", "desc"])
        #expect(waypoint.children.map(\.1) == ["34.2", "2026-10-24T09:15:02Z", "320 lx, nort", "320 lx, north entrance, overcast"])
    }

    @Test func declaresGPX11Namespace() {
        let text = gpx([])
        #expect(text.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"))
        #expect(text.contains("<gpx version=\"1.1\" creator=\"FieldMeasures\" xmlns=\"http://www.topografix.com/GPX/1/1\">"))
    }

    @Test func omitsElevationWithoutAltitude() throws {
        let waypoint = try #require(try read([ExportFixtures.point(altitude: nil)]).first)
        #expect(waypoint.children.map(\.0) == ["time", "name", "desc"])
    }

    @Test func ordersWaypointsOldestFirst() throws {
        let points = [
            ExportFixtures.point("b", at: TestCalendar.date(2026, 10, 2)),
            ExportFixtures.point("c", at: TestCalendar.date(2026, 10, 3)),
            ExportFixtures.point("a", at: TestCalendar.date(2026, 10, 1)),
        ]
        let names = try read(points).map { $0.children.first { $0.0 == "name" }?.1 }
        #expect(names == ["a", "b", "c"])
    }

    @Test(arguments: [
        ("abcdefghijk", "abcdefghijk"),
        ("abcdefghijkl", "abcdefghijkl"),
        ("abcdefghijklm", "abcdefghijkl"),
        ("320 lx\nnorth door", "320 lx north"),
    ])
    func nameIsFirstTwelveCharacters(text: String, expected: String) throws {
        let waypoint = try #require(try read([ExportFixtures.point(text)]).first)
        #expect(waypoint.children.first { $0.0 == "name" }?.1 == expected)
        #expect(waypoint.children.first { $0.0 == "desc" }?.1 == text)
    }

    @Test func escapedSpecialCharactersRoundTrip() throws {
        let text = #"A&B <5> "quoted" it's"#
        let waypoint = try #require(try read([ExportFixtures.point(text)]).first)
        #expect(waypoint.children.first { $0.0 == "desc" }?.1 == text)
        #expect(gpx([ExportFixtures.point(text)]).contains("A&amp;B &lt;5&gt; &quot;quoted&quot; it&apos;s"))
    }

    @Test func numbersUseDotDecimalsWhateverTheLocale() {
        #expect(ExportFixtures.germanLocaleNumbers() == "1,5")
        let text = gpx([ExportFixtures.berlinNoon])
        #expect(text.contains("lat=\"52.520008\""))
        #expect(!text.contains("52,520008"))
    }

    /// Writes a sample for the manual `xmllint --schema` check (task-4.3). Path is printed in the test log.
    @Test func writesSampleForSchemaCheck() throws {
        let points = [ExportFixtures.berlinNoon, ExportFixtures.point(#"A&B <5> "q" it's"#, altitude: nil)]
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("fieldmeasures-sample.gpx")
        try GPXWriter.data(for: points).write(to: url)
        print("GPX sample: \(url.path)")
    }
}
