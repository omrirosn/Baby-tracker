import Foundation
@testable import RFIsSimple

/// Floating-point comparison with a relative tolerance.
///
/// Spec §14 asks for tolerances rather than exact equality: every value here
/// comes out of `pow` and `log10`, so the last bits are never reliable.
func isClose(
    _ actual: Double,
    _ expected: Double,
    relativeTolerance: Double = 1e-9
) -> Bool {
    if actual == expected { return true }
    guard actual.isFinite, expected.isFinite else { return false }
    let scale = max(abs(actual), abs(expected), 1e-30)
    return abs(actual - expected) <= relativeTolerance * scale
}

/// Same comparison for an optional, which is how the calculators report a
/// quantity that is infinite rather than merely large.
func isClose(
    _ actual: Double?,
    _ expected: Double,
    relativeTolerance: Double = 1e-9
) -> Bool {
    guard let actual else { return false }
    return isClose(actual, expected, relativeTolerance: relativeTolerance)
}

/// Fixed locale so formatting assertions do not depend on the test machine.
let testLocale = Locale(identifier: "en_US")
