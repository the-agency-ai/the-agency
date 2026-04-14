// What Problem: Render a single slide from its Markdown AST nodes using
// SwiftUI views themed by the current Theme. This is the core rendering
// engine — every AST node type maps to a SwiftUI view.
//
// How & Why: Walk the slide's markupChildren array and dispatch each node
// to its renderer (HeadingView, ParagraphView, CodeBlockView, etc.).
// Composed inside a VStack within the slide's logical dimensions (1920×1080)
// with theme-specified padding. The slide is rendered at logical size and
// scaled to fit the actual view size by the parent.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.5

import SwiftUI
import Markdown
import HighlightSwift

// Disambiguate SwiftUI.Text from Markdown.Text
private typealias MarkdownText = Markdown.Text
private typealias TextBlock = SwiftUI.Text

/// Renders a single slide's content from its AST nodes.
public struct SlideContentView: View {
    let slide: Slide
    var sourceURL: URL? = nil
    @Environment(\.theme) private var theme

    public init(slide: Slide, sourceURL: URL? = nil) {
        self.slide = slide
        self.sourceURL = sourceURL
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: CGFloat(theme.spacingUnit)) {
            ForEach(Array(slide.markupChildren.enumerated()), id: \.offset) { _, child in
                MarkupNodeView(node: child, sourceURL: sourceURL)
            }
            Spacer()
        }
        .padding(theme.slidePadding.edgeInsets)
        .frame(
            width: CGFloat(theme.logicalDimensions.width),
            height: CGFloat(theme.logicalDimensions.height),
            alignment: .topLeading
        )
        .background(slideBackground)
        .foregroundColor(Color(hex: theme.colors.foreground))
    }

    private var slideBackground: Color {
        if let bg = slide.metadata?.background {
            return Color(hex: bg)
        }
        return Color(hex: theme.colors.background)
    }
}

/// Dispatches a Markup node to its appropriate SwiftUI renderer.
struct MarkupNodeView: View {
    let node: Markup
    var sourceURL: URL? = nil
    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            if let heading = node as? Heading {
                HeadingView(heading: heading)
            } else if let paragraph = node as? Paragraph,
                      paragraph.childCount == 1,
                      let image = paragraph.child(at: 0) as? Markdown.Image {
                // Block-level image (paragraph containing only an image)
                ImageBlockView(image: image, sourceURL: sourceURL)
            } else if let paragraph = node as? Paragraph {
                ParagraphView(paragraph: paragraph)
            } else if let codeBlock = node as? CodeBlock {
                CodeBlockView(codeBlock: codeBlock)
            } else if let list = node as? UnorderedList {
                UnorderedListView(list: list)
            } else if let list = node as? OrderedList {
                OrderedListView(list: list)
            } else if let table = node as? Markdown.Table {
                TableBlockView(table: table)
            } else if let htmlBlock = node as? HTMLBlock {
                // HTML blocks that aren't slide metadata — render as code
                Text(htmlBlock.rawHTML)
                    .font(.system(size: CGFloat(theme.bodySize), design: .monospaced))
                    .foregroundColor(Color(hex: theme.colors.muted))
            } else if let blockQuote = node as? BlockQuote {
                BlockQuoteView(blockQuote: blockQuote)
            } else {
                // Fallback: render the formatted markdown as text
                Text(node.format())
                    .font(.system(size: CGFloat(theme.bodySize)))
            }
        }
    }
}

// MARK: - Heading

struct HeadingView: View {
    let heading: Heading
    @Environment(\.theme) private var theme

    var body: some View {
        InlineContentView(children: Array(heading.children))
            .font(.system(
                size: CGFloat(theme.headingScale.size(for: heading.level)),
                weight: .bold,
                design: .default
            ))
    }
}

// MARK: - Paragraph

struct ParagraphView: View {
    let paragraph: Paragraph
    @Environment(\.theme) private var theme

    var body: some View {
        InlineContentView(children: Array(paragraph.children))
            .font(.system(size: CGFloat(theme.bodySize)))
            .lineSpacing(CGFloat(theme.bodySize) * CGFloat(theme.lineHeight - 1.0))
    }
}

// MARK: - Code Block

struct CodeBlockView: View {
    let codeBlock: CodeBlock
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            if let language = highlightLanguage {
                CodeText(codeBlock.code.trimmingCharacters(in: .newlines))
                    .highlightLanguage(language)
                    .codeTextColors(.theme(.xcode))
                    .font(.system(size: CGFloat(theme.bodySize) * 0.75, design: .monospaced))
                    .padding(CGFloat(theme.spacingUnit))
            } else {
                // Fallback for unknown languages: plain monospace
                TextBlock(codeBlock.code.trimmingCharacters(in: .newlines))
                    .font(.system(size: CGFloat(theme.bodySize) * 0.75, design: .monospaced))
                    .foregroundColor(Color(hex: theme.codeTheme.foreground))
                    .padding(CGFloat(theme.spacingUnit))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: theme.codeTheme.background))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: theme.colors.codeBorder), lineWidth: 1)
        )
    }

    /// Map language string from markdown to HighlightSwift language enum.
    private var highlightLanguage: HighlightLanguage? {
        guard let lang = codeBlock.language?.lowercased() else { return nil }
        switch lang {
        case "bash", "sh", "zsh": return .bash
        case "shell": return .shell
        case "javascript", "js": return .javaScript
        case "typescript", "ts": return .typeScript
        case "python", "py": return .python
        case "swift": return .swift
        case "go", "golang": return .go
        case "rust", "rs": return .rust
        case "markdown", "md": return .markdown
        case "json": return .json
        case "yaml", "yml": return .yaml
        case "html": return .html
        case "css": return .css
        case "ruby", "rb": return .ruby
        case "java": return .java
        case "c": return .c
        case "cpp", "c++": return .cPlusPlus
        case "sql": return .sql
        default: return nil
        }
    }
}

// MARK: - Unordered List

struct UnorderedListView: View {
    let list: UnorderedList
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: CGFloat(theme.spacingUnit) * 0.5) {
            ForEach(Array(list.children.enumerated()), id: \.offset) { _, child in
                if let item = child as? ListItem {
                    ListItemView(item: item, bullet: "\u{2022}")
                }
            }
        }
    }
}

// MARK: - Ordered List

struct OrderedListView: View {
    let list: OrderedList
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: CGFloat(theme.spacingUnit) * 0.5) {
            ForEach(Array(list.children.enumerated()), id: \.offset) { index, child in
                if let item = child as? ListItem {
                    ListItemView(item: item, bullet: "\(index + 1).")
                }
            }
        }
    }
}

// MARK: - List Item

struct ListItemView: View {
    let item: ListItem
    let bullet: String
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: CGFloat(theme.spacingUnit) * 0.5) {
            // Check for task list checkbox
            if let checkbox = item.checkbox {
                Image(systemName: checkbox == .checked ? "checkmark.square.fill" : "square")
                    .foregroundColor(Color(hex: theme.colors.accent))
            } else {
                Text(bullet)
            }
            VStack(alignment: .leading, spacing: CGFloat(theme.spacingUnit) * 0.25) {
                ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                    if let paragraph = child as? Paragraph {
                        InlineContentView(children: Array(paragraph.children))
                    } else if let nestedList = child as? UnorderedList {
                        UnorderedListView(list: nestedList)
                            .padding(.leading, CGFloat(theme.spacingUnit))
                    } else if let nestedList = child as? OrderedList {
                        OrderedListView(list: nestedList)
                            .padding(.leading, CGFloat(theme.spacingUnit))
                    }
                }
            }
        }
        .font(.system(size: CGFloat(theme.bodySize)))
    }
}

// MARK: - Table

struct TableBlockView: View {
    let table: Markdown.Table
    @Environment(\.theme) private var theme

    var body: some View {
        let columns = Array(table.head.cells)
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, cell in
                    Text(cell.plainText)
                        .font(.system(size: CGFloat(theme.bodySize) * 0.85, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(CGFloat(theme.spacingUnit) * 0.5)
                        .background(Color(hex: theme.colors.subtle))
                }
            }
            .overlay(
                Rectangle()
                    .stroke(Color(hex: theme.colors.border), lineWidth: 1)
            )

            // Body rows
            ForEach(Array(table.body.rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.cells.enumerated()), id: \.offset) { _, cell in
                        Text(cell.plainText)
                            .font(.system(size: CGFloat(theme.bodySize) * 0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(CGFloat(theme.spacingUnit) * 0.5)
                    }
                }
                .overlay(
                    Rectangle()
                        .stroke(Color(hex: theme.colors.border), lineWidth: 0.5)
                )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(hex: theme.colors.border), lineWidth: 1)
        )
    }
}

// MARK: - Block Quote

struct BlockQuoteView: View {
    let blockQuote: BlockQuote
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: CGFloat(theme.spacingUnit)) {
            Rectangle()
                .fill(Color(hex: theme.colors.accent))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: CGFloat(theme.spacingUnit) * 0.5) {
                ForEach(Array(blockQuote.children.enumerated()), id: \.offset) { _, child in
                    MarkupNodeView(node: child)
                }
            }
            .foregroundColor(Color(hex: theme.colors.muted))
        }
    }
}

// MARK: - Inline Content

/// Renders inline markup children (text, emphasis, strong, code, links, images).
struct InlineContentView: View {
    let children: [Markup]
    @Environment(\.theme) private var theme

    var body: some View {
        children.reduce(TextBlock("")) { result, child in
            result + renderInline(child)
        }
    }

    private func renderInline(_ node: Markup) -> TextBlock {
        if let text = node as? MarkdownText {
            return TextBlock(text.string)
        } else if let strong = node as? Strong {
            let inner = strong.children.reduce(TextBlock("")) { r, c in r + renderInline(c) }
            return inner.bold()
        } else if let emphasis = node as? Emphasis {
            let inner = emphasis.children.reduce(TextBlock("")) { r, c in r + renderInline(c) }
            return inner.italic()
        } else if let code = node as? InlineCode {
            return TextBlock(code.code)
                .font(.system(size: CGFloat(theme.bodySize) * 0.85, design: .monospaced))
                .foregroundColor(Color(hex: theme.colors.accent))
        } else if let link = node as? Markdown.Link {
            let inner = link.children.reduce(TextBlock("")) { r, c in r + renderInline(c) }
            return inner.foregroundColor(Color(hex: theme.colors.link))
        } else if let strikethrough = node as? Strikethrough {
            let inner = strikethrough.children.reduce(TextBlock("")) { r, c in r + renderInline(c) }
            return inner.strikethrough()
        } else if let softBreak = node as? SoftBreak {
            return TextBlock(" ")
        } else if let lineBreak = node as? LineBreak {
            return TextBlock("\n")
        } else if let image = node as? Markdown.Image {
            // Images in inline context — show alt text as placeholder
            return TextBlock("[\(image.plainText)]")
                .foregroundColor(Color(hex: theme.colors.muted))
        } else {
            return TextBlock(node.format())
        }
    }
}
