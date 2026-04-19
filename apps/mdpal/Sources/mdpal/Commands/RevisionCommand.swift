// What Problem: `mdpal revision create <bundle> [--content | --stdin]
// [--base-revision <id>]` writes a new revision to a bundle. mdpal-app
// uses this for "Save As New Revision" (rich-merge UX) and agents use
// it for batch document updates. The optional --base-revision implements
// optimistic concurrency at the bundle level: if the bundle's current
// latest doesn't match the supplied id, the write is rejected with a
// bundleConflict so the caller can re-fetch and merge.
//
// How & Why: A `revision` parent command groups future revision
// subcommands (show, list, etc.). For now only `create` exists. Content
// arrives via --content or --stdin (mutually exclusive, validated).
// When --base-revision is supplied, we compare against
// `bundle.latestRevision()?.versionId` BEFORE creating the new file.
// On match, call `bundle.createRevision(content:)`.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct RevisionCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "revision",
        abstract: "Manage bundle revisions.",
        discussion: """
            Subcommands operate on the revision history of a bundle.
            For now, only `create` is implemented; future iterations may
            add `show`, `list`, and other revision-level operations.
            """,
        subcommands: [RevisionCreateCommand.self]
    )
}

struct RevisionCreateCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new revision in a bundle.",
        discussion: """
            Writes the supplied content as a new revision. The revision
            number is auto-incremented from the current latest. If
            --base-revision is supplied, the bundle's current latest must
            match it exactly — otherwise the command exits with code 4
            (bundleConflict) so the caller can re-fetch and merge.

            Content is supplied via --content or --stdin (mutually
            exclusive). For long content, prefer --stdin to avoid
            ARG_MAX limits.
            """
    )

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @Option(name: .long, help: "Full document content for the new revision (mutually exclusive with --stdin).")
    var content: String?

    @ArgumentParser.Flag(name: .long, help: "Read full document content from stdin (mutually exclusive with --content).")
    var stdin: Bool = false

    @Option(name: .long, help: "Required base revision id. Reject the write if it doesn't match the bundle's current latest.")
    var baseRevision: String?

    @OptionGroup var output: GlobalOutputOptions

    func validate() throws {
        if content != nil && stdin {
            throw ValidationError("Specify either --content or --stdin, not both.")
        }
        if content == nil && !stdin {
            throw ValidationError("One of --content or --stdin is required.")
        }
    }

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)

            // Resolve content from --content or --stdin.
            let resolvedContent: String
            if let content {
                resolvedContent = content
            } else {
                do {
                    resolvedContent = try StdinReader.readAll()
                } catch let f as StdinReader.ReadFailure {
                    f.envelope.emit(format: output.format)
                    throw f.exitCode.argumentParserCode
                }
            }

            // Optimistic concurrency is now enforced INSIDE the engine
            // (createRevision's expectedBase parameter), closing the
            // TOCTOU window between the CLI's check and the engine's
            // own latest-discovery. Pre-iter-2.4-QG the check happened
            // here; the engine had no enforcement and a concurrent
            // writer could land between our check and the file write.
            let newRevision = try resolvedBundle.createRevision(
                content: resolvedContent,
                expectedBase: baseRevision
            )

            switch output.format {
            case .json:
                let payload = RevisionCreatePayload(
                    versionId: newRevision.versionId,
                    version: newRevision.version,
                    revision: newRevision.revision,
                    timestamp: newRevision.timestamp,
                    filePath: (newRevision.filePath as NSString).lastPathComponent
                )
                try JSONOutput.print(payload)
            case .text:
                print("versionId: \(newRevision.versionId)")
                print("version:   \(newRevision.version)")
                print("revision:  \(newRevision.revision)")
                print("timestamp: \(newRevision.timestamp)")
                print("filePath:  \((newRevision.filePath as NSString).lastPathComponent)")
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}

/// Wire shape for `mdpal revision create` success payload per the
/// dispatched spec. `filePath` is the basename of the new revision
/// file, not the absolute path — relative paths are portable.
struct RevisionCreatePayload: Encodable {
    let versionId: String
    let version: Int
    let revision: Int
    let timestamp: Date
    let filePath: String
}
