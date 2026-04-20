// What Problem: Non-fatal warnings and errors generated during parsing and
// rendering (contract §11). These surface in a diagnostics banner/pane
// without blocking the deck from rendering.
//
// How & Why: Simple value type with severity level and human-readable message.
// Collected in DeckDocument during parsing and displayed via the UI layer.
// Every error class from contract §11 maps to a Diagnostic.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.1

import Foundation

/// A non-fatal diagnostic produced during parsing or rendering.
public struct Diagnostic: Identifiable, Equatable {
    public let id = UUID()
    public let severity: Severity
    public let message: String
    /// Optional slide index where the diagnostic occurred.
    public let slideIndex: Int?

    public enum Severity: String, Equatable {
        case warning
        case error
    }

    public init(severity: Severity, message: String, slideIndex: Int? = nil) {
        self.severity = severity
        self.message = message
        self.slideIndex = slideIndex
    }

    // Custom Equatable (ignore id for testing)
    public static func == (lhs: Diagnostic, rhs: Diagnostic) -> Bool {
        lhs.severity == rhs.severity
            && lhs.message == rhs.message
            && lhs.slideIndex == rhs.slideIndex
    }
}
