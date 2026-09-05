import Foundation

/// One numeric field: the text as typed, the unit next to it, and whether the
/// user has touched it yet.
///
/// Two behaviours from the spec live here rather than in the views:
///
/// * **Changing the unit preserves the physical quantity** (§12). Typing `1`
///   with GHz selected and switching to MHz rewrites the field as `1000`; it
///   does not reinterpret the `1` as 1 MHz.
/// * **Errors stay hidden until the field has been edited** (§6), which
///   `hasBeenEdited` drives.
struct MeasuredInput<U: PhysicalUnit>: Equatable {
    var text: String
    private(set) var unit: U
    var hasBeenEdited: Bool
    var locale: Locale

    init(text: String = "", unit: U, locale: Locale = .current) {
        self.text = text
        self.unit = unit
        self.hasBeenEdited = false
        self.locale = locale
    }

    /// Seeds the field from a value in the dimension's base unit.
    init(baseValue: Double, unit: U, locale: Locale = .current) {
        self.unit = unit
        self.locale = locale
        self.hasBeenEdited = false
        let converted = unit.fromBase(baseValue)
        self.text = converted.isFinite ? ValueFormatter.display(converted, locale: locale) : ""
    }

    /// The number as typed, expressed in the currently selected unit.
    var value: Double? { DecimalTextParser.parse(text, locale: locale) }

    /// The value converted to the dimension's base unit — what calculations use.
    var baseValue: Double? {
        guard let value else { return nil }
        let base = unit.toBase(value)
        return base.isFinite ? base : nil
    }

    var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// `true` when there is text that does not parse to a usable number.
    var isUnparsable: Bool { !isEmpty && value == nil }

    /// Switches unit while keeping the physical quantity fixed.
    ///
    /// When the quantity cannot be expressed in the new unit — 0 W has no dBm
    /// equivalent — the field is cleared rather than left showing a number that
    /// now means something else.
    mutating func setUnit(_ newUnit: U) {
        guard newUnit != unit else { return }
        if let value {
            let base = unit.toBase(value)
            let converted = newUnit.fromBase(base)
            text = converted.isFinite ? ValueFormatter.display(converted, locale: locale) : ""
        }
        unit = newUnit
    }

    /// Replaces the contents with a value given in the base unit, keeping the
    /// currently selected unit.
    mutating func setBaseValue(_ base: Double) {
        let converted = unit.fromBase(base)
        text = converted.isFinite ? ValueFormatter.display(converted, locale: locale) : ""
    }

    /// Restores a unit chosen in a previous session, without touching the text.
    mutating func restoreUnit(_ newUnit: U) {
        unit = newUnit
    }
}
