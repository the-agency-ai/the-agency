// What Problem: Extract per-slide metadata from <!-- slide: ... --> HTML
// comment blocks (contract §3). These blocks are only recognized when they
// are the first non-whitespace content after a slide break.
//
// How & Why: For each slide, inspect the first child node. If it's an
// HTMLBlock matching the <!-- slide: ... --> pattern, parse the YAML body
// with Yams, extract reserved keys (background, transition, class), and
// attach as SlideMetadata. Remove the HTMLBlock from the slide's children
// so it doesn't render. Malformed blocks produce a warning diagnostic.
//
// Hex color values collide with YAML comment syntax: `background: #ff0000`
// parses as a key with an empty value followed by a comment. A pre-pass quotes
// unquoted `#`-prefixed hex values before handing the body to Yams, so authors
// can write the natural CSS form.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.6
// Updated: 2026-04-15 — hex-color YAML pre-quoting.
// Updated: 2026-08-12 PR-prep QG wave 2 — the single-regex pre-pass was both too
//   narrow (sequence items, flow collections and 1–2 digit values were dropped)
//   and too broad (its loose key group rewrote `foo: #abc` lines inside literal
//   block scalars). Replaced with a line walker that tracks block-scalar extent
//   and a tight key pattern.

import Foundation
import Markdown
import Yams

public struct SlideMetadataExtractor {

    /// Process slides to extract <!-- slide: ... --> metadata blocks.
    /// Returns updated slides with metadata attached and HTMLBlocks removed,
    /// plus any diagnostics.
    public static func extract(
        from slides: [Slide]
    ) -> (slides: [Slide], diagnostics: [Diagnostic]) {
        var diagnostics: [Diagnostic] = []
        let updatedSlides = slides.map { slide -> Slide in
            let (updated, diags) = extractMetadata(from: slide)
            diagnostics.append(contentsOf: diags)
            return updated
        }
        return (updatedSlides, diagnostics)
    }

    private static func extractMetadata(
        from slide: Slide
    ) -> (Slide, [Diagnostic]) {
        guard !slide.markupChildren.isEmpty else {
            return (slide, [])
        }

        // Look for an HTMLBlock as the first child
        guard let htmlBlock = slide.markupChildren.first as? HTMLBlock else {
            return (slide, [])
        }

        let raw = htmlBlock.rawHTML.trimmingCharacters(in: .whitespacesAndNewlines)

        // Match <!-- slide: ... --> pattern
        guard let yamlBody = extractSlideYAML(from: raw) else {
            return (slide, [])
        }

        // Parse YAML body (pre-process to quote unquoted hex-color values —
        // YAML treats # as a comment start, so `background: #ff0000` would
        // otherwise lose the value entirely).
        let preprocessed = quoteUnquotedHexValues(in: yamlBody)
        do {
            guard let yaml = try Yams.load(yaml: preprocessed) as? [String: Any] else {
                return (slide, [
                    Diagnostic(
                        severity: .warning,
                        message: "Slide metadata YAML is not a mapping; ignoring",
                        slideIndex: slide.id
                    )
                ])
            }

            let metadata = parseSlideMetadata(from: yaml)
            // Remove the HTMLBlock from children
            let remainingChildren = Array(slide.markupChildren.dropFirst())
            let updated = Slide(
                id: slide.id,
                markupChildren: remainingChildren,
                metadata: metadata,
                notes: slide.notes
            )
            return (updated, [])
        } catch {
            return (slide, [
                Diagnostic(
                    severity: .warning,
                    message: "Malformed slide metadata YAML: \(error.localizedDescription)",
                    slideIndex: slide.id
                )
            ])
        }
    }

    /// Extract the YAML body from a <!-- slide: ... --> comment.
    /// Returns the YAML string between "slide:" and "-->", or nil if not a match.
    private static func extractSlideYAML(from html: String) -> String? {
        // Pattern: <!-- slide:\n...\n-->
        // swift-markdown's rawHTML may include trailing newline — trim first
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("<!--") && trimmed.hasSuffix("-->") else {
            return nil
        }

        let inner = trimmed.dropFirst(4).dropLast(3)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard inner.hasPrefix("slide:") else {
            return nil
        }

        let yamlBody = String(inner.dropFirst(6))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return yamlBody.isEmpty ? nil : yamlBody
    }

    // MARK: - Hex-value pre-quoting

    /// A mapping line: indent, a plain scalar key, `:`, spaces, then the value.
    ///
    /// The key group is deliberately tight (`[\w.-]+`). The previous
    /// `[^:\r\n#]+` accepted anything without a colon, so a `foo: #abc` line
    /// *inside a literal block scalar* looked like a mapping and was rewritten,
    /// corrupting the multi-line value. A quoted or space-bearing key is not
    /// matched and its value is left alone — a deliberate trade for not
    /// re-implementing a YAML scanner here.
    private static let mappingLine = try? NSRegularExpression(
        pattern: #"^([ \t]*)([\w.-]+:)([ \t]*)(.*)$"#
    )

    /// A block-sequence item: indent, `-`, whitespace, then the item value.
    private static let sequenceItemLine = try? NSRegularExpression(
        pattern: #"^([ \t]*-)([ \t]+)(.*)$"#
    )

    /// A bare hex token occupying the whole value, with an optional trailing
    /// comment. 1–8 digits: `#ff` is not a valid CSS color, but quoting it keeps
    /// the author's text in `SlideMetadata.background` where `Color(validatingHex:)`
    /// rejects it and the slide falls back to the theme. Leaving it unquoted made
    /// it vanish into a YAML comment and the metadata read `nil` — a typo that
    /// reported nothing at all.
    private static let bareHexValue = try? NSRegularExpression(
        pattern: #"^(#[0-9A-Fa-f]{1,8})([ \t].*)?$"#
    )

    /// A hex token inside a flow collection: preceded by `[` or `,`, followed by
    /// `,` or `]`. `colors: [#ff0000, #00ff00]` otherwise loses both values.
    private static let flowHexValue = try? NSRegularExpression(
        pattern: #"([\[,][ \t]*)(#[0-9A-Fa-f]{1,8})(?=[ \t]*[,\]])"#
    )

    /// Pre-process a YAML body string to quote unquoted hex-color values.
    ///
    /// Converts `key: #abc123` → `key: "#abc123"` so that YAML does not
    /// interpret the `#` as a comment start. Also covers block-sequence items
    /// (`- #ff0000`) and flow collections (`colors: [#ff0000]`). Already-quoted
    /// values, full-line comments, and the interior of literal/folded block
    /// scalars are left untouched.
    ///
    /// Public because it is the whole of the workaround for a YAML/CSS syntax
    /// collision and needs to be pinned by tests independently of the parser.
    public static func quoteUnquotedHexValues(in yaml: String) -> String {
        var output: [String] = []
        // Interior of a `key: |` / `key: >` block scalar: everything indented
        // deeper than the introducing line is opaque text, not YAML.
        var blockScalarParentIndent: Int?

        for rawLine in yaml.components(separatedBy: "\n") {
            // Keep CRLF intact: strip the \r for matching, re-append on output.
            let hasCR = rawLine.hasSuffix("\r")
            let line = hasCR ? String(rawLine.dropLast()) : rawLine
            let emit: (String) -> Void = { output.append(hasCR ? $0 + "\r" : $0) }

            if let parentIndent = blockScalarParentIndent {
                if line.trimmingCharacters(in: .whitespaces).isEmpty
                    || indentWidth(of: line) > parentIndent {
                    emit(line)
                    continue
                }
                blockScalarParentIndent = nil
            }

            emit(rewriteLine(line, blockScalarParentIndent: &blockScalarParentIndent))
        }

        return output.joined(separator: "\n")
    }

    /// Number of leading space/tab characters.
    private static func indentWidth(of line: String) -> Int {
        line.prefix { $0 == " " || $0 == "\t" }.count
    }

    /// Rewrite one non-block-scalar line, opening a block scalar if the value
    /// turns out to be `|` or `>`.
    private static func rewriteLine(
        _ line: String, blockScalarParentIndent: inout Int?
    ) -> String {
        let full = NSRange(line.startIndex..., in: line)

        if let match = mappingLine?.firstMatch(in: line, range: full),
           match.range.length == full.length {
            let indent = substring(line, match.range(at: 1))
            let key = substring(line, match.range(at: 2))
            let gap = substring(line, match.range(at: 3))
            let value = substring(line, match.range(at: 4))

            if value.hasPrefix("|") || value.hasPrefix(">") {
                blockScalarParentIndent = indent.count
                return line
            }
            return indent + key + gap + quoteHex(in: value)
        }

        if let match = sequenceItemLine?.firstMatch(in: line, range: full),
           match.range.length == full.length {
            let bullet = substring(line, match.range(at: 1))
            let gap = substring(line, match.range(at: 2))
            let item = substring(line, match.range(at: 3))
            // `- key: #fff` is a mapping nested in a sequence — recurse so the
            // key/value split is handled by the mapping rule, not treated as a
            // scalar item.
            var nested: Int?
            let rewritten = item.contains(":")
                ? rewriteLine(item, blockScalarParentIndent: &nested)
                : quoteHex(in: item)
            if let nested {
                blockScalarParentIndent = bullet.count - 1 + gap.count + nested
            }
            return bullet + gap + rewritten
        }

        return line
    }

    /// Quote hex tokens inside a single YAML value.
    private static func quoteHex(in value: String) -> String {
        let range = NSRange(value.startIndex..., in: value)

        if let match = bareHexValue?.firstMatch(in: value, range: range),
           match.range.length == range.length {
            let hex = substring(value, match.range(at: 1))
            let trailing = match.range(at: 2).location == NSNotFound
                ? "" : substring(value, match.range(at: 2))
            return "\"\(hex)\"" + trailing
        }

        if value.hasPrefix("["), let flowHexValue {
            return flowHexValue.stringByReplacingMatches(
                in: value, range: range, withTemplate: "$1\"$2\""
            )
        }

        return value
    }

    private static func substring(_ string: String, _ range: NSRange) -> String {
        guard let swiftRange = Range(range, in: string) else { return "" }
        return String(string[swiftRange])
    }

    /// Parse a YAML dictionary into SlideMetadata.
    private static func parseSlideMetadata(from yaml: [String: Any]) -> SlideMetadata {
        var extra: [String: String] = [:]
        let reservedKeys: Set<String> = [
            "background", "transition", "class", "layout", "notes_file"
        ]

        for (key, value) in yaml where !reservedKeys.contains(key) {
            extra[key] = "\(value)"
        }

        return SlideMetadata(
            background: yaml["background"] as? String,
            transition: yaml["transition"] as? String,
            slideClass: yaml["class"] as? String,
            layout: yaml["layout"] as? String,
            extra: extra
        )
    }
}
