import Testing
@testable import FieldMeasures

struct TextRulesTests {
    @Test(arguments: ["", " ", "   ", "\n", " \t\n\r\n "])
    func emptyOrWhitespaceIsInvalid(_ text: String) {
        #expect(!isValidDescription(text))
    }

    @Test(arguments: ["x", " x ", "\n5\n", "320 lx"])
    func anyVisibleCharacterIsValid(_ text: String) {
        #expect(isValidDescription(text))
    }
}
