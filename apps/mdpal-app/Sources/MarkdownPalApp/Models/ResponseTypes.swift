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
public struct CLIErrorResponse: Codable {
    public let error: String
    public let message: String
    public let details: CLIErrorDetails?

    public init(error: String, message: String, details: CLIErrorDetails? = nil) {
        self.error = error
        self.message = message
        self.details = details
    }
}

/// Typed error details — enum with associated values per error kind.
public enum CLIErrorDetails: Codable, Hashable {
    case sectionNotFound(slug: String, availableSlugs: [String])
    case versionConflict(slug: String, expectedHash: String, currentHash: String,
                         currentContent: String, versionId: String)
    case bundleConflict(baseRevision: String, currentRevision: String)
    case generic([String: String])

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case type, slug, availableSlugs, expectedHash, currentHash
        case currentContent, versionId, baseRevision, currentRevision, data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "sectionNotFound":
            let slug = try container.decode(String.self, forKey: .slug)
            let available = try container.decode([String].self, forKey: .availableSlugs)
            self = .sectionNotFound(slug: slug, availableSlugs: available)

        case "versionConflict":
            let slug = try container.decode(String.self, forKey: .slug)
            let expected = try container.decode(String.self, forKey: .expectedHash)
            let current = try container.decode(String.self, forKey: .currentHash)
            let content = try container.decode(String.self, forKey: .currentContent)
            let versionId = try container.decode(String.self, forKey: .versionId)
            self = .versionConflict(slug: slug, expectedHash: expected,
                                    currentHash: current, currentContent: content,
                                    versionId: versionId)

        case "bundleConflict":
            let base = try container.decode(String.self, forKey: .baseRevision)
            let current = try container.decode(String.self, forKey: .currentRevision)
            self = .bundleConflict(baseRevision: base, currentRevision: current)

        default:
            let data = try container.decodeIfPresent([String: String].self, forKey: .data) ?? [:]
            self = .generic(data)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .sectionNotFound(let slug, let available):
            try container.encode("sectionNotFound", forKey: .type)
            try container.encode(slug, forKey: .slug)
            try container.encode(available, forKey: .availableSlugs)

        case .versionConflict(let slug, let expected, let current, let content, let versionId):
            try container.encode("versionConflict", forKey: .type)
            try container.encode(slug, forKey: .slug)
            try container.encode(expected, forKey: .expectedHash)
            try container.encode(current, forKey: .currentHash)
            try container.encode(content, forKey: .currentContent)
            try container.encode(versionId, forKey: .versionId)

        case .bundleConflict(let base, let current):
            try container.encode("bundleConflict", forKey: .type)
            try container.encode(base, forKey: .baseRevision)
            try container.encode(current, forKey: .currentRevision)

        case .generic(let data):
            try container.encode("generic", forKey: .type)
            try container.encode(data, forKey: .data)
        }
    }
}
