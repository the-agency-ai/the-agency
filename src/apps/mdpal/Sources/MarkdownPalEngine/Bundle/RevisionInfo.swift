// What Problem: Bundle revisions need a typed identifier so the engine
// can list, sort, and reference them without parsing filename strings
// at every call site. RevisionInfo is the parsed form.
//
// How & Why: Plain value struct. Sortable by versionId because the
// `V{NNNN}.{NNNN}.{YYYYMMDD}T{HHMM}Z` format is designed for lex sort
// (zero-padded numerics + ISO timestamp). Equatable for tests.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.4)

import Foundation

/// Identifying information for a single bundle revision.
public struct RevisionInfo: Equatable, Sendable {

    /// Composite version identifier (e.g., "V0001.0003.20260404T1200Z").
    public let versionId: String

    /// Version number (4 digits in the id).
    public let version: Int

    /// Revision number within the version (4 digits in the id).
    public let revision: Int

    /// UTC timestamp when the revision was created.
    public let timestamp: Date

    /// Absolute path to the revision file on disk.
    public let filePath: String

    public init(
        versionId: String,
        version: Int,
        revision: Int,
        timestamp: Date,
        filePath: String
    ) {
        self.versionId = versionId
        self.version = version
        self.revision = revision
        self.timestamp = timestamp
        self.filePath = filePath
    }
}

extension RevisionInfo: Comparable {
    public static func < (lhs: RevisionInfo, rhs: RevisionInfo) -> Bool {
        // Lex sort on versionId is correct because the format is designed
        // for it (zero-padded numbers + sortable timestamp).
        lhs.versionId < rhs.versionId
    }
}
