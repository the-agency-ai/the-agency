// What Problem: `mdpal flags <bundle>` lists all flagged sections.
// Per spec: returns {flags: [...], count}.
//
// How & Why: Resolve bundle, fetch document, listFlags, map to wire
// shape. Read-only — no revision created.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.3)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct FlagsCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "flags",
        abstract: "List all flagged sections."
    )

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @OptionGroup var output: GlobalOutputOptions

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            let document = try resolvedBundle.currentDocument()
            let flags = document.listFlags()

            switch output.format {
            case .json:
                let payload = FlagsListPayload(
                    flags: flags.map(FlagListEntryPayload.init(from:)),
                    count: flags.count
                )
                try JSONOutput.print(payload)
            case .text:
                if flags.isEmpty {
                    print("(no flags)")
                } else {
                    for f in flags {
                        let note = f.note.map { " — \($0)" } ?? ""
                        print("\(f.sectionSlug) [\(f.author)]\(note)")
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
