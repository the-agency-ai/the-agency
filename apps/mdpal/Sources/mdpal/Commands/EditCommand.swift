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
        // Reject interactive-TTY stdin with no redirect — would hang forever.
        // Only check when --stdin is requested; otherwise irrelevant.
        if stdin && isatty(fileno(stdin_pointer())) != 0 {
            let envelope = ErrorEnvelope(
                error: "stdinIsTTY",
                message: "stdin is a terminal; pipe content or use --content"
            )
            envelope.emit(format: output.format)
            throw MdpalExitCode.generalError.argumentParserCode
        }

        // Resolve bundle BEFORE the do/catch so we can use it inside the
        // versionConflict-specific path below.
        let resolvedBundle: DocumentBundle
        do {
            resolvedBundle = try BundleResolver.resolve(self.bundle)
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }

        do {
            let document = try resolvedBundle.currentDocument()

            let newContent: String
            if let content {
                newContent = content
            } else {
                // --stdin: read all of stdin to EOF.
                let data = FileHandle.standardInput.readDataToEndOfFile()
                guard let decoded = String(data: data, encoding: .utf8) else {
                    let envelope = ErrorEnvelope(
                        error: "invalidEncoding",
                        message: "stdin contained non-UTF-8 bytes"
                    )
                    envelope.emit(format: output.format)
                    throw MdpalExitCode.generalError.argumentParserCode
                }
                newContent = decoded
            }

            let updated = try document.editSection(
                slug,
                newContent: newContent,
                versionHash: version
            )

            // Persist as a new revision (append-only invariant).
            //
            // Note: `editSection` mutates the in-memory Document before this
            // line. If `serialize()` or `createRevision` fails below, the
            // bundle on disk is unchanged (good — bundle integrity preserved)
            // but the in-memory Document is dirty. Harmless for a single CLI
            // invocation (process exits); flagged for future long-lived
            // contexts.
            let serialized = try document.serialize()
            let revision = try resolvedBundle.createRevision(content: serialized)

            // Report on-disk size, not in-memory string byte count.
            // attributesOfItem returns the actual file length the consumer
            // can verify via stat/du.
            let onDiskBytes = (try? FileManager.default.attributesOfItem(atPath: revision.filePath)[.size] as? Int)
                ?? serialized.utf8.count

            switch output.format {
            case .json:
                let payload = EditPayload(
                    slug: updated.slug,
                    versionHash: updated.versionHash,
                    versionId: revision.versionId,
                    bytesWritten: onDiskBytes
                )
                try JSONOutput.print(payload)
            case .text:
                print("slug:         \(updated.slug)")
                print("versionHash:  \(updated.versionHash)")
                print("versionId:    \(revision.versionId)")
                print("bytesWritten: \(onDiskBytes)")
            }
        } catch let error as EngineError {
            // Enrich versionConflict envelope with the bundle's current
            // versionId per the dispatched spec — the engine error doesn't
            // carry it (Document doesn't know bundle metadata), so we add
            // it here at the boundary where both contexts are available.
            if case .versionConflict(let slug, let expected, let actual, let currentContent) = error {
                let versionId = (try? resolvedBundle.latestRevision()?.versionId) ?? ""
                let details: [String: AnyCodable] = [
                    "slug": AnyCodable(slug),
                    "expectedHash": AnyCodable(expected),
                    "currentHash": AnyCodable(actual),
                    "currentContent": AnyCodable(currentContent),
                    "versionId": AnyCodable(versionId),
                ]
                let envelope = ErrorEnvelope(
                    error: "versionConflict",
                    message: "Section '\(slug)' was modified — expected hash \(expected), got \(actual)",
                    details: details
                )
                envelope.emit(format: output.format)
                throw MdpalExitCode.versionConflict.argumentParserCode
            }
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}

// Helper to get FILE* for isatty — avoids `Darwin.stdin` collision
// with Swift's `stdin` keyword on macOS.
private func stdin_pointer() -> UnsafeMutablePointer<FILE> {
    fdopen(0, "r")
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
