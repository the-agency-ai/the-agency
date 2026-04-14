// What Problem: YAML front-matter at offset 0 of a markdown file must be
// stripped before passing to swift-markdown (which doesn't handle it natively).
// The closing --- of front-matter must NOT become a slide break (contract §1).
//
// How & Why: Pre-extraction: scan for leading --- at line 0, find the closing
// ---, extract the YAML body, parse with Yams. Returns the FrontMatter struct
// and the remaining markdown (everything after the closing ---). If no
// front-matter is detected, returns nil and the full source unchanged.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.3

import Foundation
import Yams

public struct FrontMatterExtractor {

    /// Result of front-matter extraction.
    public struct ExtractionResult {
        /// Parsed front-matter (nil if none detected).
        public let frontMatter: FrontMatter?
        /// The remaining markdown source after stripping front-matter.
        public let remainingSource: String
        /// Any diagnostics from parsing.
        public let diagnostics: [Diagnostic]
    }

    /// Extract YAML front-matter from the beginning of a markdown source.
    ///
    /// Front-matter is detected when the source starts with `---` at offset 0
    /// (no leading whitespace or BOM), contains at least one line of YAML content,
    /// and is terminated by a `---` line (contract §1 disambiguation rule).
    public static func extract(from source: String) -> ExtractionResult {
        // Normalize line endings to handle both \n and \r\n (Windows-style)
        let normalized = source.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        // Must start with --- at offset 0
        guard !lines.isEmpty, lines[0].trimmingCharacters(in: .whitespaces) == "---" else {
            return ExtractionResult(
                frontMatter: nil,
                remainingSource: source,
                diagnostics: []
            )
        }

        // Find the closing ---
        var closingIndex: Int? = nil
        for i in 1..<lines.count {
            if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
                closingIndex = i
                break
            }
        }

        guard let endIndex = closingIndex, endIndex > 1 else {
            // No closing --- found, or empty front-matter (--- immediately followed by ---)
            // Treat as no front-matter — the leading --- becomes a thematic break
            if let endIndex = closingIndex, endIndex == 1 {
                // Two adjacent --- lines at start: no front-matter, pass through
                return ExtractionResult(
                    frontMatter: nil,
                    remainingSource: source,
                    diagnostics: []
                )
            }
            return ExtractionResult(
                frontMatter: nil,
                remainingSource: source,
                diagnostics: []
            )
        }

        // Extract the YAML body between the two --- lines
        let yamlLines = lines[1..<endIndex]
        let yamlString = yamlLines.joined(separator: "\n")

        // The remaining source is everything after the closing ---
        let remainingLines = lines[(endIndex + 1)...]
        let remaining = remainingLines.joined(separator: "\n")

        // Parse YAML
        do {
            guard let yaml = try Yams.load(yaml: yamlString) as? [String: Any] else {
                return ExtractionResult(
                    frontMatter: nil,
                    remainingSource: source,
                    diagnostics: [
                        Diagnostic(
                            severity: .warning,
                            message: "Front-matter YAML is not a mapping; ignoring"
                        )
                    ]
                )
            }

            let fm = parseFrontMatter(from: yaml)
            return ExtractionResult(
                frontMatter: fm,
                remainingSource: remaining,
                diagnostics: []
            )
        } catch {
            return ExtractionResult(
                frontMatter: nil,
                remainingSource: remaining,
                diagnostics: [
                    Diagnostic(
                        severity: .warning,
                        message: "Invalid YAML front-matter: \(error.localizedDescription)"
                    )
                ]
            )
        }
    }

    /// Parse a YAML dictionary into a FrontMatter struct.
    private static func parseFrontMatter(from yaml: [String: Any]) -> FrontMatter {
        var meta: [String: String] = [:]
        let reservedKeys: Set<String> = [
            "title", "author", "theme", "date", "description", "footer"
        ]

        // Collect custom fields
        for (key, value) in yaml where !reservedKeys.contains(key) {
            meta[key] = "\(value)"
        }

        return FrontMatter(
            title: yaml["title"] as? String,
            author: yaml["author"] as? String,
            theme: yaml["theme"] as? String,
            date: yaml["date"] as? String,
            description: yaml["description"] as? String,
            footer: yaml["footer"] as? String,
            meta: meta
        )
    }
}
