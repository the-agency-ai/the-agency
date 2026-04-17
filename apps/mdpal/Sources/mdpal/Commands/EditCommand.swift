// What Problem: `mdpal edit <slug> --version <hash> <bundle>` is the
// optimistic-concurrency write path. mdpal-app's editor uses this to
// commit a section change after the user observed `versionHash` from a
// prior `read`. Conflicts must surface as exit 2 with the current
// content so the app can offer a merge UI.
//
// How & Why: Resolve bundle, fetch latest revision content, parse to a
// Document, call editSection (engine throws versionConflict if the hash
// has changed underneath us), serialize the updated document, and
// create a new revision via DocumentBundle.createRevision. Success
// payload returns the new versionHash, versionId, and bytesWritten per
// the dispatched JSON spec.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.2)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct EditCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit a section's content with optimistic concurrency.",
        discussion: """
            Pass --version with the hash you observed from a prior `mdpal read`.
            If the section has been modified since (different hash), the command
            exits with code 2 and a `versionConflict` envelope on stderr that
            includes `currentContent` so callers can merge.

            Content is supplied either via --content "text" or by piping to
            stdin. Empty content is allowed.
            """
    )

    @Argument(help: "Section slug (e.g., 'introduction' or 'authentication/oauth').")
    var slug: String

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @Option(name: .long, help: "The version hash you observed from a prior read.")
    var version: String

    @Option(name: .long, help: "New section content (mutually exclusive with --stdin).")
    var content: String?

    @ArgumentParser.Flag(name: .long, help: "Read new content from stdin (mutually exclusive with --content).")
    var stdin: Bool = false

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
            let document = try resolvedBundle.currentDocument()

            let newContent: String
            if let content {
                newContent = content
            } else {
                // --stdin: read all of stdin to EOF.
                let data = FileHandle.standardInput.readDataToEndOfFile()
                newContent = String(data: data, encoding: .utf8) ?? ""
            }

            let updated = try document.editSection(
                slug,
                newContent: newContent,
                versionHash: version
            )

            // Persist as a new revision (append-only invariant).
            let serialized = try document.serialize()
            let revision = try resolvedBundle.createRevision(content: serialized)

            switch output.format {
            case .json:
                let payload = EditPayload(
                    slug: updated.slug,
                    versionHash: updated.versionHash,
                    versionId: revision.versionId,
                    bytesWritten: serialized.utf8.count
                )
                try JSONOutput.print(payload)
            case .text:
                print("slug:         \(updated.slug)")
                print("versionHash:  \(updated.versionHash)")
                print("versionId:    \(revision.versionId)")
                print("bytesWritten: \(serialized.utf8.count)")
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}

/// Wire shape for `mdpal edit` success payload. Per dispatched spec:
/// returns the new versionHash (use as the next --version), the new
/// revision's versionId, and the byte length written.
struct EditPayload: Encodable {
    let slug: String
    let versionHash: String
    let versionId: String
    let bytesWritten: Int
}
