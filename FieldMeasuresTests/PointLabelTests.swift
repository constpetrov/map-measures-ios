import Testing
@testable import FieldMeasures

struct PointLabelTests {
    @Test func labelUnderLimitIsWhole() {
        #expect(pinLabel(for: "abcdefghijk") == "abcdefghijk")
    }

    @Test func labelAtLimitIsWhole() {
        #expect(pinLabel(for: "abcdefghijkl") == "abcdefghijkl")
    }

    @Test func labelOverLimitIsTruncatedWithEllipsis() {
        #expect(pinLabel(for: "abcdefghijklm") == "abcdefghijkl…")
    }

    @Test func labelReplacesEachLineBreakWithOneSpace() {
        #expect(pinLabel(for: "68 dB\ntraffic") == "68 dB traffi…")
        #expect(pinLabel(for: "a\r\nb") == "a b")
    }

    @Test func labelCountsEmojiAsOneCharacter() {
        #expect(pinLabel(for: "💡💡💡💡💡💡💡💡💡💡💡💡") == "💡💡💡💡💡💡💡💡💡💡💡💡")
    }

    @Test func gpxNameUnderAtAndOverLimit() {
        #expect(gpxName(for: "abcdefghijk") == "abcdefghijk")
        #expect(gpxName(for: "abcdefghijkl") == "abcdefghijkl")
        #expect(gpxName(for: "abcdefghijklm") == "abcdefghijkl")
    }

    @Test func gpxNameReplacesLineBreaks() {
        #expect(gpxName(for: "320 lx\nnorth door") == "320 lx north")
    }

    @Test func labelsShowWhenZoomedIn() {
        #expect(showsLabels(latitudeDelta: 0.005))
    }

    @Test func labelsShowAtThreshold() {
        #expect(showsLabels(latitudeDelta: 0.01))
    }

    @Test func labelsHideWhenZoomedOut() {
        #expect(!showsLabels(latitudeDelta: 0.02))
    }
}
