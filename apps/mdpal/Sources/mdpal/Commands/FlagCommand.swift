// What Problem: `mdpal flag <slug> <bundle> --author [--note]` flags a
// section for discussion. Per spec: returns {slug, flagged: true, author,
// note, timestamp}. Replaces existing flag on the same section (engine
// semantics).
//
// How & Why: Resolve bundle, fetch document, call flagSection, serialize,
// create revision. Return FlagPayload.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.3)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct FlagCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "flag",
        abstract: "Flag a section for discussion."
    )

    @Argument(help: "Section slug to flag.")
    var slug: String

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @Option(name: .long, help: "Who is flagging the section.")
    var author: String

    @Option(name: .long, help: "Optional note explaining the flag.")
    var note: String?

    @Option(
        name: .long,
        help: "Bundle revision id you last saw. If supplied, the create fails with bundleConflict if another writer landed first."
    )
    var baseRevision: String?

    @OptionGroup var output: GlobalOutputOptions

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            let document = try resolvedBundle.currentDocument()

            let flag = try document.flagSection(slug, author: author, note: note)

            let serialized = try document.serialize()
            _ = try resolvedBundle.createRevision(
                content: serialized,
                expectedBase: baseRevision
            )

            switch output.format {
            case .json:
                let payload = FlagPayload(from: flag)
                try JSONOutput.print(payload)
            case .text:
                print("slug:    \(flag.sectionSlug)")
                print("flagged: true")
                print("author:  \(flag.author)")
                if let note = flag.note { print("note:    \(note)") }
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}
