// What Problem: `mdpal resolve <commentId> <bundle> --response --by`
// resolves an unresolved comment by attaching a Resolution. Per spec,
// the response payload includes the commentId, resolved=true, and the
// full resolution object (response, by, timestamp).
//
// How & Why: Resolve bundle, fetch document, call resolveComment
// (engine throws commentNotFound or commentAlreadyResolved on failure),
// serialize, write a new revision. Return ResolvePayload as JSON.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.3)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct ResolveCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "resolve",
        abstract: "Resolve an unresolved comment by id."
    )

    @Argument(help: "Comment id (e.g., 'c0001').")
    var commentId: String

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @Option(name: .long, help: "Response text (mutually exclusive with --response-stdin).")
    var response: String?

    @ArgumentParser.Flag(name: .long, help: "Read response text from stdin (avoids ARG_MAX limits).")
    var responseStdin: Bool = false

    @Option(name: .long, help: "Who is resolving the comment.")
    var by: String

    @OptionGroup var output: GlobalOutputOptions

    func validate() throws {
        if response != nil && responseStdin {
            throw ValidationError("Specify either --response or --response-stdin, not both.")
        }
        if response == nil && !responseStdin {
            throw ValidationError("One of --response or --response-stdin is required.")
        }
    }

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            let document = try resolvedBundle.currentDocument()

            let resolvedResponse: String
            if let response {
                resolvedResponse = response
            } else {
                let data = FileHandle.standardInput.readDataToEndOfFile()
                guard let decoded = String(data: data, encoding: .utf8) else {
                    let envelope = ErrorEnvelope(
                        error: "invalidEncoding",
                        message: "stdin contained non-UTF-8 bytes"
                    )
                    envelope.emit(format: output.format)
                    throw MdpalExitCode.generalError.argumentParserCode
                }
                resolvedResponse = decoded
            }

            let comment = try document.resolveComment(
                id: commentId,
                response: resolvedResponse,
                resolvedBy: by
            )

            let serialized = try document.serialize()
            _ = try resolvedBundle.createRevision(content: serialized)

            switch output.format {
            case .json:
                let payload = ResolvePayload(
                    commentId: comment.id,
                    resolved: true,
                    resolution: comment.resolution.map(ResolutionPayload.init(from:))
                )
                try JSONOutput.print(payload)
            case .text:
                print("commentId: \(comment.id)")
                print("resolved:  true")
                if let r = comment.resolution {
                    print("response:  \(r.response)")
                    print("by:        \(r.resolvedBy)")
                }
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}

/// Wire shape for `mdpal resolve` per spec. resolution is always
/// non-null for a successful resolve, but emitted explicitly via custom
/// encode for shape stability with other resolution-bearing payloads.
struct ResolvePayload: Encodable {
    let commentId: String
    let resolved: Bool
    let resolution: ResolutionPayload?

    private enum CodingKeys: String, CodingKey {
        case commentId, resolved, resolution
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(commentId, forKey: .commentId)
        try c.encode(resolved, forKey: .resolved)
        if let resolution { try c.encode(resolution, forKey: .resolution) }
        else { try c.encodeNil(forKey: .resolution) }
    }
}
