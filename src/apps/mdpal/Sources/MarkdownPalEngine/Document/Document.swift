// What Problem: Engine consumers need a single object that bundles a parsed
// section tree, the document's metadata (comments, flags, info), and the
// parser used to read it — so callers can perform section operations without
// juggling separate types. The Document is the central engine type.
//
// How & Why: Reference type (class) per A&D §11.3 — Document is mutated as
// the user adds/resolves comments and flags sections. One designated init
// takes content + parser + optional filePath; convenience inits resolve the
// parser via ParserRegistry or read from disk. Iteration 1.2 establishes
// the model and metadata I/O. Section operations land in iteration 1.3.
//
// Document is intentionally NOT Sendable. Callers own a Document on a
// single thread/actor; passing it across isolation boundaries is unsupported.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

import Foundation

/// A parsed, queryable representation of a structured document.
///
/// A Document bundles the parsed section tree, the YAML metadata block
/// (comments, flags, document info), and the parser used to read it.
///
/// Two initialization modes:
/// - **Library mode** — caller provides raw content; engine parses.
/// - **CLI mode** — engine reads the file from disk via `Document(contentsOfFile:)`.
public final class Document {

    /// The parsed section tree.
    /// Mutated by `editSection` to replace section content in place.
    public internal(set) var sections: SectionTree

    /// The document metadata (comments, flags, info).
    /// Mutated only through `addComment`, `resolveComment`, `flagSection`,
    /// `clearFlag`, and `refreshSection` so lifecycle invariants (id
    /// assignment, slug validation, list-membership semantics) are upheld.
    /// Test code can mutate this directly via `@testable import`.
    public internal(set) var metadata: DocumentMetadata

    /// The parser used to read this document.
    public let parser: any DocumentParser

    /// The file path the document was loaded from, if any.
    public let filePath: String?

    // MARK: - Initialization

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - content: The raw document text.
    ///   - parser: The parser to use for the document format.
    ///   - filePath: Optional source path; recorded for later `save()`.
    public init(
        content: String,
        parser: any DocumentParser,
        filePath: String? = nil
    ) throws {
        self.parser = parser
        self.filePath = filePath

        // Strip the metadata block from content before parsing the section
        // tree, so the metadata YAML doesn't pollute the section structure.
        let (bodyContent, metadata) = try Self.extractMetadata(
            from: content,
            parser: parser
        )

        do {
            self.sections = try parser.parse(bodyContent)
        } catch let error as EngineError {
            throw error
        } catch {
            throw EngineError.parseError(description: "\(error)")
        }
        self.metadata = metadata
    }

    /// CLI mode: read the file from disk and parse it.
    ///
    /// Resolves the parser via `ParserRegistry.shared` based on the file
    /// extension. Throws `.unsupportedFormat` if no parser matches,
    /// `.fileError` if the file cannot be read, and `.fileTooLarge` if
    /// the file exceeds the engine's defensive 16 MiB ceiling (matches
    /// the `revision create --stdin` cap so anything writable is also
    /// readable).
    public convenience init(contentsOfFile path: String) throws {
        // Capped read — defends against accidental or hostile multi-GB
        // revision files. Limit is the same as StdinReader's cap so a
        // bundle written by THIS engine is always readable by THIS engine.
        let content = try SizedFileReader.readRevisionUTF8(at: path)

        let pathExtension = (path as NSString).pathExtension
        guard !pathExtension.isEmpty else {
            throw EngineError.unsupportedFormat(fileExtension: "")
        }
        let fileExtension = "." + pathExtension
        guard let parser = ParserRegistry.shared.parser(for: fileExtension) else {
            throw EngineError.unsupportedFormat(fileExtension: fileExtension)
        }

        try self.init(content: content, parser: parser, filePath: path)
    }

    // MARK: - Serialization

    /// Serialize the document back to its source format.
    /// Includes the metadata block at the end of the document.
    public func serialize() throws -> String {
        let body = try parser.serialize(sections)
        let yaml = try MetadataSerializer.encode(metadata)
        return parser.writeMetadataBlock(yaml, into: body)
    }

    /// **Phase 3 iter 3.3.** Flatten the document to plain Markdown
    /// (pancake form). Returns the parsed section body without the
    /// engine's metadata block. Optionally appends comments and/or flags
    /// as separate Markdown sections at the end so the output stays
    /// valid Markdown a downstream tool can read.
    ///
    /// Empty body → single newline (POSIX text-file convention).
    ///
    /// - Parameters:
    ///   - includeComments: When true, appends a `## Comments` section
    ///     listing each comment as a sub-block with id / type / author
    ///     / text / context. Resolved comments include the resolution.
    ///   - includeFlags: When true, appends a `## Flags` section listing
    ///     each flag as `- <slug>: <author> — <note>` lines.
    /// - Returns: pancake Markdown string.
    public func flatten(includeComments: Bool = false, includeFlags: Bool = false) throws -> String {
        var output = try parser.serialize(sections)

        // Empty body convention: single newline (POSIX text-file).
        if output.isEmpty {
            output = "\n"
        }

        if includeComments && !metadata.allComments.isEmpty {
            // Trim trailing newlines so the spacing between body and
            // appended sections is consistent.
            while output.hasSuffix("\n") { output.removeLast() }
            output += "\n\n## Comments\n\n"
            for comment in metadata.allComments {
                output += "### \(comment.id) (\(comment.type.rawValue), \(comment.author))\n\n"
                output += "Section: `\(comment.sectionSlug)`  \n"
                output += "Context: \(comment.context)\n\n"
                output += "\(comment.text)\n\n"
                if let resolution = comment.resolution {
                    output += "**Resolved by \(resolution.resolvedBy):** \(resolution.response)\n\n"
                }
            }
        }

        if includeFlags && !metadata.flags.isEmpty {
            while output.hasSuffix("\n") { output.removeLast() }
            output += "\n\n## Flags\n\n"
            for flag in metadata.flags {
                let noteSuffix = flag.note.map { " — \($0)" } ?? ""
                output += "- `\(flag.sectionSlug)` (\(flag.author))\(noteSuffix)\n"
            }
            output += "\n"
        }

        // Always end with exactly one trailing newline.
        while output.hasSuffix("\n\n") { output.removeLast() }
        if !output.hasSuffix("\n") { output += "\n" }

        return output
    }

    /// Write the document back to its source file path (CLI mode only).
    /// Throws `.noFilePath` if the document was created in library mode.
    public func save() throws {
        guard let path = filePath else {
            throw EngineError.noFilePath
        }
        try save(to: path)
    }

    /// Write the document to a specific path.
    public func save(to path: String) throws {
        let content = try serialize()
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw EngineError.fileError(path: path, description: "\(error)")
        }
    }

    // MARK: - Metadata extraction

    /// Extract the metadata block from raw content.
    /// Returns the content with the metadata block stripped, and the parsed
    /// metadata (or a blank metadata object if no block was present).
    private static func extractMetadata(
        from content: String,
        parser: any DocumentParser
    ) throws -> (body: String, metadata: DocumentMetadata) {
        guard let range = parser.findMetadataBlock(in: content) else {
            return (content, DocumentMetadata.blank())
        }
        let yaml = String(content[range.contentRange])
        let metadata = try MetadataSerializer.decode(yaml)

        // Strip the outer block from the body and normalize trailing newlines.
        var body = content
        body.removeSubrange(range.outerRange)
        // Trim ALL trailing whitespace, then re-append a single newline so
        // serialized output stays consistent regardless of input shape.
        while let last = body.last, last.isWhitespace {
            body.removeLast()
        }
        if !body.isEmpty {
            body += "\n"
        }
        return (body, metadata)
    }
}
