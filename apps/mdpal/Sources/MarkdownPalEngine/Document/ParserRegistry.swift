// What Problem: Document(contentsOfFile:) needs to pick the right parser
// based on the file extension. Hard-coding "if .md, use MarkdownParser" in
// Document is fragile and prevents adding new format parsers later.
//
// How & Why: A registry that maps file extensions to parser instances.
// Parsers register themselves via DocumentParser.supportedExtensions and
// the registry resolves an extension to a parser at lookup time. Iteration
// 1.2 ships a singleton with MarkdownParser pre-registered. Future formats
// (Org, AsciiDoc, etc.) register additional parsers without touching the
// Document type.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

import Foundation

/// A registry of DocumentParser implementations keyed by file extension.
public final class ParserRegistry: @unchecked Sendable {

    /// The shared registry. MarkdownParser is pre-registered.
    public static let shared: ParserRegistry = {
        let registry = ParserRegistry()
        registry.register(MarkdownParser())
        return registry
    }()

    private var parsers: [String: any DocumentParser] = [:]
    private let lock = NSLock()

    public init() {}

    /// Register a parser for all of its supported extensions.
    public func register(_ parser: any DocumentParser) {
        lock.lock()
        defer { lock.unlock() }
        for ext in type(of: parser).supportedExtensions {
            parsers[ext.lowercased()] = parser
        }
    }

    /// Resolve a parser by file extension. The extension may be passed
    /// with or without the leading dot.
    public func parser(for fileExtension: String) -> (any DocumentParser)? {
        lock.lock()
        defer { lock.unlock() }
        let normalized = fileExtension.hasPrefix(".")
            ? fileExtension.lowercased()
            : "." + fileExtension.lowercased()
        return parsers[normalized]
    }

    /// All registered file extensions.
    public var registeredExtensions: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(parsers.keys).sorted()
    }
}
