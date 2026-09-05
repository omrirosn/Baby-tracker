import Foundation

/// Formats numbers for display and for copying.
///
/// Policy (spec §12, "Result behavior"):
/// * four significant digits on screen — enough for engineering work, short
///   enough to read at a glance;
/// * no grouping separators, so a displayed value can be typed straight back in;
/// * scientific notation only outside the range where plain decimals stay
///   readable;
/// * full precision is never lost — `copyText` keeps twelve significant digits.
enum ValueFormatter {
    static let displaySignificantDigits = 4
    static let copySignificantDigits = 12

    /// Values at or above this magnitude switch to scientific notation.
    static let scientificUpperBound = 1e6
    /// Values below this magnitude (and non-zero) switch to scientific notation.
    static let scientificLowerBound = 1e-4

    /// Placeholder shown where a result has no finite value.
    static let undefinedPlaceholder = "—"

    /// Rounded form shown in the interface.
    static func display(
        _ value: Double,
        significantDigits: Int = displaySignificantDigits,
        locale: Locale = .current
    ) -> String {
        format(value, significantDigits: significantDigits, locale: locale)
    }

    /// High-precision form placed on the pasteboard, so copying never silently
    /// throws away digits the calculation produced.
    static func copyText(_ value: Double, locale: Locale = .current) -> String {
        format(value, significantDigits: copySignificantDigits, locale: locale)
    }

    /// `display` with the unit symbol appended, e.g. `-12.34 dBm`.
    static func display(_ value: Double, unit: some PhysicalUnit, locale: Locale = .current) -> String {
        "\(display(value, locale: locale)) \(unit.symbol)"
    }

    /// Spoken form for VoiceOver, e.g. "-12.34 dBm" → "minus 12.34 dBm".
    static func spoken(_ value: Double, unit: some PhysicalUnit, locale: Locale = .current) -> String {
        guard value.isFinite else { return "undefined" }
        let magnitude = display(abs(value), locale: locale)
        let sign = value < 0 ? "minus " : ""
        return "\(sign)\(magnitude) \(unit.accessibilityName)"
    }

    private static func format(_ value: Double, significantDigits: Int, locale: Locale) -> String {
        guard value.isFinite else { return undefinedPlaceholder }
        if value == 0 { return "0" }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 1
        formatter.maximumSignificantDigits = max(1, significantDigits)
        formatter.usesGroupingSeparator = false

        let magnitude = abs(value)
        if magnitude >= scientificUpperBound || magnitude < scientificLowerBound {
            formatter.numberStyle = .scientific
            formatter.exponentSymbol = "e"
        } else {
            formatter.numberStyle = .decimal
        }

        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
