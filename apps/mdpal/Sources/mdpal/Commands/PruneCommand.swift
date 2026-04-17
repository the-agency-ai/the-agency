// What Problem: `mdpal prune <bundle> [--keep <n>]` deletes old
// revisions while merging forward any resolved comments from the pruned
// revisions into the latest. Without prune, bundle directories grow
// unbounded; with it, history stays manageable while comment provenance
// is preserved.
//
// How & Why: Resolve bundle, derive `keep` from --keep or the bundle
// config's prune.keep, call `bundle.prune(keep:)`, serialize the
// PruneResult into the wire shape. The pruned-revisions list pairs
// versionId with the basename of the deleted file so the caller can
// reconstruct what was removed.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct PruneCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "prune",
        abstract: "Remove old revisions while preserving resolved comments.",
        discussion: """
            Keeps the most recent N revisions and deletes the rest. Resolved
            comments from pruned revisions are merged forward into the latest
            revision so no comment history is lost.

            If --keep is omitted, the bundle config's `prune.keep` value is
            used (default 20).
            """
    )

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @Option(name: .long, help: "Number of most-recent revisions to keep. Defaults to the bundle config's prune.keep.")
    var keep: Int?

    @OptionGroup var output: GlobalOutputOptions

    func validate() throws {
        if let keep, keep <= 0 {
            throw ValidationError("--keep must be > 0; got \(keep).")
        }
    }

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            let effectiveKeep = keep ?? resolvedBundle.config.prune.keep

            // Collect the pre-prune revision list so we can map pruned
            // versionIds back to filenames in the wire payload. The engine
            // returns just the versionIds; the wire spec wants {versionId,
            // filePath} pairs.
            let preRevisions = try resolvedBundle.listRevisions()
            // Use uniquingKeysWith for defense-in-depth: the engine guarantees
            // uniqueness of versionId across files, but a corrupt bundle with
            // two files parsing to the same versionId would otherwise hard-
            // crash here. Keep the first sighting; lossy but non-fatal.
            let filenameByVersionId = Dictionary(
                preRevisions.map {
                    ($0.versionId, ($0.filePath as NSString).lastPathComponent)
                },
                uniquingKeysWith: { first, _ in first }
            )

            let result = try resolvedBundle.prune(keep: effectiveKeep)

            switch output.format {
            case .json:
                let prunedEntries = result.prunedRevisions.map { id in
                    PrunedRevisionPayload(
                        versionId: id,
                        filePath: filenameByVersionId[id] ?? "\(id).md"
                    )
                }
                let payload = PrunePayload(
                    pruned: prunedEntries,
                    kept: result.remainingRevisions,
                    prunedCount: result.prunedRevisions.count,
                    commentsPreserved: result.mergedComments
                )
                try JSONOutput.print(payload)
            case .text:
                if result.prunedRevisions.isEmpty {
                    print("(nothing pruned; \(result.remainingRevisions) kept)")
                } else {
                    print("pruned \(result.prunedRevisions.count) revision(s):")
                    for id in result.prunedRevisions {
                        print("  \(id)")
                    }
                    print("kept:              \(result.remainingRevisions)")
                    print("commentsPreserved: \(result.mergedComments)")
                }
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}

/// Wire shape for `mdpal prune` per the dispatched spec.
struct PrunePayload: Encodable {
    let pruned: [PrunedRevisionPayload]
    let kept: Int
    let prunedCount: Int
    let commentsPreserved: Int
}

struct PrunedRevisionPayload: Encodable {
    let versionId: String
    let filePath: String
}
