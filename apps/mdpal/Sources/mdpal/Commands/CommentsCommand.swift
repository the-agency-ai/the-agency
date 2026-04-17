// What Problem: `mdpal comments <bundle> [--section] [--type]
// [--unresolved] [--resolved]` lists comments with optional filters.
// mdpal-app uses this to render comment threads. Per spec the response
// includes the filter values back so callers can verify what they
// actually got.
//
// How & Why: Resolve bundle, build a CommentFilter from CLI flags,
// call listComments, map to CommentPayload[], emit with count + filters
// echo. Read-only — no revision created.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.3)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct CommentsCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "comments",
        abstract: "List comments with optional filters."
    )

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @Option(name: .long, help: "Filter to comments anchored to this section slug.")
    var section: String?

    @Option(name: .long, help: "Filter to comments of this type.")
    var type: String?

    @ArgumentParser.Flag(name: .long, help: "Filter to unresolved comments only.")
    var unresolved: Bool = false

    @ArgumentParser.Flag(name: .long, help: "Filter to resolved comments only.")
    var resolved: Bool = false

    @OptionGroup var output: GlobalOutputOptions

    func validate() throws {
        if unresolved && resolved {
            throw ValidationError("--unresolved and --resolved are mutually exclusive.")
        }
    }

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            let document = try resolvedBundle.currentDocument()

            // Map CLI flags to engine CommentFilter. Type validation is
            // engine-side (CommentType.init returns nil for unknown).
            let filterType: CommentType?
            if let type {
                guard let t = CommentType(rawValue: type) else {
                    let envelope = ErrorEnvelope(
                        error: "invalidArgument",
                        message: "Unknown comment type '\(type)'. Valid: question, suggestion, note, directive, decision.",
                        details: ["argument": AnyCodable("type"), "value": AnyCodable(type)]
                    )
                    envelope.emit(format: output.format)
                    throw MdpalExitCode.generalError.argumentParserCode
                }
                filterType = t
            } else {
                filterType = nil
            }

            // Three-state resolved filter: nil = no filter, true = resolved
            // only, false = unresolved only. CommentFilter mirrors this.
            let resolvedFilter: Bool?
            if resolved { resolvedFilter = true }
            else if unresolved { resolvedFilter = false }
            else { resolvedFilter = nil }

            let filter: CommentFilter? = (section != nil || filterType != nil || resolvedFilter != nil)
                ? CommentFilter(
                    sectionSlug: section,
                    type: filterType,
                    unresolvedOnly: resolvedFilter == false,
                    resolvedOnly: resolvedFilter == true
                  )
                : nil

            let comments = document.listComments(filter: filter)
            let payloads = comments.map(CommentPayload.init(from:))

            switch output.format {
            case .json:
                let payload = CommentsListPayload(
                    comments: payloads,
                    count: payloads.count,
                    filters: FiltersEcho(
                        section: section,
                        type: type,
                        resolved: resolvedFilter
                    )
                )
                try JSONOutput.print(payload)
            case .text:
                if comments.isEmpty {
                    print("(no comments)")
                } else {
                    for c in comments {
                        let mark = c.isResolved ? "[resolved]" : "[open]"
                        print("\(mark) \(c.id) \(c.sectionSlug) (\(c.type.rawValue)) \(c.author): \(c.text)")
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

/// Wire shape for `mdpal comments` per spec.
struct CommentsListPayload: Encodable {
    let comments: [CommentPayload]
    let count: Int
    let filters: FiltersEcho
}

/// Echo of filters that were applied. nil values mean "no filter" and
/// MUST serialize as explicit JSON null per the dispatched spec
/// (consumers expect a stable shape).
struct FiltersEcho: Encodable {
    let section: String?
    let type: String?
    let resolved: Bool?

    private enum CodingKeys: String, CodingKey {
        case section, type, resolved
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let section { try c.encode(section, forKey: .section) }
        else { try c.encodeNil(forKey: .section) }
        if let type { try c.encode(type, forKey: .type) }
        else { try c.encodeNil(forKey: .type) }
        if let resolved { try c.encode(resolved, forKey: .resolved) }
        else { try c.encodeNil(forKey: .resolved) }
    }
}
