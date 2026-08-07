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

    /// Pre-process a YAML body string to quote unquoted hex-color values.
    /// Converts `key: #abc123` → `key: "#abc123"` so that YAML does not
    /// interpret the `#` as a comment start. Leaves already-quoted values
    /// and full-line comments untouched. Handles 3/4/6/8 hex digits.
    private static func quoteUnquotedHexValues(in yaml: String) -> String {
        // Match a mapping line: optional leading whitespace, a key, `:`, spaces,
        // then an unquoted `#` followed by 3–8 hex digits, optional trailing ws.
        let pattern = #"(?m)^(\s*[^:\r\n#]+:\s*)(#[0-9A-Fa-f]{3,8})(\s*(?:#[^\r\n]*)?)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return yaml
        }
        let range = NSRange(yaml.startIndex..., in: yaml)
        return regex.stringByReplacingMatches(
            in: yaml,
            range: range,
            withTemplate: "$1\"$2\"$3"
        )
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
