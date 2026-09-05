import Foundation

/// Something worth telling the user about an input, shown under the field.
///
/// An issue always carries an icon and a written message so state is never
/// signalled by colour alone (spec §12, "Accessibility").
struct ValidationIssue: Hashable, Identifiable, Sendable {
    enum Severity: String, Hashable, Sendable {
        /// Blocks the result.
        case error
        /// The result stands, but the input is unusual and worth a second look.
        case warning
    }

    let severity: Severity
    let message: String

    var id: String { "\(severity.rawValue)|\(message)" }

    var systemImage: String {
        switch severity {
        case .error: return "exclamationmark.triangle.fill"
        case .warning: return "info.circle.fill"
        }
    }

    /// Spoken prefix so VoiceOver conveys severity without relying on colour.
    var accessibilityPrefix: String {
        switch severity {
        case .error: return "Error"
        case .warning: return "Note"
        }
    }

    static func error(_ message: String) -> ValidationIssue {
        ValidationIssue(severity: .error, message: message)
    }

    static func warning(_ message: String) -> ValidationIssue {
        ValidationIssue(severity: .warning, message: message)
    }

    init(severity: Severity, message: String) {
        self.severity = severity
        self.message = message
    }

    init(_ error: CalculationError) {
        self.severity = .error
        self.message = error.message
    }
}
