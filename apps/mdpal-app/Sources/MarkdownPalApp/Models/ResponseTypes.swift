// What Problem: The CLI returns structured JSON responses for mutation
// commands (edit, resolve, flag, clear-flag) and list wrappers (comments,
// flags). The app needs typed representations to parse these responses.
// Also need a BundlePath newtype to prevent String misuse for bundle paths.
//
// How & Why: One file for all response types that don't belong to a specific
// model. BundlePath is a newtype wrapper — 5 lines that prevent passing an
// arbitrary string where a bundle path is expected. Response types match
// the CLI JSON spec (dispatch #23) exactly. CLIErrorResponse handles
// structured error output from stderr with typed details per error kind.
//
// Written: 2026-04-06 Phase 1A model alignment (CLI JSON spec dispatch #23)

import Foundation

// MARK: - BundlePath

/// Newtype wrapper for bundle path strings.
/// Prevents accidental misuse of arbitrary strings as bundle paths.
public struct BundlePath: Sendable, Hashable {
    public let path: String
    public init(_ path: String) { self.path = path }
}

// MARK: - Mutation Response Types

/// Response from `mdpal edit <slug>`.
public struct EditResult: Codable, Hashable {
    public let slug: String
    public let versionHash: String
    public let versionId: String
    public let bytesWritten: Int

    public init(slug: String, versionHash: String, versionId: String, bytesWritten: Int) {
        self.slug = slug
        self.versionHash = versionHash
        self.versionId = versionId
        self.bytesWritten = bytesWritten
    }
}

/// Response from `mdpal resolve <commentId>`.
public struct ResolveResult: Codable, Hashable {
    public let commentId: String
    public let resolved: Bool
    public let resolution: Resolution

    public init(commentId: String, resolved: Bool, resolution: Resolution) {
        self.commentId = commentId
        self.resolved = resolved
        self.resolution = resolution
    }
}

/// Response from `mdpal flag <slug>`.
public struct FlagResult: Codable, Hashable {
    public let slug: String
    public let flagged: Bool
    public let author: String
    public let note: String?
    public let timestamp: Date

    public init(slug: String, flagged: Bool, author: String, note: String?, timestamp: Date) {
        self.slug = slug
        self.flagged = flagged
        self.author = author
        self.note = note
        self.timestamp = timestamp
    }
}

/// Response from `mdpal clear-flag <slug>`.
public struct ClearFlagResult: Codable, Hashable {
    public let slug: String
    public let flagged: Bool

    public init(slug: String, flagged: Bool) {
        self.slug = slug
        self.flagged = flagged
    }
}

// MARK: - Persistence Response Types (Phase 1C)

/// One revision in a bundle's history. Used both as the success shape of
/// `mdpal revision create` (latest == nil, since the create doesn't
/// emit it) and as the element shape of `mdpal history`'s revision list
/// (latest present).
public struct RevisionInfo: Codable, Hashable {
    public let versionId: String
    public let version: Int
    public let revision: Int
    public let timestamp: Date
    public let filePath: String
    /// Only set by `mdpal history` output — marks which revision the
    /// `latest.md` symlink currently points at. Nil for fresh-create.
    public let latest: Bool?

    public init(versionId: String, version: Int, revision: Int,
                timestamp: Date, filePath: String, latest: Bool? = nil) {
        self.versionId = versionId
        self.version = version
        self.revision = revision
        self.timestamp = timestamp
        self.filePath = filePath
        self.latest = latest
    }
}

/// Wrapper for `mdpal history <bundle>`. Service unwraps to the array.
public struct HistoryResponse: Codable {
    public let revisions: [RevisionInfo]
    public let count: Int
    public let currentVersion: Int

    public init(revisions: [RevisionInfo], count: Int, currentVersion: Int) {
        self.revisions = revisions
        self.count = count
        self.currentVersion = currentVersion
    }
}

/// Response from `mdpal version show <bundle>`.
public struct VersionInfo: Codable, Hashable {
    public let version: Int
    public let versionId: String
    public let revision: Int
    public let timestamp: Date

    public init(version: Int, versionId: String, revision: Int, timestamp: Date) {
        self.version = version
        self.versionId = versionId
        self.revision = revision
        self.timestamp = timestamp
    }
}

/// Response from `mdpal version bump <bundle>`. Separate type from
/// `VersionInfo` because `previousVersion` is only meaningful on bump.
public struct VersionBumpResult: Codable, Hashable {
    public let previousVersion: Int
    public let version: Int
    public let versionId: String
    public let revision: Int
    public let timestamp: Date

    public init(previousVersion: Int, version: Int, versionId: String,
                revision: Int, timestamp: Date) {
        self.previousVersion = previousVersion
        self.version = version
        self.versionId = versionId
        self.revision = revision
        self.timestamp = timestamp
    }
}

// MARK: - List Response Wrappers

/// Wrapper for `mdpal comments` response.
public struct CommentsResponse: Codable {
    public let comments: [Comment]
    public let count: Int
    public let filters: CommentsFilters

    public init(comments: [Comment], count: Int, filters: CommentsFilters) {
        self.comments = comments
        self.count = count
        self.filters = filters
    }
}

/// Active filters in a comments response.
public struct CommentsFilters: Codable, Hashable {
    public let section: String?
    public let type: String?
    public let resolved: Bool?

    public init(section: String? = nil, type: String? = nil, resolved: Bool? = nil) {
        self.section = section
        self.type = type
        self.resolved = resolved
    }
}

/// Wrapper for `mdpal flags` response.
public struct FlagsResponse: Codable {
    public let flags: [Flag]
    public let count: Int

    public init(flags: [Flag], count: Int) {
        self.flags = flags
        self.count = count
    }
}

// MARK: - Error Types

/// Structured error response from CLI stderr.
///
/// Wire format per dispatch #23:
/// ```
/// {
///   "error": "versionConflict",
///   "message": "Section 'architecture' was modified...",
///   "details": {
///     "slug": "architecture",
///     "expectedHash": "c9d0e1f2",
///     ...
///   }
/// }
/// ```
///
/// The top-level `error` field is the discriminator that selects how
/// `details` is shaped. Older code in this file (Phase 1A) had the
/// discriminator inside `details` — that did NOT match dispatch #23 and
/// was rewritten in 1B.4 when envelope parsing got its first real
/// consumer (editSection's versionConflict mapping).
///
/// Decode-only by design: the app receives envelopes from the CLI but
/// never synthesizes them. If a future code path needs to emit an
/// envelope (e.g., a mock CLI in integration tests), add an explicit
/// Encodable conformance then; don't stumble into it by generics.
public struct CLIErrorResponse: Hashable {
    public let error: String
    public let message: String
    public let details: CLIErrorDetails?

    public init(error: String, message: String, details: CLIErrorDetails? = nil) {
        self.error = error
        self.message = message
        self.details = details
    }
}

extension CLIErrorResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case error, message, details
    }

    /// Custom decoder: reads outer `error` as discriminator, then routes
    /// `details` to the matching `CLIErrorDetails` case. An unknown
    /// `error` discriminator (or a known discriminator with a malformed
    /// details object) falls through to `.generic` — keeps the envelope
    /// forward-compatible with future error kinds AND preserves the
    /// `error`/`message` for the UI even when details are unparseable.
    ///
    /// Robustness notes:
    /// - `"details": null` is treated the same as omitted (`decodeNil`).
    /// - A known discriminator with missing/mistyped detail fields falls
    ///   through to `.generic` rather than blowing up the whole envelope:
    ///   one required field missing shouldn't make the entire error
    ///   invisible to the UI.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let errorTag = try container.decode(String.self, forKey: .error)
        let message = try container.decode(String.self, forKey: .message)

        let details: CLIErrorDetails?
        if container.contains(.details),
           (try? container.decodeNil(forKey: .details)) == false {
            // superDecoder scoped to the `details` node lets us pick
            // between typed-keyed decoding (known discriminators) and
            // dynamic [String: String] fallback (unknown) without
            // enumerating every possible key up front.
            let detailsDecoder = try container.superDecoder(forKey: .details)
            details = CLIErrorDetails.decodeOrGeneric(tag: errorTag, from: detailsDecoder)
        } else {
            details = nil
        }

        self.init(error: errorTag, message: message, details: details)
    }
}

/// Typed error details — enum with associated values per error kind.
///
/// Decoded by `CLIErrorResponse.init(from:)` using the outer `error` tag
/// as the discriminator. Not `Codable` on its own — the envelope owns
/// the discriminator so there's no ambiguity about where `type` lives.
public enum CLIErrorDetails: Hashable {
    case sectionNotFound(slug: String, availableSlugs: [String])
    case commentNotFound(commentId: String)
    case versionConflict(slug: String, expectedHash: String, currentHash: String,
                         currentContent: String, versionId: String)
    case bundleConflict(baseRevision: String, currentRevision: String)
    /// Catch-all for error kinds the app doesn't have typed decoding for
    /// yet (forward-compat) or envelopes with non-string detail values.
    case generic([String: String])

    /// Keys present inside a `details` object across the known error kinds.
    /// Internal because `CLIErrorResponse.init(from:)` is the only decoder.
    fileprivate enum DetailsKeys: String, CodingKey {
        case slug, availableSlugs, expectedHash, currentHash
        case currentContent, versionId, baseRevision, currentRevision
        case commentId
    }

    /// Decode the details payload into a typed case when the discriminator
    /// is known AND the expected fields are all present; otherwise fall
    /// back to `.generic` so the outer envelope stays usable.
    ///
    /// Non-throwing — the whole point is robustness at the envelope
    /// layer. Any decode failure is swallowed and the result is a best-
    /// effort `.generic([String: String])` capture.
    fileprivate static func decodeOrGeneric(
        tag: String,
        from decoder: Decoder
    ) -> CLIErrorDetails {
        switch tag {
        case "sectionNotFound":
            if let c = try? decoder.container(keyedBy: DetailsKeys.self),
               let slug = try? c.decode(String.self, forKey: .slug),
               let available = try? c.decode([String].self, forKey: .availableSlugs) {
                return .sectionNotFound(slug: slug, availableSlugs: available)
            }

        case "commentNotFound":
            if let c = try? decoder.container(keyedBy: DetailsKeys.self),
               let commentId = try? c.decode(String.self, forKey: .commentId) {
                return .commentNotFound(commentId: commentId)
            }

        case "versionConflict":
            if let c = try? decoder.container(keyedBy: DetailsKeys.self),
               let slug = try? c.decode(String.self, forKey: .slug),
               let expected = try? c.decode(String.self, forKey: .expectedHash),
               let current = try? c.decode(String.self, forKey: .currentHash),
               let content = try? c.decode(String.self, forKey: .currentContent),
               let versionId = try? c.decode(String.self, forKey: .versionId) {
                return .versionConflict(slug: slug, expectedHash: expected,
                                        currentHash: current, currentContent: content,
                                        versionId: versionId)
            }

        case "bundleConflict":
            if let c = try? decoder.container(keyedBy: DetailsKeys.self),
               let base = try? c.decode(String.self, forKey: .baseRevision),
               let current = try? c.decode(String.self, forKey: .currentRevision) {
                return .bundleConflict(baseRevision: base, currentRevision: current)
            }

        default:
            break // falls through to .generic below
        }

        // Fallback: decode the entire details object as a raw string-to-
        // string dictionary. Captures arbitrary keys (e.g., future
        // "quotaExceeded" with {"limit":"1000"}). Non-string values cause
        // the dictionary decode to throw — swallow and return .generic([:])
        // rather than fail the whole envelope. The `error`/`message` pair
        // remains available to the UI regardless.
        let dict = (try? [String: String](from: decoder)) ?? [:]
        return .generic(dict)
    }
}
