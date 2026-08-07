// What Problem: "is this HTML just a line break?" was answered in two places
// with two different rules. HTMLBlockView matched three literal lowercase
// spellings by string replacement, so `<BR>` or `<br  />` fell through to the
// tag stripper and rendered as nothing — the intended vertical space silently
// vanished. InlineContentView used a lowercased `hasPrefix("<br")` instead.
// Two answers to one question, and neither was testable on its own.
//
// How & Why: One helper, one rule, used by both call sites. Detection is a
// case-insensitive regex so every spelling HTML permits — `<BR>`, `<br/>`,
// `<br   />`, and runs of them — is treated alike. Kept as free functions on an
// enum namespace so the rules can be unit-tested without building a view.
//
// Written: 2026-08-07 during mdslidepal-mac PR-prep QG — consolidates the two
// divergent <br> implementations found in SlideView.

import Foundation

/// Shared rules for the small subset of HTML the slide renderer interprets.
public enum HTMLText {

    /// True when `html` consists solely of one or more `<br>` tags and
    /// whitespace. Case- and spelling-insensitive: `<BR>`, `<br/>`, `<br />`
    /// and repeats all qualify.
    public static func isLineBreakOnly(_ html: String) -> Bool {
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed.range(
            of: "\\A(\\s*<br\\s*/?>\\s*)+\\z",
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    /// True when a single inline HTML node is a line break.
    public static func isLineBreak(_ html: String) -> Bool {
        html.trimmingCharacters(in: .whitespacesAndNewlines).range(
            of: "\\A<br\\s*/?>\\z",
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    /// Number of `<br>` tags in `html` — drives how much vertical space a
    /// break-only block contributes.
    public static func lineBreakCount(_ html: String) -> Int {
        let matches = html.ranges(
            of: "<br\\s*/?>",
            options: [.regularExpression, .caseInsensitive]
        )
        return max(1, matches.count)
    }

    /// Strip all HTML tags, leaving the text content.
    public static func stripTags(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

private extension String {
    /// All ranges matching `pattern` — Foundation has no batch `ranges(of:)`
    /// for regex options on this deployment target, so walk the string.
    func ranges(of pattern: String, options: String.CompareOptions) -> [Range<String.Index>] {
        var result: [Range<String.Index>] = []
        var searchStart = startIndex
        while searchStart < endIndex,
              let found = range(of: pattern, options: options, range: searchStart..<endIndex) {
            result.append(found)
            searchStart = found.upperBound > found.lowerBound ? found.upperBound : index(after: found.lowerBound)
        }
        return result
    }
}
