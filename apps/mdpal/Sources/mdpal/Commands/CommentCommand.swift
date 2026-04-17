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

    @Option(name: .long, help: "Comment body text (mutually exclusive with --text-stdin).")
    var text: String?

    @ArgumentParser.Flag(name: .long, help: "Read comment text from stdin (avoids ARG_MAX limits for long bodies).")
    var textStdin: Bool = false

    @Option(name: .long, help: "Override the auto-captured section context.")
    var context: String?

    @Option(name: .long, help: "Priority: low, normal, high. Defaults to normal.")
    var priority: String?

    @Option(name: .long, help: "Tag to apply to the comment. Repeat for multiple tags (e.g., --tag perf --tag phase2).")
    var tag: [String] = []

    @OptionGroup var output: GlobalOutputOptions

    func validate() throws {
        if text != nil && textStdin {
            throw ValidationError("Specify either --text or --text-stdin, not both.")
        }
        if text == nil && !textStdin {
            throw ValidationError("One of --text or --text-stdin is required.")
        }
    }

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            let document = try resolvedBundle.currentDocument()

            // Resolve text from --text or stdin (bounded read).
            let resolvedText: String
            if let text {
                resolvedText = text
            } else {
                do {
                    resolvedText = try StdinReader.readAll()
                } catch let f as StdinReader.ReadFailure {
                    f.envelope.emit(format: output.format)
                    throw MdpalExitCode.generalError.argumentParserCode
                }
            }

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

            // Repeatable --tag is a [String]; nil if user passed no tags.
            let parsedTags: [String]? = tag.isEmpty ? nil : tag

            let comment = try document.addComment(NewComment(
                type: commentType,
                author: author,
                sectionSlug: slug,
                text: resolvedText,
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
