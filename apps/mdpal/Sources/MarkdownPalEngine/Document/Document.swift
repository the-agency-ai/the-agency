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
    /// extension. Throws `.unsupportedFormat` if no parser matches and
    /// `.fileError` if the file cannot be read.
    public convenience init(contentsOfFile path: String) throws {
        let content: String
        do {
            content = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw EngineError.fileError(path: path, description: "\(error)")
        }

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
