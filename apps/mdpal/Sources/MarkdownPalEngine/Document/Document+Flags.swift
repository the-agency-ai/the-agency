// What Problem: Iteration 1.3 adds the flag lifecycle on Document — set,
// list, clear. Flags are lightweight section bookmarks: a section slug, an
// optional note, an author, and a timestamp.
//
// How & Why: Flagging the same section twice replaces the existing flag
// (one flag per section per document — keeps things simple for V1). Clear
// throws sectionNotFlagged if no flag exists for the slug. Section
// validation ensures we don't flag non-existent sections.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.3)

import Foundation

extension Document {

    // MARK: - Flag

    /// Flag a section for discussion. Replaces any existing flag on the
    /// same section.
    ///
    /// - Throws: `.sectionNotFound` if no section matches the slug.
    @discardableResult
    public func flagSection(
        _ slug: String,
        author: String,
        note: String? = nil,
        timestamp: Date = Date()
    ) throws -> Flag {
        guard findNode(slug: slug) != nil else {
            throw EngineError.sectionNotFound(slug: slug, available: allSlugs())
        }
        // Validation passed; the underlying section node is unused beyond
        // existence — we just need confirmation that the slug resolves.
        let flag = Flag(sectionSlug: slug, note: note, author: author, timestamp: timestamp)
        // Remove any existing flag on the same section, then append.
        metadata.flags.removeAll { $0.sectionSlug == slug }
        metadata.flags.append(flag)
        return flag
    }

    // MARK: - List

    /// List all flags on the document.
    public func listFlags() -> [Flag] {
        metadata.flags
    }

    // MARK: - Clear

    /// Clear the flag on a section.
    ///
    /// - Throws: `.sectionNotFlagged` if no flag exists for the slug.
    public func clearFlag(_ slug: String) throws {
        guard let index = metadata.flags.firstIndex(where: { $0.sectionSlug == slug }) else {
            throw EngineError.sectionNotFlagged(slug: slug)
        }
        metadata.flags.remove(at: index)
    }
}
