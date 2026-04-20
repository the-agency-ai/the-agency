// What Problem: Section content is displayed as plain text, but reviewers
// need to see Markdown formatting — headings, bold/italic, code blocks,
// lists, links — to read the document naturally. Without rendering,
// reviewers must mentally parse raw Markdown syntax.
//
// How & Why: Block-level splitting + SwiftUI native rendering. The content
// is split into blocks (paragraphs, code blocks, blockquotes, lists,
// thematic breaks) and each block renders with appropriate styling.
// Paragraphs use AttributedString(markdown:) for inline formatting (bold,
// italic, code, links). Code blocks get monospaced font + background.
// This approach avoids WebView overhead and stays within SwiftUI's
// rendering pipeline for native feel and accessibility.
//
// Not a full CommonMark renderer — covers the 80% case for document review.
// The engine (mdpal-cli) uses swift-markdown for full AST parsing; the app
// does visual presentation of already-parsed content.
//
// Written: 2026-04-05 during mdpal-app Phase 1 (Markdown rendering)

import SwiftUI

// MARK: - Block Model

/// A discrete block of Markdown content for rendering.
enum MarkdownBlock: Identifiable {
    case paragraph(String)
    case codeBlock(language: String?, code: String)
    case blockquote(String)
    case heading(level: Int, text: String)
    case unorderedList([String])
    case orderedList([(Int, String)])
    case thematicBreak
    case table(header: [String], rows: [[String]])

    var id: String {
        switch self {
        case .paragraph(let t): return "p-\(t.hashValue)"
        case .codeBlock(_, let c): return "code-\(c.hashValue)"
        case .blockquote(let t): return "bq-\(t.hashValue)"
        case .heading(let l, let t): return "h\(l)-\(t.hashValue)"
        case .unorderedList(let items): return "ul-\(items.hashValue)"
        case .orderedList(let items): return "ol-\(items.map(\.1).hashValue)"
        case .thematicBreak: return "hr-\(Int.random(in: 0..<Int.max))"
        case .table(let h, _): return "tbl-\(h.hashValue)"
        }
    }
}

// MARK: - Block Parser

/// Splits raw Markdown text into renderable blocks.
///
/// This is a lightweight block-level splitter, not a full CommonMark parser.
/// It handles the common patterns found in structured documents:
/// headings, code blocks, blockquotes, lists, tables, and thematic breaks.
/// Everything else is treated as a paragraph with inline Markdown support.
enum MarkdownBlockParser {

    static func parse(_ content: String) -> [MarkdownBlock] {
        let lines = content.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Empty line — skip
            if trimmed.isEmpty {
                index += 1
                continue
            }

            // Fenced code block
            if trimmed.hasPrefix("```") {
                let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                let lang = language.isEmpty ? nil : language
                var codeLines: [String] = []
                index += 1
                while index < lines.count {
                    if lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        index += 1
                        break
                    }
                    codeLines.append(lines[index])
                    index += 1
                }
                blocks.append(.codeBlock(language: lang, code: codeLines.joined(separator: "\n")))
                continue
            }

            // ATX heading (# through ######)
            if let headingMatch = parseHeading(trimmed) {
                blocks.append(.heading(level: headingMatch.0, text: headingMatch.1))
                index += 1
                continue
            }

            // Thematic break (---, ***, ___)
            if isThematicBreak(trimmed) {
                blocks.append(.thematicBreak)
                index += 1
                continue
            }

            // Blockquote
            if trimmed.hasPrefix(">") {
                var quoteLines: [String] = []
                while index < lines.count {
                    let l = lines[index].trimmingCharacters(in: .whitespaces)
                    if l.hasPrefix(">") {
                        let stripped = String(l.dropFirst()).trimmingCharacters(in: .whitespaces)
                        quoteLines.append(stripped)
                        index += 1
                    } else if l.isEmpty {
                        break
                    } else {
                        break
                    }
                }
                blocks.append(.blockquote(quoteLines.joined(separator: "\n")))
                continue
            }

            // Unordered list (- or * or + prefix)
            if isUnorderedListItem(trimmed) {
                var items: [String] = []
                while index < lines.count {
                    let l = lines[index].trimmingCharacters(in: .whitespaces)
                    if isUnorderedListItem(l) {
                        items.append(stripListMarker(l))
                        index += 1
                    } else if l.isEmpty {
                        break
                    } else if l.hasPrefix("  ") || l.hasPrefix("\t") {
                        // Continuation line
                        if !items.isEmpty {
                            items[items.count - 1] += " " + l.trimmingCharacters(in: .whitespaces)
                        }
                        index += 1
                    } else {
                        break
                    }
                }
                blocks.append(.unorderedList(items))
                continue
            }

            // Ordered list (1. 2. etc.)
            if isOrderedListItem(trimmed) {
                var items: [(Int, String)] = []
                while index < lines.count {
                    let l = lines[index].trimmingCharacters(in: .whitespaces)
                    if let orderedItem = parseOrderedListItem(l) {
                        items.append(orderedItem)
                        index += 1
                    } else if l.isEmpty {
                        break
                    } else if l.hasPrefix("  ") || l.hasPrefix("\t") {
                        if !items.isEmpty {
                            items[items.count - 1].1 += " " + l.trimmingCharacters(in: .whitespaces)
                        }
                        index += 1
                    } else {
                        break
                    }
                }
                blocks.append(.orderedList(items))
                continue
            }

            // Table (pipe-delimited)
            if trimmed.contains("|") && index + 1 < lines.count {
                let nextLine = lines[index + 1].trimmingCharacters(in: .whitespaces)
                if isTableSeparator(nextLine) {
                    let header = parseTableRow(trimmed)
                    var rows: [[String]] = []
                    index += 2 // skip header + separator
                    while index < lines.count {
                        let l = lines[index].trimmingCharacters(in: .whitespaces)
                        if l.contains("|") && !l.isEmpty {
                            rows.append(parseTableRow(l))
                            index += 1
                        } else {
                            break
                        }
                    }
                    blocks.append(.table(header: header, rows: rows))
                    continue
                }
            }

            // Default: paragraph (collect consecutive non-empty, non-special lines)
            var paragraphLines: [String] = []
            while index < lines.count {
                let l = lines[index]
                let lt = l.trimmingCharacters(in: .whitespaces)
                if lt.isEmpty || lt.hasPrefix("```") || lt.hasPrefix("#") ||
                   lt.hasPrefix(">") || isThematicBreak(lt) ||
                   isUnorderedListItem(lt) || isOrderedListItem(lt) {
                    break
                }
                // Check for table start
                if lt.contains("|") && index + 1 < lines.count {
                    let nextL = lines[index + 1].trimmingCharacters(in: .whitespaces)
                    if isTableSeparator(nextL) { break }
                }
                paragraphLines.append(l)
                index += 1
            }
            if !paragraphLines.isEmpty {
                blocks.append(.paragraph(paragraphLines.joined(separator: "\n")))
            }
        }

        return blocks
    }

    // MARK: - Helpers

    private static func parseHeading(_ line: String) -> (Int, String)? {
        var level = 0
        for ch in line {
            if ch == "#" { level += 1 }
            else { break }
        }
        guard level >= 1 && level <= 6 else { return nil }
        let rest = String(line.dropFirst(level)).trimmingCharacters(in: .whitespaces)
        guard !rest.isEmpty else { return nil }
        return (level, rest)
    }

    private static func isThematicBreak(_ line: String) -> Bool {
        let stripped = line.replacingOccurrences(of: " ", with: "")
        if stripped.count >= 3 {
            if stripped.allSatisfy({ $0 == "-" }) { return true }
            if stripped.allSatisfy({ $0 == "*" }) { return true }
            if stripped.allSatisfy({ $0 == "_" }) { return true }
        }
        return false
    }

    private static func isUnorderedListItem(_ line: String) -> Bool {
        return line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ")
    }

    private static func stripListMarker(_ line: String) -> String {
        if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
            return String(line.dropFirst(2))
        }
        return line
    }

    private static func isOrderedListItem(_ line: String) -> Bool {
        return parseOrderedListItem(line) != nil
    }

    private static func parseOrderedListItem(_ line: String) -> (Int, String)? {
        // Match: digits followed by ". " or ") "
        var digits = ""
        for ch in line {
            if ch.isNumber { digits.append(ch) }
            else { break }
        }
        guard !digits.isEmpty, let num = Int(digits) else { return nil }
        let rest = String(line.dropFirst(digits.count))
        if rest.hasPrefix(". ") {
            return (num, String(rest.dropFirst(2)))
        }
        if rest.hasPrefix(") ") {
            return (num, String(rest.dropFirst(2)))
        }
        return nil
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        let cleaned = line.replacingOccurrences(of: " ", with: "")
        // Must contain pipes and dashes, possibly colons for alignment
        let validChars = Set<Character>(["|", "-", ":"])
        return !cleaned.isEmpty && cleaned.allSatisfy { validChars.contains($0) }
    }

    private static func parseTableRow(_ line: String) -> [String] {
        var row = line
        // Strip leading/trailing pipes
        if row.hasPrefix("|") { row = String(row.dropFirst()) }
        if row.hasSuffix("|") { row = String(row.dropLast()) }
        return row.components(separatedBy: "|").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
    }
}

// MARK: - Markdown Content View

/// Renders Markdown content as native SwiftUI views.
///
/// Splits the raw Markdown text into blocks (paragraphs, code blocks,
/// headings, lists, blockquotes, tables, thematic breaks) and renders
/// each with appropriate styling. Inline Markdown (bold, italic, code,
/// links) is handled by AttributedString(markdown:).
public struct MarkdownContentView: View {
    let content: String

    public init(content: String) {
        self.content = content
    }

    public var body: some View {
        let blocks = MarkdownBlockParser.parse(content)
        VStack(alignment: .leading, spacing: 12) {
            ForEach(blocks) { block in
                blockView(for: block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block {
        case .paragraph(let text):
            paragraphView(text)

        case .codeBlock(let language, let code):
            codeBlockView(language: language, code: code)

        case .blockquote(let text):
            blockquoteView(text)

        case .heading(let level, let text):
            headingView(level: level, text: text)

        case .unorderedList(let items):
            unorderedListView(items)

        case .orderedList(let items):
            orderedListView(items)

        case .thematicBreak:
            Divider()
                .padding(.vertical, 4)

        case .table(let header, let rows):
            tableView(header: header, rows: rows)
        }
    }

    // MARK: - Block Renderers

    private func paragraphView(_ text: String) -> some View {
        Group {
            if let attributed = try? AttributedString(markdown: text,
                    options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                Text(attributed)
                    .font(.body)
                    .textSelection(.enabled)
            } else {
                Text(text)
                    .font(.body)
                    .textSelection(.enabled)
            }
        }
    }

    private func codeBlockView(language: String?, code: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let lang = language {
                Text(lang)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }

            Text(code)
                .font(.body.monospaced())
                .textSelection(.enabled)
                .padding(.horizontal, 12)
                .padding(.vertical, language != nil ? 8 : 12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }

    private func blockquoteView(_ text: String) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(.blue.opacity(0.4))
                .frame(width: 3)

            Group {
                if let attributed = try? AttributedString(markdown: text,
                        options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                    Text(attributed)
                        .font(.body.italic())
                        .foregroundStyle(.secondary)
                } else {
                    Text(text)
                        .font(.body.italic())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 12)
            .padding(.vertical, 4)
        }
        .padding(.leading, 4)
    }

    private func headingView(level: Int, text: String) -> some View {
        Group {
            if let attributed = try? AttributedString(markdown: text,
                    options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                Text(attributed)
                    .font(fontForHeading(level))
                    .fontWeight(.bold)
            } else {
                Text(text)
                    .font(fontForHeading(level))
                    .fontWeight(.bold)
            }
        }
        .padding(.top, level <= 2 ? 8 : 4)
    }

    private func fontForHeading(_ level: Int) -> Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        case 3: return .title3
        case 4: return .headline
        default: return .subheadline
        }
    }

    private func unorderedListView(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    if let attributed = try? AttributedString(markdown: item,
                            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                        Text(attributed)
                            .font(.body)
                    } else {
                        Text(item)
                            .font(.body)
                    }
                }
            }
        }
        .padding(.leading, 8)
    }

    private func orderedListView(_ items: [(Int, String)]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(item.0).")
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 20, alignment: .trailing)
                    if let attributed = try? AttributedString(markdown: item.1,
                            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                        Text(attributed)
                            .font(.body)
                    } else {
                        Text(item.1)
                            .font(.body)
                    }
                }
            }
        }
        .padding(.leading, 8)
    }

    private func tableView(header: [String], rows: [[String]]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                ForEach(Array(header.enumerated()), id: \.offset) { idx, cell in
                    Text(cell)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    if idx < header.count - 1 {
                        Divider()
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Data rows
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { idx, cell in
                        Text(cell)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        if idx < row.count - 1 {
                            Divider()
                        }
                    }
                }
                if rowIdx < rows.count - 1 {
                    Divider()
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
