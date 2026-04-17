// What Problem: When a command fails, mdpal-app needs structured error
// info: an error code (string, distinct from exit code), a human message,
// and any error-specific details (e.g., versionConflict carries the
// expected hash, actual hash, and current section content). Plain text
// on stderr forces brittle string parsing.
//
// How & Why: ErrorEnvelope is the wire shape for every error. It's
// emitted to stderr as JSON when --format json (default) and to stderr
// as a one-line summary when --format text. Exit code is set separately
// via ExitCode. Every EngineError case maps to a code string here.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import Foundation
import MarkdownPalEngine

/// Wire shape for every CLI error. Emitted to stderr as JSON.
struct ErrorEnvelope: Encodable {
    /// Stable error code string (e.g., "version_conflict"). Maps 1:1 to
    /// EngineError cases. mdpal-app matches on this, NOT on the message.
    let code: String

    /// Human-readable error description.
    let message: String

    /// Error-specific structured details. Only some codes populate this.
    let details: [String: AnyCodable]?

    init(code: String, message: String, details: [String: AnyCodable]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

/// Type-erased Encodable for heterogeneous detail dictionaries.
struct AnyCodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        _encode = { encoder in try wrapped.encode(to: encoder) }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

extension ErrorEnvelope {

    /// Emit this envelope to stderr as JSON and return the corresponding
    /// exit code. Caller is expected to `Mdpal.exit(withError:)` or
    /// `throw ExitCode(rawValue:)` after.
    func emit(format: OutputFormat = .json) {
        switch format {
        case .json:
            if let json = try? JSONOutput.string(self) {
                FileHandle.standardError.write(Data((json + "\n").utf8))
            } else {
                FileHandle.standardError.write(Data("{\"code\":\"output_failed\",\"message\":\"failed to encode error envelope\"}\n".utf8))
            }
        case .text:
            FileHandle.standardError.write(Data("\(code): \(message)\n".utf8))
        }
    }
}

/// Map an EngineError into the ErrorEnvelope wire shape + exit code.
enum EngineErrorMapper {

    static func envelope(for error: EngineError) -> (envelope: ErrorEnvelope, exit: MdpalExitCode) {
        switch error {
        case .parseError(let message, let line, let column):
            var details: [String: AnyCodable]? = nil
            if line != nil || column != nil {
                var d: [String: AnyCodable] = [:]
                if let line { d["line"] = AnyCodable(line) }
                if let column { d["column"] = AnyCodable(column) }
                details = d
            }
            return (
                ErrorEnvelope(code: "parse_error", message: message, details: details),
                .generalError
            )
        case .metadataError(let message):
            return (
                ErrorEnvelope(code: "metadata_error", message: message),
                .generalError
            )
        case .sectionNotFound(let slug, let suggestions):
            let details: [String: AnyCodable] = [
                "slug": AnyCodable(slug),
                "suggestions": AnyCodable(suggestions),
            ]
            return (
                ErrorEnvelope(
                    code: "section_not_found",
                    message: "Section '\(slug)' not found",
                    details: details
                ),
                .notFound
            )
        case .versionConflict(let slug, let expected, let actual, let currentContent):
            let details: [String: AnyCodable] = [
                "slug": AnyCodable(slug),
                "expected_hash": AnyCodable(expected),
                "actual_hash": AnyCodable(actual),
                "current_content": AnyCodable(currentContent),
            ]
            return (
                ErrorEnvelope(
                    code: "version_conflict",
                    message: "Section '\(slug)' was modified — expected hash \(expected), got \(actual)",
                    details: details
                ),
                .versionConflict
            )
        case .bundleConflict(let message):
            return (
                ErrorEnvelope(code: "bundle_conflict", message: message),
                .bundleConflict
            )
        case .invalidBundlePath(let path, let reason):
            let details: [String: AnyCodable] = [
                "path": AnyCodable(path),
                "reason": AnyCodable(reason),
            ]
            return (
                ErrorEnvelope(
                    code: "invalid_bundle_path",
                    message: "Invalid bundle path '\(path)': \(reason)",
                    details: details
                ),
                .generalError
            )
        case .commentNotFound(let id):
            let details: [String: AnyCodable] = ["id": AnyCodable(id)]
            return (
                ErrorEnvelope(code: "comment_not_found", message: "Comment '\(id)' not found", details: details),
                .notFound
            )
        case .commentAlreadyResolved(let id):
            let details: [String: AnyCodable] = ["id": AnyCodable(id)]
            return (
                ErrorEnvelope(code: "comment_already_resolved", message: "Comment '\(id)' is already resolved", details: details),
                .generalError
            )
        case .sectionNotFlagged(let slug):
            let details: [String: AnyCodable] = ["slug": AnyCodable(slug)]
            return (
                ErrorEnvelope(code: "section_not_flagged", message: "Section '\(slug)' is not flagged", details: details),
                .generalError
            )
        case .fileError(let path, let description):
            let details: [String: AnyCodable] = [
                "path": AnyCodable(path),
                "description": AnyCodable(description),
            ]
            return (
                ErrorEnvelope(
                    code: "file_error",
                    message: "File error at '\(path)': \(description)",
                    details: details
                ),
                .generalError
            )
        case .unsupportedFormat(let format):
            let details: [String: AnyCodable] = ["format": AnyCodable(format)]
            return (
                ErrorEnvelope(code: "unsupported_format", message: "Unsupported format: \(format)", details: details),
                .generalError
            )
        case .noFilePath:
            return (
                ErrorEnvelope(code: "no_file_path", message: "Document was created without a file path"),
                .generalError
            )
        }
    }
}
