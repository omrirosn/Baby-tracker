import Foundation
import Testing
@testable import RFIsSimple

/// Parsing what the user types, and formatting what they get back.
struct NumberTextTests {

    // MARK: - Parsing

    @Test func plainDecimals() {
        #expect(DecimalTextParser.parse("42", locale: testLocale) == 42)
        #expect(DecimalTextParser.parse("0.5", locale: testLocale) == 0.5)
        #expect(DecimalTextParser.parse("-3.5", locale: testLocale) == -3.5)
        #expect(DecimalTextParser.parse("+7", locale: testLocale) == 7)
    }

    /// A comma decimal separator has to work wherever the user is.
    @Test func commaIsADecimalSeparator() {
        #expect(DecimalTextParser.parse("1,5", locale: testLocale) == 1.5)
        #expect(DecimalTextParser.parse("0,25", locale: Locale(identifier: "de_DE")) == 0.25)
    }

    @Test func groupingSeparatorsAreIgnored() {
        #expect(DecimalTextParser.parse("1,234.5", locale: testLocale) == 1234.5)
        #expect(DecimalTextParser.parse("1.234.567", locale: Locale(identifier: "de_DE")) == 1_234_567)
        #expect(DecimalTextParser.parse("1 234,5", locale: Locale(identifier: "fr_FR")) == 1234.5)
    }

    @Test func scientificNotation() {
        #expect(DecimalTextParser.parse("1.5e9", locale: testLocale) == 1.5e9)
        #expect(DecimalTextParser.parse("2E-3", locale: testLocale) == 2e-3)
        #expect(DecimalTextParser.parse("1,5e9", locale: testLocale) == 1.5e9)
    }

    /// Half-typed values must not produce a wrong number while the user is
    /// still typing.
    @Test func partiallyTypedValues() {
        #expect(DecimalTextParser.parse("3.", locale: testLocale) == 3)
        #expect(DecimalTextParser.parse(".5", locale: testLocale) == 0.5)
        #expect(DecimalTextParser.parse("-.5", locale: testLocale) == -0.5)
    }

    @Test func unicodeMinusIsAccepted() {
        #expect(DecimalTextParser.parse("\u{2212}30", locale: testLocale) == -30)
    }

    /// `Double.init` accepts all of these; the parser must not.
    @Test func nonNumbersAreRejected() {
        #expect(DecimalTextParser.parse("", locale: testLocale) == nil)
        #expect(DecimalTextParser.parse("   ", locale: testLocale) == nil)
        #expect(DecimalTextParser.parse("abc", locale: testLocale) == nil)
        #expect(DecimalTextParser.parse("inf", locale: testLocale) == nil)
        #expect(DecimalTextParser.parse("nan", locale: testLocale) == nil)
        #expect(DecimalTextParser.parse("0x10", locale: testLocale) == nil)
        #expect(DecimalTextParser.parse("-", locale: testLocale) == nil)
        #expect(DecimalTextParser.parse("50 Ω", locale: testLocale) == nil)
    }

    // MARK: - Formatting

    @Test func displayUsesFourSignificantDigits() {
        #expect(ValueFormatter.display(0.299792458, locale: testLocale) == "0.2998")
        #expect(ValueFormatter.display(1234.5678, locale: testLocale) == "1235")
        #expect(ValueFormatter.display(0, locale: testLocale) == "0")
    }

    @Test func noGroupingSeparatorsSoValuesCanBeTypedBack() throws {
        let formatted = ValueFormatter.display(123456, locale: testLocale)
        #expect(!formatted.contains(","))
        let reparsed = try #require(DecimalTextParser.parse(formatted, locale: testLocale))
        #expect(isClose(reparsed, 123456, relativeTolerance: 1e-3))
    }

    @Test func veryLargeAndVerySmallValuesUseScientificNotation() throws {
        let large = ValueFormatter.display(2.4e9, locale: testLocale)
        let small = ValueFormatter.display(1.5e-7, locale: testLocale)
        #expect(large.lowercased().contains("e"))
        #expect(small.lowercased().contains("e"))
        #expect(isClose(try #require(DecimalTextParser.parse(large, locale: testLocale)), 2.4e9, relativeTolerance: 1e-3))
        #expect(isClose(try #require(DecimalTextParser.parse(small, locale: testLocale)), 1.5e-7, relativeTolerance: 1e-3))
    }

    @Test func copyKeepsMorePrecisionThanTheDisplay() throws {
        let value = 1.0 / 3.0
        let copied = try #require(DecimalTextParser.parse(ValueFormatter.copyText(value, locale: testLocale), locale: testLocale))
        #expect(isClose(copied, value, relativeTolerance: 1e-11))
    }

    @Test func nonFiniteValuesShowAPlaceholderRatherThanInfinity() {
        #expect(ValueFormatter.display(.infinity, locale: testLocale) == ValueFormatter.undefinedPlaceholder)
        #expect(ValueFormatter.display(.nan, locale: testLocale) == ValueFormatter.undefinedPlaceholder)
    }

    @Test func spokenFormReadsTheSignAndTheUnit() {
        let spoken = ValueFormatter.spoken(-12.5, unit: PowerUnit.dBm, locale: testLocale)
        #expect(spoken == "minus 12.5 dBm")
    }

    // MARK: - MeasuredInput

    /// Spec §12: changing the unit keeps the physical value.
    @Test func changingUnitPreservesTheQuantity() {
        var input = MeasuredInput<FrequencyUnit>(text: "1", unit: .gigahertz, locale: testLocale)
        #expect(isClose(input.baseValue, 1e9))

        input.setUnit(.megahertz)
        #expect(input.text == "1000")
        #expect(isClose(input.baseValue, 1e9))

        input.setUnit(.kilohertz)
        #expect(isClose(input.baseValue, 1e9))
    }

    /// 0 W has no dBm equivalent, so the field is cleared rather than left
    /// showing a number that now means something else.
    @Test func changingToAUnitThatCannotExpressTheValueClearsTheField() {
        var input = MeasuredInput<PowerUnit>(text: "0", unit: .watt, locale: testLocale)
        input.setUnit(.dBm)
        #expect(input.text.isEmpty)
        #expect(input.unit == .dBm)
        #expect(input.baseValue == nil)
    }

    @Test func emptyAndUnparsableStates() {
        let empty = MeasuredInput<PowerUnit>(text: "", unit: .dBm, locale: testLocale)
        #expect(empty.isEmpty)
        #expect(empty.baseValue == nil)
        #expect(empty.isUnparsable == false)

        let broken = MeasuredInput<PowerUnit>(text: "abc", unit: .dBm, locale: testLocale)
        #expect(broken.isUnparsable)
        #expect(broken.baseValue == nil)
    }

    @Test func seedingFromABaseValue() {
        let input = MeasuredInput<LengthUnit>(baseValue: 0.125, unit: .millimetre, locale: testLocale)
        #expect(input.text == "125")
        #expect(isClose(input.baseValue, 0.125))
    }

    @Test func aFieldStartsUnedited() {
        let input = MeasuredInput<PowerUnit>(text: "30", unit: .dBm, locale: testLocale)
        #expect(input.hasBeenEdited == false)
    }
}
