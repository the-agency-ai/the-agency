// What Problem: `mdpal read <slug> <bundle>` returns the full content
// of a single section, including its version hash (for subsequent
// optimistic-concurrency edits) and direct children. mdpal-app uses
// this when the user clicks into a section in the outline.
//
// How & Why: Open bundle, fetch currentDocument(), call readSection.
// Emit JSON with slug, heading, level, content, version_hash, children.
// On not-found, surface section_not_found via ErrorEnvelope so the app
// can offer the suggestions list.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct ReadCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "read",
        abstract: "Read a single section from the latest revision of a bundle.",
        discussion: """
            Slugs are path-style: top-level sections are bare ("introduction"),
            nested sections use forward-slash separators ("authentication/oauth").
            Use `mdpal sections` to discover available slugs.
            """
    )

    @Argument(help: "Section slug (e.g., 'introduction' or 'authentication/oauth').")
    var slug: String

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @Option(name: .long, help: "Output format: json (default) or text.")
    var format: OutputFormat = .json

    func run() throws {
        do {
            let bundle = try BundleResolver.resolve(self.bundle)
            let document = try bundle.currentDocument()
            let section = try document.readSection(slug)

            switch format {
            case .json:
                let payload = SectionPayload(from: section)
                try JSONOutput.print(payload)
            case .text:
                print("# \(section.heading)")
                print("slug:         \(section.slug)")
                print("level:        \(section.level)")
                print("version_hash: \(section.versionHash)")
                if !section.children.isEmpty {
                    print("children:")
                    for child in section.children {
                        print("  - \(child.slug)")
                    }
                }
                print("")
                print(section.content)
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: format)
            throw exit.argumentParserCode
        }
    }
}

/// Wire shape for `mdpal read` JSON output. Mirrors `Section` but omits
/// `lineRange` (always nil in Phase 1; will be added when wired through
/// the parser in Phase 2.5).
struct SectionPayload: Encodable {
    let slug: String
    let heading: String
    let level: Int
    let content: String
    let versionHash: String
    let children: [SectionInfo]

    init(from section: Section) {
        self.slug = section.slug
        self.heading = section.heading
        self.level = section.level
        self.content = section.content
        self.versionHash = section.versionHash
        self.children = section.children
    }
}
