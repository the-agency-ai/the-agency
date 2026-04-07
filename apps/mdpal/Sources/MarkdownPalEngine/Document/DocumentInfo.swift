// What Problem: A document has identifying metadata — version id, version
// number, revision number, timestamps, authors — that lives in the metadata
// block alongside comments and flags. The engine needs an in-memory type
// for this information.
//
// How & Why: Plain value struct, Codable for YAML round-trip. The versionId
// is a composite string (e.g., "V0001.0003.20260404T1200Z") that encodes
// version, revision, and timestamp for human-readable identification of
// bundle revisions. The numeric `version` and `revision` are kept as
// separate fields for typed comparison.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

import Foundation

/// Document-level identifying metadata.
public struct DocumentInfo: Equatable, Sendable, Codable {

    /// Composite version identifier (e.g., "V0001.0003.20260404T1200Z").
    public var versionId: String

    /// Version number (incremented on major content shifts).
    public var version: Int

    /// Revision number within the current version (incremented per save).
    public var revision: Int

    /// When this revision was created.
    public var timestamp: Date

    /// When the document was first created.
    public var created: Date

    /// Authors who have contributed to the document.
    public var authors: [String]

    public init(
        versionId: String,
        version: Int,
        revision: Int,
        timestamp: Date,
        created: Date,
        authors: [String]
    ) {
        self.versionId = versionId
        self.version = version
        self.revision = revision
        self.timestamp = timestamp
        self.created = created
        self.authors = authors
    }

    /// A blank DocumentInfo for new documents with no existing metadata.
    public static func blank(now: Date = Date()) -> DocumentInfo {
        DocumentInfo(
            versionId: "V0001.0001.\(formatVersionTimestamp(now))",
            version: 1,
            revision: 1,
            timestamp: now,
            created: now,
            authors: []
        )
    }

    /// Format a Date as a versionId timestamp (e.g., "20260404T1200Z").
    private static func formatVersionTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmm'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}
