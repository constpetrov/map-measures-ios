import Foundation
import Testing
@testable import FieldMeasures

struct CSVWriterTests {
    private let berlin = TimeZone(identifier: "Europe/Berlin")!

    private func csv(_ points: [ExportPoint], timeZone: TimeZone? = nil) -> Data {
        CSVWriter.data(for: points, timeZone: timeZone ?? berlin)
    }

    /// A minimal RFC 4180 reader: quoted fields, doubled quotes, CRLF records.
    private func parse(_ data: Data) -> [[String]] {
        var text = Substring(String(decoding: data.dropFirst(3), as: UTF8.self))
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        while let character = text.first {
            text = text.dropFirst()
            if inQuotes {
                if character == "\"" {
                    if text.first == "\"" { field.append("\""); text = text.dropFirst() } else { inQuotes = false }
                } else {
                    field.append(character)
                }
            } else if character == "\"" {
                inQuotes = true
            } else if character == "," {
                row.append(field); field = ""
            } else if character == "\r\n" {
                row.append(field); rows.append(row); row = []; field = ""
            } else {
                field.append(character)
            }
        }
        return rows
    }

    @Test func startsWithByteOrderMark() {
        #expect(Array(csv([ExportFixtures.berlinNoon]).prefix(3)) == [0xEF, 0xBB, 0xBF])
    }

    @Test func headerFollowsByteOrderMark() {
        let rows = parse(csv([]))
        #expect(rows == [["created_at_utc", "created_at_local", "latitude", "longitude", "altitude_m", "accuracy_m", "description"]])
    }

    @Test func rowHasAllFieldsFormatted() throws {
        let rows = parse(csv([ExportFixtures.berlinNoon]))
        #expect(rows.count == 2)
        #expect(rows[1] == [
            "2026-10-24T09:15:02Z", "2026-10-24T11:15:02+02:00", "52.520008", "13.404954", "34.2", "5",
            "320 lx, north entrance, overcast",
        ])
    }

    @Test func rowsEndWithCRLF() {
        let text = String(decoding: csv([ExportFixtures.point()]).dropFirst(3), as: UTF8.self)
        #expect(text.hasSuffix("\r\n"))
        #expect(text.components(separatedBy: "\r\n").count == 3)
    }

    @Test func localTimeUsesGivenTimeZone() {
        let rows = parse(csv([ExportFixtures.berlinNoon], timeZone: TimeZone(identifier: "UTC")!))
        #expect(rows[1][1] == "2026-10-24T09:15:02Z")
        let tokyo = parse(csv([ExportFixtures.berlinNoon], timeZone: TimeZone(identifier: "Asia/Tokyo")!))
        #expect(tokyo[1][1] == "2026-10-24T18:15:02+09:00")
    }

    @Test func missingAltitudeIsEmptyField() {
        let rows = parse(csv([ExportFixtures.point(altitude: nil)]))
        #expect(rows[1][4] == "")
    }

    @Test func accuracyIsRoundedToWholeMetres() {
        var point = ExportFixtures.point()
        point.accuracy = 20.5
        #expect(parse(csv([point]))[1][5] == "21")
        point.accuracy = 3.2
        #expect(parse(csv([point]))[1][5] == "3")
    }

    @Test func quotesFieldsWithSpecialCharacters() {
        #expect(CSVWriter.field("plain") == "plain")
        #expect(CSVWriter.field("a,b") == "\"a,b\"")
        #expect(CSVWriter.field("say \"hi\"") == "\"say \"\"hi\"\"\"")
        #expect(CSVWriter.field("two\nlines") == "\"two\nlines\"")
        #expect(CSVWriter.field("cr\rlf") == "\"cr\rlf\"")
    }

    @Test(arguments: ["68 dB, traffic", "say \"hi\"", "line 1\nline 2", "a\r\nb", "Свет 320 лк", "  spaced  "])
    func descriptionsRoundTrip(text: String) {
        let rows = parse(csv([ExportFixtures.point(text)]))
        #expect(rows[1][6] == text)
    }

    @Test func ordersRowsOldestFirst() {
        let points = [
            ExportFixtures.point("b", at: TestCalendar.date(2026, 10, 2)),
            ExportFixtures.point("a", at: TestCalendar.date(2026, 10, 1)),
        ]
        #expect(parse(csv(points)).dropFirst().map { $0[6] } == ["a", "b"])
    }

    @Test func numbersUseDotDecimalsWhateverTheLocale() {
        #expect(ExportFixtures.germanLocaleNumbers() == "1,5")
        let row = parse(csv([ExportFixtures.berlinNoon]))[1]
        #expect(row[2] == "52.520008")
        #expect(row[4] == "34.2")
    }
}
