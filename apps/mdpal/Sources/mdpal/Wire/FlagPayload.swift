// What Problem: Engine's Flag has `sectionSlug`; spec uses `slug`. Plus
// the spec adds `flagged: true|false` boolean — present on every flag-
// related payload (single flag, list entries, clear-flag response).
//
// How & Why: FlagPayload mirrors the spec; FlagsListPayload and
// ClearFlagPayload are the wrapper types. Used by FlagCommand,
// FlagsCommand, and ClearFlagCommand.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.3)

import Foundation
import MarkdownPalEngine

/// Wire shape for a single flag, per spec. `flagged` is constant true
/// for any payload representing an existing flag.
///
/// Custom encode emits `note: null` explicitly when the flag has no
/// note (Swift's synthesized Encodable would omit the key, breaking
/// consumers that expect a stable shape).
struct FlagPayload: Encodable {
    let slug: String
    let flagged: Bool
    let author: String
    let note: String?
    let timestamp: Date

    init(from flag: Flag) {
        self.slug = flag.sectionSlug
        self.flagged = true
        self.author = flag.author
        self.note = flag.note
        self.timestamp = flag.timestamp
    }

    private enum CodingKeys: String, CodingKey {
        case slug, flagged, author, note, timestamp
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(slug, forKey: .slug)
        try c.encode(flagged, forKey: .flagged)
        try c.encode(author, forKey: .author)
        if let note { try c.encode(note, forKey: .note) }
        else { try c.encodeNil(forKey: .note) }
        try c.encode(timestamp, forKey: .timestamp)
    }
}

/// Wire shape for `mdpal flags`. Listing payload entries DON'T carry
/// `flagged: true` — the surrounding payload makes it implicit. Per
/// spec the list items are just slug + author + note + timestamp.
struct FlagListEntryPayload: Encodable {
    let slug: String
    let author: String
    let note: String?
    let timestamp: Date

    init(from flag: Flag) {
        self.slug = flag.sectionSlug
        self.author = flag.author
        self.note = flag.note
        self.timestamp = flag.timestamp
    }

    private enum CodingKeys: String, CodingKey {
        case slug, author, note, timestamp
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(slug, forKey: .slug)
        try c.encode(author, forKey: .author)
        if let note { try c.encode(note, forKey: .note) }
        else { try c.encodeNil(forKey: .note) }
        try c.encode(timestamp, forKey: .timestamp)
    }
}

struct FlagsListPayload: Encodable {
    let flags: [FlagListEntryPayload]
    let count: Int
}

/// Wire shape for `mdpal clear-flag` response per spec.
struct ClearFlagPayload: Encodable {
    let slug: String
    let flagged: Bool  // always false here
}
