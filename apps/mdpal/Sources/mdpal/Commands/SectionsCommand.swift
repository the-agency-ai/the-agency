// What Problem: The first real command — `mdpal sections <bundle>` —
// returns a JSON tree of sections in the latest revision. mdpal-app
// uses this to populate its document outline.
//
// How & Why: Open the bundle, fetch currentDocument(), call
// listSections() to get the flat slug-keyed list, then build a recursive
// tree by parsing the path-style slugs ("parent/child"). Top-level
// payload includes total `count` and `versionId` of the revision read,
// per the dispatched spec to mdpal-app.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct SectionsCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "sections",
        abstract: "List all sections in the latest revision of a bundle.",
        discussion: """
            Returns a recursive tree of section summaries (slug, heading, level,
            versionHash, children). Top-level payload includes `count` and
            `versionId` of the revision being read.
            """
    )

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @OptionGroup var output: GlobalOutputOptions

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            let document = try resolvedBundle.currentDocument()
            let sections = document.listSections()
            let versionId = try resolvedBundle.latestRevision()?.versionId ?? ""

            switch output.format {
            case .json:
                let tree = SectionTreeBuilder.build(from: sections)
                let payload = SectionsPayload(
                    sections: tree,
                    count: sections.count,
                    versionId: versionId
                )
                try JSONOutput.print(payload)
            case .text:
                if sections.isEmpty {
                    print("(no sections)")
                } else {
                    for section in sections {
                        let indent = String(repeating: "  ", count: max(0, section.level - 1))
                        print("\(indent)\(section.slug)  [\(section.heading)]")
                    }
                }
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}

/// Wire shape for `mdpal sections` JSON output.
///
/// Per the dispatched spec: `sections` is a recursive tree (each node
/// has a `children` array), `count` is the total section count across
/// the entire tree, `versionId` identifies the revision being read.
struct SectionsPayload: Encodable {
    let sections: [SectionTreeNode]
    let count: Int
    let versionId: String
}

/// Recursive section tree node — `SectionInfo` plus a `children` array
/// of the same type. The flat list returned by `listSections()` is
/// folded into this shape by `SectionTreeBuilder`.
struct SectionTreeNode: Encodable {
    let slug: String
    let heading: String
    let level: Int
    let versionHash: String
    let children: [SectionTreeNode]
}

/// Build a recursive tree from the flat list returned by `listSections()`.
///
/// The flat list uses path-style slugs: a child of "introduction" is
/// "introduction/background". We parent-detect by stripping the last
/// `/`-segment of each slug. The flat list is in document order, so
/// parents always precede their children.
enum SectionTreeBuilder {
    static func build(from flat: [SectionInfo]) -> [SectionTreeNode] {
        var childrenBySlug: [String: [SectionInfo]] = [:]
        var roots: [SectionInfo] = []

        for section in flat {
            if let lastSlash = section.slug.lastIndex(of: "/") {
                let parentSlug = String(section.slug[..<lastSlash])
                childrenBySlug[parentSlug, default: []].append(section)
            } else {
                roots.append(section)
            }
        }

        func node(for info: SectionInfo) -> SectionTreeNode {
            let kids = (childrenBySlug[info.slug] ?? []).map(node(for:))
            return SectionTreeNode(
                slug: info.slug,
                heading: info.heading,
                level: info.level,
                versionHash: info.versionHash,
                children: kids
            )
        }

        return roots.map(node(for:))
    }
}
