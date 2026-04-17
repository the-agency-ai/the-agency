// What Problem: The first real command — `mdpal sections <bundle>` —
// returns the list of sections in the latest revision of a bundle as
// JSON. mdpal-app uses this to populate its document outline.
//
// How & Why: Open the bundle, fetch currentDocument(), call
// listSections() on it, emit the array as JSON. Engine errors map
// through ErrorEnvelope → stderr + exit code.
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
            Returns a flat list of section summaries (slug, heading, level,
            version_hash, child_count). Use `mdpal read <slug>` to fetch
            the full content of a single section.
            """
    )

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @Option(name: .long, help: "Output format: json (default) or text.")
    var format: OutputFormat = .json

    func run() throws {
        do {
            let bundle = try BundleResolver.resolve(self.bundle)
            let document = try bundle.currentDocument()
            let sections = document.listSections()

            switch format {
            case .json:
                let payload = SectionsPayload(sections: sections)
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
            envelope.emit(format: format)
            throw exit.argumentParserCode
        }
    }
}

/// Wire shape for `mdpal sections` JSON output. The `sections` field is
/// a top-level array — wrapping it in a payload object lets us add
/// future fields (e.g., bundle_version_id, document_info) without
/// breaking the wire format.
struct SectionsPayload: Encodable {
    let sections: [SectionInfo]
}
