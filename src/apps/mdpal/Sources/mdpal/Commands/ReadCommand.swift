// What Problem: `mdpal read <slug> <bundle>` returns the full content
// of a single section, including its versionHash (for subsequent
// optimistic-concurrency edits) and the bundle's versionId. mdpal-app
// uses this when the user clicks into a section in the outline.
//
// How & Why: Open bundle, fetch currentDocument(), call readSection.
// Emit JSON with slug, heading, level, content, versionHash, versionId.
// On not-found, surface sectionNotFound via ErrorEnvelope so the app
// can offer the availableSlugs list.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
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

    @OptionGroup var output: GlobalOutputOptions

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            let document = try resolvedBundle.currentDocument()
            let section = try document.readSection(slug)
            let versionId = try resolvedBundle.latestRevision()?.versionId ?? ""

            switch output.format {
            case .json:
                let payload = SectionPayload(from: section, versionId: versionId)
                try JSONOutput.print(payload)
            case .text:
                print("# \(section.heading)")
                print("slug:        \(section.slug)")
                print("level:       \(section.level)")
                print("versionHash: \(section.versionHash)")
                print("versionId:   \(versionId)")
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
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}

/// Wire shape for `mdpal read` JSON output. Per the dispatched spec:
/// includes `versionHash` (for optimistic-concurrency edits) and
/// `versionId` (identifies the revision the section was read from).
///
/// Note: the spec does not include the children array on `read` (that
/// info is on `sections`). We omit it here too to match the contract.
struct SectionPayload: Encodable {
    let slug: String
    let heading: String
    let level: Int
    let content: String
    let versionHash: String
    let versionId: String

    init(from section: Section, versionId: String) {
        self.slug = section.slug
        self.heading = section.heading
        self.level = section.level
        self.content = section.content
        self.versionHash = section.versionHash
        self.versionId = versionId
    }
}
