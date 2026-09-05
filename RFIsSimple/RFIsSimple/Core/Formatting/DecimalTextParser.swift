import Foundation

/// Turns what an engineer types into a `Double`.
///
/// Requirements this satisfies (spec §12, "Input behavior"):
/// * decimal input works whichever separator the user's locale uses;
/// * scientific notation is accepted (`1.5e9`, `2E-3`);
/// * partially typed values (`3.`, `.5`) never produce a wrong number;
/// * `inf`, `nan` and hex literals — all of which `Double.init` accepts — are
///   rejected before they can reach a calculation.
enum DecimalTextParser {
    /// Characters allowed in a decimal or scientific literal once separators
    /// have been normalised.
    private static let allowedCharacters = Set("0123456789.eE+-")

    /// Characters some locales insert as grouping separators.
    private static let groupingCharacters = ["\u{00A0}", "\u{202F}", "\u{2009}", " ", "'"]

    static func parse(_ text: String, locale: Locale = .current) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // `Double("inf")`, `Double("nan")` and `Double("0x1p3")` all succeed, so
        // reject letters up front. `e` and `E` stay for scientific notation.
        let hasUnexpectedLetter = trimmed.contains { $0.isLetter && $0 != "e" && $0 != "E" }
        guard !hasUnexpectedLetter else { return nil }

        // Digits from other scripts never reach `Double.init`; hand those to the
        // locale-aware formatter instead.
        if trimmed.contains(where: { $0.isNumber && !$0.isASCII }) {
            return localeNumber(from: trimmed, locale: locale)
        }

        var candidate = trimmed.replacingOccurrences(of: "\u{2212}", with: "-")
        for separator in groupingCharacters {
            candidate = candidate.replacingOccurrences(of: separator, with: "")
        }
        candidate = normalisingSeparators(in: candidate)

        guard candidate.allSatisfy({ allowedCharacters.contains($0) }),
              candidate.contains(where: { $0.isNumber }) else { return nil }

        // Accept values that are still being typed, such as "3." or ".5".
        if candidate.hasSuffix(".") { candidate += "0" }
        if candidate.hasPrefix(".") { candidate = "0" + candidate }
        if candidate.hasPrefix("-.") { candidate = "-0" + candidate.dropFirst() }
        if candidate.hasPrefix("+.") { candidate = "+0" + candidate.dropFirst() }

        guard let value = Double(candidate), value.isFinite else { return nil }
        return value
    }

    /// Resolves `.` and `,` into a single decimal point.
    ///
    /// * A separator that repeats is grouping: `1.234.567` → `1234567`.
    /// * When both appear, the last one is the decimal point: `1,234.5` → `1234.5`.
    /// * A single separator is the decimal point, which is what someone typing
    ///   into a calculator means whatever their locale.
    private static func normalisingSeparators(in text: String) -> String {
        let dots = text.filter { $0 == "." }.count
        let commas = text.filter { $0 == "," }.count

        switch (dots, commas) {
        case (0, 0):
            return text
        case (_, 0):
            return dots > 1 ? text.replacingOccurrences(of: ".", with: "") : text
        case (0, _):
            return commas > 1
                ? text.replacingOccurrences(of: ",", with: "")
                : text.replacingOccurrences(of: ",", with: ".")
        default:
            let lastDot = text.lastIndex(of: ".")
            let lastComma = text.lastIndex(of: ",")
            if let lastDot, let lastComma, lastDot > lastComma {
                return text.replacingOccurrences(of: ",", with: "")
            }
            return text
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
        }
    }

    private static func localeNumber(from text: String, locale: Locale) -> Double? {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        guard let number = formatter.number(from: text) else { return nil }
        let value = number.doubleValue
        return value.isFinite ? value : nil
    }
}
