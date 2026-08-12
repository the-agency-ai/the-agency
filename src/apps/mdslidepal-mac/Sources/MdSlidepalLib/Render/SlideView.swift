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
// Slides whose content is just a title (optionally with a subtitle) branch to
// a centered hero layout instead of the top-aligned body layout. All type is
// resolved through FontResolver rather than .system(size:), so themes can name
// real font stacks. HTMLBlock nodes are interpreted for the small subset we
// support (<br>, <hr>) and otherwise stripped to text — never shown raw.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.5
// Updated: 2026-04-15 Phase 5.1/5.2 — hero layout, HTMLBlockView, FontResolver
//   typography.
// Updated: 2026-08-07 PR-prep QG — <br> detection moved to the shared HTMLText
//   helper (was case-sensitive and duplicated), blockquotes now thread sourceURL
//   so nested images resolve, and unparseable slide `background:` metadata falls
//   back to the theme instead of painting the slide magenta.

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
        Group {
            if slide.isHero {
                heroBody
            } else {
                contentBody
            }
        }
        .padding(theme.slidePadding.edgeInsets)
        .frame(
            width: CGFloat(theme.logicalDimensions.width),
            height: CGFloat(theme.logicalDimensions.height)
        )
        .background(slideBackground)
        .foregroundColor(Color(hex: theme.colors.foreground))
    }

    private var heroBody: some View {
        VStack(alignment: .center, spacing: CGFloat(theme.spacingUnit) * 1.25) {
            Spacer(minLength: 0)
            ForEach(Array(slide.markupChildren.enumerated()), id: \.offset) { _, child in
                if let heading = child as? Heading {
                    HeadingView(heading: heading, isHero: true)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Body slides fill the slide from the top-left corner down.
    ///
    /// Not centred: contract §11's overflow policy says content past the logical
    /// viewport scrolls and is never cropped. Vertical centring puts half the
    /// excess above the top edge as well as below it, so an over-long slide loses
    /// its opening lines — and the first line no longer sits where it does on
    /// every other slide, which is what makes a deck read as one deck.
    public static let bodyAlignment: Alignment = .topLeading

    private var contentBody: some View {
        VStack(alignment: .leading, spacing: CGFloat(theme.spacingUnit) * 1.25) {
            ForEach(Array(slide.markupChildren.enumerated()), id: \.offset) { idx, child in
                MarkupNodeView(node: child, sourceURL: sourceURL)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, spacingAfter(child: child, isLast: idx == slide.markupChildren.count - 1))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Self.bodyAlignment)
    }

    /// Vertical rhythm: heading children get breathing room below them.
    /// The last child gets no trailing padding — the slide's own padding
    /// supplies the bottom margin.
    private func spacingAfter(child: Markup, isLast: Bool) -> CGFloat {
        if isLast { return 0 }
        let unit = CGFloat(theme.spacingUnit)
        if let heading = child as? Heading {
            return heading.level <= 2 ? unit * 0.75 : unit * 0.5
        }
        return 0
    }

    /// Per-slide `background:` metadata comes from an untrusted .md file, so an
    /// unparseable value falls back to the theme background rather than painting
    /// the slide the magenta debug color.
    ///
    /// Static and public because the choice between the validating parser and
    /// `Color(hex:)` is the whole behavior: as a private computed property on a
    /// SwiftUI view nothing could reach it, and swapping the call back to
    /// `Color(hex:)` — repainting every typo'd background magenta — broke no test.
    public static func background(for metadata: SlideMetadata?, theme: Theme) -> Color {
        if let bg = metadata?.background,
           let color = Color(validatingHex: bg) {
            return color
        }
        return Color(hex: theme.colors.background)
    }

    private var slideBackground: Color {
        Self.background(for: slide.metadata, theme: theme)
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
                // Interpret common HTML tags instead of showing raw
                HTMLBlockView(html: htmlBlock.rawHTML)
            } else if let blockQuote = node as? BlockQuote {
                BlockQuoteView(blockQuote: blockQuote, sourceURL: sourceURL)
            } else {
                // Fallback: render the formatted markdown as text
                Text(node.format())
                    .font(FontResolver.sans(theme, size: CGFloat(theme.bodySize)))
            }
        }
    }
}

// MARK: - Heading

struct HeadingView: View {
    let heading: Heading
    var isHero: Bool = false
    @Environment(\.theme) private var theme

    var body: some View {
        let baseSize = CGFloat(theme.headingScale.size(for: heading.level))
        // Hero slides get a 15% size boost on H1/H2 for cover-slide presence.
        let size = (isHero && heading.level <= 2) ? baseSize * 1.15 : baseSize
        let weight: Font.Weight = heading.level <= 2 ? .bold : .semibold
        let font = FontResolver.display(theme, size: size, weight: weight)
        InlineContentView(children: Array(heading.children))
            .font(font)
            .tracking(heading.level == 1 ? -0.5 : -0.3)  // Tighter letter-spacing like reveal.js
            .lineSpacing(size * 0.05)
            .padding(.bottom, heading.level <= 2 ? CGFloat(theme.spacingUnit) * 0.25 : 0)
    }
}

// MARK: - Paragraph

struct ParagraphView: View {
    let paragraph: Paragraph
    @Environment(\.theme) private var theme

    var body: some View {
        InlineContentView(children: Array(paragraph.children))
            .font(FontResolver.sans(theme, size: CGFloat(theme.bodySize)))
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
                    .font(FontResolver.mono(theme, size: CGFloat(theme.bodySize) * 0.7))
                    .padding(.horizontal, CGFloat(theme.spacingUnit) * 1.5)
                    .padding(.vertical, CGFloat(theme.spacingUnit))
            } else {
                TextBlock(codeBlock.code.trimmingCharacters(in: .newlines))
                    .font(FontResolver.mono(theme, size: CGFloat(theme.bodySize) * 0.7))
                    .foregroundColor(Color(hex: theme.codeTheme.foreground))
                    .padding(.horizontal, CGFloat(theme.spacingUnit) * 1.5)
                    .padding(.vertical, CGFloat(theme.spacingUnit))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: theme.codeTheme.background))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
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
        .font(FontResolver.sans(theme, size: CGFloat(theme.bodySize)))
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
                        .font(FontResolver.sans(theme, size: CGFloat(theme.bodySize) * 0.85, weight: .bold))
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
                            .font(FontResolver.sans(theme, size: CGFloat(theme.bodySize) * 0.85))
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
    /// Base URL of the source .md file, threaded through so images nested in a
    /// blockquote resolve relative paths the same way top-level images do.
    var sourceURL: URL?
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: CGFloat(theme.spacingUnit)) {
            Rectangle()
                .fill(Color(hex: theme.colors.accent))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: CGFloat(theme.spacingUnit) * 0.5) {
                ForEach(Array(blockQuote.children.enumerated()), id: \.offset) { _, child in
                    MarkupNodeView(node: child, sourceURL: sourceURL)
                }
            }
            .foregroundColor(Color(hex: theme.colors.muted))
        }
    }
}

// MARK: - HTML Block

/// Interprets common HTML tags instead of showing raw markup.
/// Handles <br>, <br/>, <hr>, and strips unknown tags gracefully.
struct HTMLBlockView: View {
    let html: String
    @Environment(\.theme) private var theme

    var body: some View {
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)

        if isBrOnly(trimmed) {
            // <br> or <br><br> — render as vertical space
            // Clamp here, not in the counter: a break-only block always earns
            // at least one unit of space, but "count" must still mean count.
            let brCount = max(1, HTMLText.lineBreakCount(trimmed))
            Spacer()
                .frame(height: CGFloat(theme.spacingUnit) * CGFloat(brCount))
        } else if trimmed.hasPrefix("<hr") {
            // <hr> — render as a thin divider
            Rectangle()
                .fill(Color(hex: theme.colors.border))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        } else {
            // Strip tags and render whatever text content remains
            let stripped = stripHTMLTags(trimmed)
            if !stripped.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(stripped)
                    .font(FontResolver.sans(theme, size: CGFloat(theme.bodySize)))
            }
            // If fully empty after stripping, render nothing
        }
    }

    /// Check if the HTML block is only <br> tags (with optional whitespace).
    private func isBrOnly(_ html: String) -> Bool {
        HTMLText.isLineBreakOnly(html)
    }

    /// Simple HTML tag stripper for fallback rendering.
    private func stripHTMLTags(_ html: String) -> String {
        HTMLText.stripTags(html)
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
                .font(FontResolver.mono(theme, size: CGFloat(theme.bodySize) * 0.85))
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
        } else if let inlineHTML = node as? InlineHTML {
            // Handle inline HTML — <br> becomes newline, others stripped
            if HTMLText.isLineBreak(inlineHTML.rawHTML) {
                return TextBlock("\n")
            }
            // Strip other inline HTML tags
            return TextBlock("")
        } else {
            return TextBlock(node.format())
        }
    }
}
