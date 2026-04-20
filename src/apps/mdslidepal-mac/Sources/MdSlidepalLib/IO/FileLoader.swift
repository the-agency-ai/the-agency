// What Problem: Load markdown files from disk and feed them into the parsing
// pipeline. Handles file reading, encoding detection, and error surfacing.
// This is the bridge between the filesystem and DeckState.
//
// How & Why: Simple async file reader that loads a URL into a String, then
// calls DeckState.load(). Separated from DeckState so file I/O can be
// tested independently and to keep the model layer pure.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 2.2

import Foundation

/// File loading utilities for markdown decks.
public struct FileLoader {

    /// Load a markdown file from a URL and return its contents.
    /// Throws if the file can't be read.
    public static func loadString(from url: URL) throws -> String {
        // Try UTF-8 first (most common for markdown)
        if let content = try? String(contentsOf: url, encoding: .utf8) {
            return content
        }
        // Fallback: let Foundation detect encoding
        var encoding: String.Encoding = .utf8
        let content = try String(contentsOf: url, usedEncoding: &encoding)
        return content
    }

    /// Validate that a URL points to a readable markdown file.
    public static func validate(url: URL) -> FileValidation {
        guard url.isFileURL else {
            return .invalid("Not a file URL")
        }
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            return .invalid("File not readable: \(url.lastPathComponent)")
        }
        let ext = url.pathExtension.lowercased()
        if ext != "md" && ext != "markdown" && ext != "mdown" && ext != "txt" {
            return .warning("Unexpected extension: .\(ext) — expected .md")
        }
        return .valid
    }

    public enum FileValidation {
        case valid
        case warning(String)
        case invalid(String)
    }
}
