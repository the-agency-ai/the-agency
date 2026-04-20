// What Problem: When a comment is resolved, the engine needs to capture who
// resolved it, when, and what the response was — so the resolution survives
// in the metadata block as a permanent record.
//
// How & Why: Plain value struct, Codable for YAML round-trip. The presence
// of a Resolution on a Comment (vs nil) is how the engine distinguishes
// resolved from unresolved comments — they live in different YAML lists
// (`resolved` vs `unresolved`) but share the same Comment shape.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

import Foundation

/// The resolution of a comment.
public struct Resolution: Equatable, Sendable, Codable {

    /// The response text explaining the resolution.
    public let response: String

    /// When the comment was resolved.
    public let resolvedDate: Date

    /// Who resolved the comment.
    public let resolvedBy: String

    public init(response: String, resolvedDate: Date, resolvedBy: String) {
        self.response = response
        self.resolvedDate = resolvedDate
        self.resolvedBy = resolvedBy
    }
}
