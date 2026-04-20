// What Problem: Document-level metadata from YAML front-matter at the start
// of a markdown file (contract §1). Controls deck title, author, theme
// selection, and other document properties.
//
// How & Why: Struct with optional fields matching the reserved front-matter
// keys. Parsed by FrontMatterExtractor using Yams. Custom fields go into
// `meta` dictionary for theme engine pass-through (MVP themes don't use
// custom fields but the schema supports them).
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.1

import Foundation

/// Document-level metadata from YAML front-matter.
public struct FrontMatter: Equatable {
    public var title: String?
    public var author: String?
    public var theme: String?
    public var date: String?
    public var description: String?
    public var footer: String?
    /// Custom fields exposed to the theme engine.
    public var meta: [String: String]

    public init(
        title: String? = nil,
        author: String? = nil,
        theme: String? = nil,
        date: String? = nil,
        description: String? = nil,
        footer: String? = nil,
        meta: [String: String] = [:]
    ) {
        self.title = title
        self.author = author
        self.theme = theme
        self.date = date
        self.description = description
        self.footer = footer
        self.meta = meta
    }
}
