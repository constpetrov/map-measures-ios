import Testing
@testable import FieldMeasures

struct AccuracyRulesTests {
    @Test func withinThresholdHasNoWarning() {
        #expect(!isLowAccuracy(15))
    }

    @Test func atThresholdHasNoWarning() {
        #expect(!isLowAccuracy(20))
    }

    @Test func beyondThresholdWarns() {
        #expect(isLowAccuracy(21))
    }
}
