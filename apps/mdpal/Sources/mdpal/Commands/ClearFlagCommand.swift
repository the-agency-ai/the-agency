// What Problem: `mdpal clear-flag <slug> <bundle>` removes the flag on
// a section. Per spec: returns {slug, flagged: false}.
//
// How & Why: Resolve bundle, fetch document, call clearFlag (engine
// throws sectionNotFlagged if the section has no flag), serialize,
// create revision.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.3)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct ClearFlagCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "clear-flag",
        abstract: "Clear the flag on a section."
    )

    @Argument(help: "Section slug whose flag should be cleared.")
    var slug: String

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

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

            try document.clearFlag(slug)

            let serialized = try document.serialize()
            _ = try resolvedBundle.createRevision(
                content: serialized,
                expectedBase: baseRevision
            )

            switch output.format {
            case .json:
                try JSONOutput.print(ClearFlagPayload(slug: slug, flagged: false))
            case .text:
                print("slug:    \(slug)")
                print("flagged: false")
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}
