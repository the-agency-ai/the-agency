// What Problem: Markdown image sources come from untrusted .md files. A deck
// can reference `../../../secret.png`, a symlink pointing outside the deck, or
// a sibling directory whose name merely shares a prefix with the deck folder.
// Contract §11 says such references must be refused, not rendered. The check
// previously lived inside ImageBlockView as a private method, which made it
// both untestable and wrong (a bare string hasPrefix).
//
// How & Why: Pulled out as a pure, public function so the containment rule can
// be unit-tested without instantiating a SwiftUI view. Containment is decided
// on path *components*, not string prefixes — `/deck` must not be considered a
// parent of `/deck-private`. Both sides are symlink-resolved first, so a
// symlink inside the deck cannot smuggle in a file from elsewhere.
//
// Written: 2026-08-07 during mdslidepal-mac PR-prep QG — extracted from
// ImageBlockView to fix the sibling-prefix escape and give contract §11 a test.

import Foundation

/// Resolves markdown image sources to URLs, enforcing contract §11 containment.
public enum ImagePathResolver {

    /// Resolve an image `source` relative to the markdown file at `sourceURL`.
    ///
    /// Returns `nil` when the source is empty, when a local path is given but
    /// no base is known, or when the resolved path escapes the base directory.
    /// Remote `http`/`https` sources are returned as-is.
    public static func resolve(source: String?, relativeTo sourceURL: URL?) -> URL? {
        guard let source, !source.isEmpty else { return nil }

        // Remote URL — no containment rule applies.
        if source.hasPrefix("http://") || source.hasPrefix("https://") {
            return URL(string: source)
        }

        // Local path — resolve relative to the source .md file. With no base
        // there is nothing to contain the path against, so refuse rather than
        // fall back to an unvalidated location.
        guard let baseURL = sourceURL?.deletingLastPathComponent() else {
            return nil
        }

        let base = baseURL.standardized.resolvingSymlinksInPath()
        let resolved = baseURL.appendingPathComponent(source)
            .standardized
            .resolvingSymlinksInPath()

        guard isContained(resolved, in: base) else { return nil }
        return resolved
    }

    /// True when `url` is the base directory itself or sits beneath it.
    ///
    /// Compares path components so that `/decks` is not treated as a parent of
    /// `/decks-private` — the failure mode of a plain string prefix test.
    public static func isContained(_ url: URL, in base: URL) -> Bool {
        let baseComponents = base.pathComponents
        let urlComponents = url.pathComponents
        guard urlComponents.count >= baseComponents.count else { return false }
        return Array(urlComponents.prefix(baseComponents.count)) == baseComponents
    }
}
