// What Problem: `mdpal comment <slug> <bundle> --type --author --text
// [--context] [--priority] [--tags]` adds a comment anchored to a
// section. The engine assigns commentId, timestamp, and (when --context
// is omitted) captures the current section content as the historical
// context. Each new comment is a state change on the document, persisted
// as a new revision (append-only invariant).
//
// How & Why: Resolve bundle, fetch latest document, build a NewComment
// from CLI args, call addComment (engine validates section exists,
// assigns id), serialize, write a new revision. Return the persisted
// Comment as JSON.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.3)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct CommentCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "comment",
        abstract: "Add a comment anchored to a section.",
        discussion: """
            Anchors a comment to <slug>. The engine auto-assigns commentId
            and timestamp, and captures current section content as `context`
            unless --context overrides.

            Comment types: question, suggestion, note, directive, decision.
            Priority defaults to 'normal'. Tags are comma-separated.
            """
    )

    @Argument(help: "Section slug to anchor the comment to.")
    var slug: String

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @Option(name: .long, help: "Comment type: question, suggestion, note, directive, decision.")
    var type: String

    @Option(name: .long, help: "Comment author.")
    var author: String

    @Option(name: .long, help: "Comment body text.")
    var text: String

    @Option(name: .long, help: "Override the auto-captured section context.")
    var context: String?

    @Option(name: .long, help: "Priority: low, normal, high. Defaults to normal.")
    var priority: String?

    @Option(name: .long, help: "Comma-separated tags (e.g., 'perf,phase2').")
    var tags: String?

    @OptionGroup var output: GlobalOutputOptions

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            let document = try resolvedBundle.currentDocument()

            guard let commentType = CommentType(rawValue: type) else {
                let envelope = ErrorEnvelope(
                    error: "invalidArgument",
                    message: "Unknown comment type '\(type)'. Valid: question, suggestion, note, directive, decision.",
                    details: ["argument": AnyCodable("type"), "value": AnyCodable(type)]
                )
                envelope.emit(format: output.format)
                throw MdpalExitCode.generalError.argumentParserCode
            }

            let parsedPriority: Priority?
            if let priority {
                guard let p = Priority(rawValue: priority) else {
                    let envelope = ErrorEnvelope(
                        error: "invalidArgument",
                        message: "Unknown priority '\(priority)'. Valid: low, normal, high.",
                        details: ["argument": AnyCodable("priority"), "value": AnyCodable(priority)]
                    )
                    envelope.emit(format: output.format)
                    throw MdpalExitCode.generalError.argumentParserCode
                }
                parsedPriority = p
            } else {
                parsedPriority = nil
            }

            let parsedTags: [String]? = tags.map {
                $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            }

            let comment = try document.addComment(NewComment(
                type: commentType,
                author: author,
                sectionSlug: slug,
                text: text,
                context: context,
                priority: parsedPriority,
                tags: parsedTags
            ))

            // Persist as a new revision.
            let serialized = try document.serialize()
            _ = try resolvedBundle.createRevision(content: serialized)

            switch output.format {
            case .json:
                let payload = CommentPayload(from: comment)
                try JSONOutput.print(payload)
            case .text:
                print("commentId: \(comment.id)")
                print("slug:      \(comment.sectionSlug)")
                print("type:      \(comment.type.rawValue)")
                print("author:    \(comment.author)")
                print("text:      \(comment.text)")
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}
