// What Problem: `mdpal diff <rev1> <rev2> <bundle>` is the
// section-level diff between two revisions of a bundle. mdpal-app's
// "compare versions" view drives this; agents call it before deciding
// whether to merge or branch.
//
// How & Why: Resolve bundle, call the engine's `bundle.diff(baseRevision:,
// targetRevision:)`, filter out `.unchanged` per the dispatched spec
// ("only changed sections are included"), serialize the remaining
// SectionDiffs to the wire shape. The argument order — rev1, rev2 —
// reads as "from rev1 to rev2" so the JSON `from`/`to` map directly.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct DiffCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "diff",
        abstract: "Compare two revisions of a bundle at the section level.",
        discussion: """
            Reports added, removed, and modified sections from <rev1> to
            <rev2>. Unchanged sections are omitted (use --include-unchanged
            to emit them).

            Both revision arguments are versionIds (e.g., V0001.0003.20260406T0100Z)
            obtained from `mdpal history`.
            """
    )

    @Argument(help: "Base revision id (the 'from' side of the diff).")
    var rev1: String

    @Argument(help: "Target revision id (the 'to' side of the diff).")
    var rev2: String

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @ArgumentParser.Flag(name: .long, help: "Include unchanged sections in output. Default: omit them.")
    var includeUnchanged: Bool = false

    @OptionGroup var output: GlobalOutputOptions

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            let allDiffs = try resolvedBundle.diff(
                baseRevision: rev1,
                targetRevision: rev2
            )
            let filtered = includeUnchanged
                ? allDiffs
                : allDiffs.filter { $0.type != .unchanged }

            switch output.format {
            case .json:
                let changes = filtered.map { diff in
                    DiffChangePayload(
                        slug: diff.slug,
                        type: diff.type.rawValue,
                        summary: diff.summary
                    )
                }
                let payload = DiffPayload(
                    from: rev1,
                    to: rev2,
                    changes: changes,
                    count: changes.count
                )
                try JSONOutput.print(payload)
            case .text:
                if filtered.isEmpty {
                    print("(no changes)")
                } else {
                    for diff in filtered {
                        print("\(diff.type.rawValue): \(diff.slug) — \(diff.summary)")
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

/// Wire shape for `mdpal diff` per the dispatched spec.
struct DiffPayload: Encodable {
    let from: String
    let to: String
    let changes: [DiffChangePayload]
    let count: Int
}

/// One row in the `changes` array. `type` is one of the SectionDiffType
/// raw values: "added", "removed", "modified", "unchanged".
struct DiffChangePayload: Encodable {
    let slug: String
    let type: String
    let summary: String
}
