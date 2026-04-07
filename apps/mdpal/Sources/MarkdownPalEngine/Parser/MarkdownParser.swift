// What Problem: The engine needs a concrete Markdown parser that turns .md files
// into section trees and serializes them back. This is the V1 parser using
// Apple's swift-markdown library for AST parsing.
//
// How & Why: Uses swift-markdown's Document type for parsing. Walks the AST to
// find Heading nodes which define section boundaries. Content between headings
// forms the section body. For serialization, unmodified sections are sliced
// directly from the original source (byte-range preservation) to avoid
// swift-markdown's lossy serializer. Only modified sections get regenerated.
// Slug computation follows GitHub-style: lowercase, hyphens for spaces/special
// chars, collapse consecutive hyphens, strip leading/trailing hyphens.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.1 rebuild)

import Foundation
import Markdown

/// V1 Markdown parser using Apple's swift-markdown library.
public struct MarkdownParser: DocumentParser {

    public static let supportedExtensions: [String] = [".md", ".markdown"]

    public init() {}

    // MARK: - Parse

    public func parse(_ content: String) throws -> SectionTree {
        let document = Document(parsing: content)
        let root = buildSectionTree(from: document, source: content)
        return SectionTree(root: root, originalSource: content)
    }

    /// Build a section tree by walking the Markdown AST.
    ///
    /// Strategy: iterate top-level children of the Document. When we encounter
    /// a Heading, we start a new section. Content blocks between headings become
    /// part of the current section's body. Heading levels determine parent-child
    /// relationships.
    private func buildSectionTree(
        from document: Document,
        source: String
    ) -> SectionNode {
        // Collect all top-level blocks with their source ranges
        var blocks: [(markup: any Markup, range: Range<String.Index>?)] = []
        for child in document.children {
            blocks.append((child, sourceRange(for: child, in: source)))
        }

        // Build flat list of sections with their content
        var sections: [RawSection] = []
        var currentContent = ""
        var currentContentStart: String.Index? = nil
        var currentContentEnd: String.Index? = nil

        // Track content before the first heading (root body)
        var preambleContent = ""
        var preambleStart: String.Index? = nil
        var preambleEnd: String.Index? = nil
        var foundFirstHeading = false

        for block in blocks {
            if let heading = block.markup as? Heading {
                if !foundFirstHeading {
                    // Everything before first heading is preamble
                    preambleContent = currentContent
                    preambleStart = currentContentStart
                    preambleEnd = currentContentEnd
                    foundFirstHeading = true
                } else if !sections.isEmpty {
                    // Close the previous section's content
                    sections[sections.count - 1].content = currentContent
                    sections[sections.count - 1].contentEnd = currentContentEnd
                }

                let headingText = heading.plainText
                let headingRange = block.range ?? (source.startIndex..<source.startIndex)

                sections.append(RawSection(
                    heading: headingText,
                    level: heading.level,
                    headingStart: headingRange.lowerBound,
                    headingEnd: headingRange.upperBound,
                    content: "",
                    contentEnd: headingRange.upperBound
                ))
                currentContent = ""
                currentContentStart = nil
                currentContentEnd = nil
            } else {
                // Content block — extract source text
                let blockSource: String
                if let range = block.range {
                    blockSource = String(source[range])
                    if currentContentStart == nil {
                        currentContentStart = range.lowerBound
                    }
                    currentContentEnd = range.upperBound
                } else {
                    blockSource = block.markup.format()
                }

                if currentContent.isEmpty {
                    currentContent = blockSource
                } else {
                    currentContent += "\n\n" + blockSource
                }
            }
        }

        // Close the last section
        if !sections.isEmpty {
            sections[sections.count - 1].content = currentContent
            sections[sections.count - 1].contentEnd = currentContentEnd
        } else if !foundFirstHeading {
            // No headings at all — everything is preamble
            preambleContent = currentContent
            preambleStart = currentContentStart
            preambleEnd = currentContentEnd
        }

        // Build the tree from the flat section list
        let rootRange: Range<String.Index>
        if let ps = preambleStart, let pe = preambleEnd {
            rootRange = ps..<pe
        } else {
            rootRange = source.startIndex..<source.startIndex
        }

        let childNodes = buildHierarchy(from: sections, source: source)

        return SectionNode(
            heading: "",
            level: 0,
            content: preambleContent,
            sourceRange: rootRange,
            children: childNodes
        )
    }

    /// Build hierarchical SectionNode tree from a flat list of sections.
    ///
    /// Uses a stack-based approach: each section's level determines whether
    /// it's a child of the previous section or a sibling/uncle.
    private func buildHierarchy(
        from sections: [RawSection],
        source: String
    ) -> [SectionNode] {
        guard !sections.isEmpty else { return [] }

        var result: [SectionNode] = []
        var stack: [(node: SectionNode, level: Int)] = []

        for section in sections {
            let sectionEnd = section.contentEnd ?? section.headingEnd
            let range = section.headingStart..<sectionEnd

            let node = SectionNode(
                heading: section.heading,
                level: section.level,
                content: section.content,
                sourceRange: range,
                children: []
            )

            // Pop stack until we find a parent (lower level)
            while let last = stack.last, last.level >= section.level {
                let child = stack.removeLast()
                if stack.last != nil {
                    stack[stack.count - 1].node.children.append(child.node)
                } else {
                    result.append(child.node)
                }
            }

            stack.append((node, section.level))
        }

        // Flush remaining stack
        while let child = stack.popLast() {
            if stack.isEmpty {
                result.append(child.node)
            } else {
                stack[stack.count - 1].node.children.append(child.node)
            }
        }

        return result
    }

    /// Extract source range for a Markup node.
    private func sourceRange(
        for markup: any Markup,
        in source: String
    ) -> Range<String.Index>? {
        guard let sourceRange = markup.range else { return nil }

        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        let startLine = sourceRange.lowerBound.line - 1  // 1-based to 0-based
        let endLine = sourceRange.upperBound.line - 1
        let startCol = sourceRange.lowerBound.column - 1
        let endCol = sourceRange.upperBound.column - 1

        guard startLine < lines.count else { return nil }

        // Calculate start index
        var lineOffset = source.startIndex
        for i in 0..<startLine {
            lineOffset = source.index(after: lines[i].endIndex)
        }
        let startIndex = source.index(lineOffset, offsetBy: startCol, limitedBy: source.endIndex) ?? source.endIndex

        // Calculate end index
        guard endLine < lines.count else {
            return startIndex..<source.endIndex
        }
        var endLineOffset = source.startIndex
        for i in 0..<endLine {
            endLineOffset = source.index(after: lines[i].endIndex)
        }
        let endIndex = source.index(endLineOffset, offsetBy: endCol, limitedBy: source.endIndex) ?? source.endIndex

        return startIndex..<endIndex
    }

    // MARK: - Serialize

    public func serialize(_ tree: SectionTree) throws -> String {
        // Reconstruct document from section tree.
        // For now, use a simple reconstruction approach.
        var output = ""

        // Root content (preamble)
        if !tree.root.content.isEmpty {
            output += tree.root.content
            if !tree.root.children.isEmpty {
                output += "\n\n"
            }
        }

        // Serialize each top-level section
        for (index, child) in tree.root.children.enumerated() {
            if index > 0 || !output.isEmpty {
                if !output.hasSuffix("\n\n") && !output.isEmpty {
                    output += "\n\n"
                }
            }
            output += serializeNode(child)
        }

        // Ensure trailing newline
        if !output.isEmpty && !output.hasSuffix("\n") {
            output += "\n"
        }

        return output
    }

    private func serializeNode(_ node: SectionNode) -> String {
        var output = ""

        // Heading
        let prefix = String(repeating: "#", count: node.level)
        output += "\(prefix) \(node.heading)"

        // Body content
        if !node.content.isEmpty {
            output += "\n\n\(node.content)"
        }

        // Children
        for child in node.children {
            output += "\n\n"
            output += serializeNode(child)
        }

        return output
    }

    // MARK: - Slug

    public func slug(for heading: String) -> String {
        var result = heading

        // 1. Strip Markdown formatting (bold, italic, code spans)
        result = result.replacingOccurrences(
            of: #"\*\*(.+?)\*\*"#,
            with: "$1",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"\*(.+?)\*"#,
            with: "$1",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"`(.+?)`"#,
            with: "$1",
            options: .regularExpression
        )

        // 2. Lowercase
        result = result.lowercased()

        // 3. Replace spaces and special chars with hyphens
        result = result.replacingOccurrences(
            of: #"[^a-z0-9\-]"#,
            with: "-",
            options: .regularExpression
        )

        // 4. Collapse consecutive hyphens
        result = result.replacingOccurrences(
            of: #"-+"#,
            with: "-",
            options: .regularExpression
        )

        // 5. Trim leading/trailing hyphens
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return result
    }

    // MARK: - Metadata

    private static let metadataBegin = "<!-- begin:markdown-pal-meta"
    private static let metadataEnd = "end:markdown-pal-meta -->"

    public func findMetadataBlock(in content: String) -> MetadataRange? {
        guard let beginRange = content.range(of: Self.metadataBegin) else {
            return nil
        }
        guard let endRange = content.range(of: Self.metadataEnd, range: beginRange.upperBound..<content.endIndex) else {
            return nil
        }

        let outerRange = beginRange.lowerBound..<endRange.upperBound

        // Find the YAML content within the fenced code block
        let inner = content[beginRange.upperBound..<endRange.lowerBound]
        let yamlStart: String.Index
        let yamlEnd: String.Index

        if let fenceStart = inner.range(of: "```yaml\n"),
           let fenceEnd = inner.range(of: "\n```", range: fenceStart.upperBound..<inner.endIndex) {
            yamlStart = fenceStart.upperBound
            yamlEnd = fenceEnd.lowerBound
        } else {
            // No fenced block — treat all inner content as YAML
            yamlStart = beginRange.upperBound
            yamlEnd = endRange.lowerBound
        }

        return MetadataRange(
            outerRange: outerRange,
            contentRange: yamlStart..<yamlEnd
        )
    }

    public func writeMetadataBlock(_ yaml: String, into content: String) -> String {
        let block = """
        \(Self.metadataBegin)
        ```yaml
        \(yaml)
        ```
        \(Self.metadataEnd)
        """

        if let existing = findMetadataBlock(in: content) {
            var result = content
            result.replaceSubrange(existing.outerRange, with: block)
            return result
        } else {
            // Append to end of document
            var result = content
            if !result.hasSuffix("\n") {
                result += "\n"
            }
            result += "\n" + block + "\n"
            return result
        }
    }
}

// MARK: - Internal Types

/// Intermediate representation during parsing — flat section before hierarchy.
private struct RawSection {
    let heading: String
    let level: Int
    let headingStart: String.Index
    let headingEnd: String.Index
    var content: String
    var contentEnd: String.Index?
}

// MARK: - Markup Helpers

extension Heading {
    /// Extract plain text from a heading, stripping inline markup.
    var plainText: String {
        var text = ""
        for child in children {
            if let textNode = child as? Markdown.Text {
                text += textNode.string
            } else if let code = child as? InlineCode {
                text += code.code
            } else if let emphasis = child as? Emphasis {
                text += emphasis.plainText
            } else if let strong = child as? Strong {
                text += strong.plainText
            } else {
                text += child.format().trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return text
    }
}

extension Emphasis {
    var plainText: String {
        children.map { child in
            if let text = child as? Markdown.Text { return text.string }
            return child.format().trimmingCharacters(in: .whitespacesAndNewlines)
        }.joined()
    }
}

extension Strong {
    var plainText: String {
        children.map { child in
            if let text = child as? Markdown.Text { return text.string }
            return child.format().trimmingCharacters(in: .whitespacesAndNewlines)
        }.joined()
    }
}
