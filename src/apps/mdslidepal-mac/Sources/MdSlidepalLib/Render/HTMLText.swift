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
// Updated: 2026-08-12 PR-prep QG — de-ambiguated the break-only pattern (nested
//   `\s*` made it exponential on untrusted input), taught stripTags to remove
//   comments, <script> and <style> with their contents (a `>` inside a comment
//   used to leak onto the slide), and made lineBreakCount report a true count
//   instead of clamping to 1.

import Foundation

/// Shared rules for the small subset of HTML the slide renderer interprets.
public enum HTMLText {

    /// True when `html` consists solely of one or more `<br>` tags and
    /// whitespace. Case- and spelling-insensitive: `<BR>`, `<br/>`, `<br />`
    /// and repeats all qualify.
    public static func isLineBreakOnly(_ html: String) -> Bool {
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        // The leading `\s*` is hoisted out of the repeated group deliberately.
        // With it inside, each repetition begins *and* ends with `\s*`, so a run
        // of spaces between two `<br>`s can be divided between the two in many
        // ways; a non-matching suffix then forces the engine through all of them
        // (exponential backtracking on untrusted slide HTML). Anchoring each
        // repetition at a literal `<` removes the ambiguity. The language matched
        // is identical.
        return trimmed.range(
            of: "\\A\\s*(<br\\s*/?>\\s*)+\\z",
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

    /// Number of `<br>` tags in `html`. A true count — zero when there are none.
    /// Callers that need a floor (a break-only block always contributes some
    /// space) clamp at their own call site.
    public static func lineBreakCount(_ html: String) -> Int {
        html.ranges(
            of: "<br\\s*/?>",
            options: [.regularExpression, .caseInsensitive]
        ).count
    }

    /// Strip all HTML tags, leaving the text content.
    ///
    /// Comments, `<script>` and `<style>` go first, contents and all. A plain
    /// `<[^>]+>` pass stops at the first `>`, so `<!-- ARR > 2M -->` leaks
    /// ` 2M -->` onto the slide and `<script>alert(1)</script>` leaks its body.
    public static func stripTags(_ html: String) -> String {
        var result = html
        for pattern in [
            "<!--[\\s\\S]*?-->",
            "<script\\b[^>]*>[\\s\\S]*?</script\\s*>",
            "<style\\b[^>]*>[\\s\\S]*?</style\\s*>"
        ] {
            result = result.replacingOccurrences(
                of: pattern, with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        return result.replacingOccurrences(
            of: "<[^>]+>", with: "", options: .regularExpression
        )
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
