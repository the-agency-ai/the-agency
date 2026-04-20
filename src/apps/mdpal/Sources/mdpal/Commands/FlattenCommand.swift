// What Problem: `mdpal flatten <bundle>` converts a packaged bundle's
// latest revision into pancake (.md) Markdown. mdpal-app's "Send
// flattened" reply path needs this to ship plain .md back to the original
// requester. Default output is body-only; --include-comments and
// --include-flags append the metadata as separate Markdown sections.
//
// How & Why: Resolve bundle, fetch latest revision via currentDocument,
// call Document.flatten (engine method added in iter 3.3). Output to
// stdout by default, or to <path> via --output. Empty bundle returns
// bundleConflict exit 4 (no revisions to flatten).
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
// Reference: usr/jordan/mdpal/plan-mdpal-20260406.md (Phase 3 iter 3.3)
//
// Written: 2026-04-19 during mdpal-cli session (Phase 3 iter 3.3)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct FlattenCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "flatten",
        abstract: "Flatten a .mdpal bundle's latest revision to plain Markdown.",
        discussion: """
            Reads the bundle's latest revision and emits pancake Markdown
            (no metadata block). Used by mdpal-app's "Send flattened" reply
            path.

            Default: body only.
            --include-comments: appends a `## Comments` section with each
              comment's id / type / author / text / context (and resolution
              if present).
            --include-flags: appends a `## Flags` section listing flagged
              sections.
            --output <path>: write to file instead of stdout.

            Empty bundle (no revisions) → bundleConflict exit 4.
            """
    )

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @Option(name: .long, help: "Write the flattened Markdown to this path. Defaults to stdout.")
    var output: String?

    @ArgumentParser.Flag(name: .long, help: "Append comments as a Markdown section after the body.")
    var includeComments: Bool = false

    @ArgumentParser.Flag(name: .long, help: "Append flags as a Markdown section after the body.")
    var includeFlags: Bool = false

    @OptionGroup var outputOpts: GlobalOutputOptions

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            // Latest-revision check FIRST so we surface bundleConflict
            // before doing any read work.
            guard try resolvedBundle.latestRevision() != nil else {
                throw EngineError.bundleConflict(
                    "Bundle has no revisions to flatten: \(resolvedBundle.path)"
                )
            }

            let document = try resolvedBundle.currentDocument()
            let flattened = try document.flatten(
                includeComments: includeComments,
                includeFlags: includeFlags
            )

            if let output {
                let outputPath = BundleResolver.canonicalize(output)
                do {
                    try flattened.write(toFile: outputPath, atomically: true, encoding: .utf8)
                } catch {
                    throw EngineError.fileError(
                        path: outputPath,
                        description: "Failed to write flattened output: \(error)"
                    )
                }
                // When --output is supplied, emit a small JSON payload to
                // stdout so callers can pipe-then-confirm. Keeps the
                // command machine-readable end-to-end.
                switch outputOpts.format {
                case .json:
                    let payload = FlattenPayload(
                        path: outputPath,
                        bytesWritten: flattened.utf8.count,
                        includeComments: includeComments,
                        includeFlags: includeFlags
                    )
                    try JSONOutput.print(payload)
                case .text:
                    print("path:            \(outputPath)")
                    print("bytesWritten:    \(flattened.utf8.count)")
                    print("includeComments: \(includeComments)")
                    print("includeFlags:    \(includeFlags)")
                }
            } else {
                // No --output: emit the flattened Markdown directly to
                // stdout. JSON format wraps the payload in a JSON object
                // so machine consumers can still parse it; text format
                // emits the raw Markdown.
                switch outputOpts.format {
                case .json:
                    let payload = FlattenStdoutPayload(
                        content: flattened,
                        bytesWritten: flattened.utf8.count,
                        includeComments: includeComments,
                        includeFlags: includeFlags
                    )
                    try JSONOutput.print(payload)
                case .text:
                    // Raw Markdown — single-pass to stdout, no print()
                    // because that adds a trailing newline (flatten
                    // already ends with exactly one).
                    FileHandle.standardOutput.write(Data(flattened.utf8))
                }
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: outputOpts.format)
            throw exit.argumentParserCode
        }
    }
}

/// Wire shape for `mdpal flatten --output <path>`.
struct FlattenPayload: Encodable {
    let path: String
    let bytesWritten: Int
    let includeComments: Bool
    let includeFlags: Bool
}

/// Wire shape for `mdpal flatten` to stdout (JSON format only — text
/// format emits raw Markdown).
struct FlattenStdoutPayload: Encodable {
    let content: String
    let bytesWritten: Int
    let includeComments: Bool
    let includeFlags: Bool
}
