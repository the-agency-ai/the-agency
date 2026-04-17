// What Problem: When a command fails, mdpal-app needs structured error
// info: a discriminator string (`error`), a human message, and any
// error-specific details (e.g., versionConflict carries the expected
// hash, current hash, and current section content). Plain text on
// stderr forces brittle string parsing.
//
// How & Why: ErrorEnvelope is the wire shape for every error — the
// discriminator field is `error` (not `code`) and values are camelCase
// symbol names (e.g., "sectionNotFound") matching the dispatched spec
// to mdpal-app. Emitted to stderr as JSON; exit code is set separately
// via MdpalExitCode. Every EngineError case maps to an `error` value.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import Foundation
import MarkdownPalEngine

/// Wire shape for every CLI error. Emitted to stderr as JSON.
///
/// The discriminator field is `error` (per dispatched spec). mdpal-app
/// switches on this value, NOT on `message`.
struct ErrorEnvelope: Encodable {
    /// Stable error discriminator (e.g., "sectionNotFound"). Maps 1:1 to
    /// EngineError cases. mdpal-app matches on this, NOT on the message.
    let error: String

    /// Human-readable error description.
    let message: String

    /// Error-specific structured details. Only some errors populate this.
    let details: [String: AnyCodable]?

    init(error: String, message: String, details: [String: AnyCodable]? = nil) {
        self.error = error
        self.message = message
        self.details = details
    }
}

/// Type-erased Encodable for heterogeneous detail dictionaries.
///
/// Note: nested encoding is preserved by the captured closure. Detail
/// dictionaries with snake_case keys (e.g., literal "expected_hash")
/// would survive encoding because dictionary keys are NOT transformed
/// by JSONEncoder — only property names. We use camelCase dictionary
/// keys throughout to match the wire format.
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

    /// Emit this envelope to stderr. JSON form by default; text form
    /// is `<error>: <message>\n` (single line, machine-parseable).
    ///
    /// On JSON encode failure (extremely rare — Encodable from a known
    /// shape doesn't fail), falls back to a hand-built JSON object that
    /// preserves the original `error` and `message` so consumers
    /// matching on the discriminator still get the right routing.
    func emit(format: OutputFormat = .json) {
        switch format {
        case .json:
            if let json = try? JSONOutput.string(self) {
                FileHandle.standardError.write(Data((json + "\n").utf8))
            } else {
                // Hand-built fallback that preserves the original error+message
                // (so consumers matching on `error` get the right routing even
                // if the structured encode somehow fails).
                let safeError = JSONString.escape(self.error)
                let safeMessage = JSONString.escape(self.message)
                let fallback = "{\"error\":\"\(safeError)\",\"message\":\"\(safeMessage)\",\"details\":null}\n"
                FileHandle.standardError.write(Data(fallback.utf8))
            }
        case .text:
            FileHandle.standardError.write(Data("\(error): \(message)\n".utf8))
        }
    }
}

/// Minimal JSON string escaper for the encode-failure fallback path.
/// Not a general-purpose JSON encoder — only used to make the fallback
/// envelope well-formed when `JSONEncoder` itself fails.
private enum JSONString {
    static func escape(_ s: String) -> String {
        var out = ""
        for ch in s {
            switch ch {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                let scalar = ch.unicodeScalars.first?.value ?? 0
                if scalar < 0x20 {
                    out += String(format: "\\u%04x", scalar)
                } else {
                    out.append(ch)
                }
            }
        }
        return out
    }
}

/// Map an EngineError into the ErrorEnvelope wire shape + exit code.
///
/// Error discriminator values are camelCase symbol-style (matches the
/// dispatched spec). mdpal-app's RealCLIService switches on these.
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
                ErrorEnvelope(error: "parseError", message: message, details: details),
                .generalError
            )
        case .metadataError(let message):
            return (
                ErrorEnvelope(error: "metadataError", message: message),
                .generalError
            )
        case .sectionNotFound(let slug, let suggestions):
            let details: [String: AnyCodable] = [
                "slug": AnyCodable(slug),
                "availableSlugs": AnyCodable(suggestions),
            ]
            return (
                ErrorEnvelope(
                    error: "sectionNotFound",
                    message: "Section '\(slug)' not found",
                    details: details
                ),
                .notFound
            )
        case .versionConflict(let slug, let expected, let actual, let currentContent):
            let details: [String: AnyCodable] = [
                "slug": AnyCodable(slug),
                "expectedHash": AnyCodable(expected),
                "currentHash": AnyCodable(actual),
                "currentContent": AnyCodable(currentContent),
            ]
            return (
                ErrorEnvelope(
                    error: "versionConflict",
                    message: "Section '\(slug)' was modified — expected hash \(expected), got \(actual)",
                    details: details
                ),
                .versionConflict
            )
        case .bundleConflict(let message):
            return (
                ErrorEnvelope(error: "bundleConflict", message: message),
                .bundleConflict
            )
        case .bundleBaseConflict(let expected, let actual):
            // Spec wire shape (line 384-392 of dispatch-cli-json-output-shapes):
            // {error: "bundleConflict", details: {baseRevision, currentRevision}}.
            // Discriminator stays "bundleConflict" so mdpal-app's switch is
            // unchanged; structured fields land in details for callers that
            // need to re-fetch and merge.
            let details: [String: AnyCodable] = [
                "baseRevision": AnyCodable(expected),
                "currentRevision": AnyCodable(actual),
            ]
            return (
                ErrorEnvelope(
                    error: "bundleConflict",
                    message: "Base revision \(expected) does not match current latest \(actual)",
                    details: details
                ),
                .bundleConflict
            )
        case .invalidBundlePath(let path, let reason):
            let details: [String: AnyCodable] = [
                "path": AnyCodable(path),
                "reason": AnyCodable(reason),
            ]
            return (
                ErrorEnvelope(
                    error: "invalidBundlePath",
                    message: "Invalid bundle path '\(path)': \(reason)",
                    details: details
                ),
                .generalError
            )
        case .commentNotFound(let id):
            let details: [String: AnyCodable] = ["commentId": AnyCodable(id)]
            return (
                ErrorEnvelope(error: "commentNotFound", message: "Comment '\(id)' not found", details: details),
                .notFound
            )
        case .commentAlreadyResolved(let id):
            let details: [String: AnyCodable] = ["commentId": AnyCodable(id)]
            return (
                ErrorEnvelope(error: "commentAlreadyResolved", message: "Comment '\(id)' is already resolved", details: details),
                .generalError
            )
        case .sectionNotFlagged(let slug):
            let details: [String: AnyCodable] = ["slug": AnyCodable(slug)]
            return (
                ErrorEnvelope(error: "sectionNotFlagged", message: "Section '\(slug)' is not flagged", details: details),
                .generalError
            )
        case .fileError(let path, let description):
            let details: [String: AnyCodable] = [
                "path": AnyCodable(path),
                "description": AnyCodable(description),
            ]
            return (
                ErrorEnvelope(
                    error: "fileError",
                    message: "File error at '\(path)': \(description)",
                    details: details
                ),
                .generalError
            )
        case .unsupportedFormat(let format):
            let details: [String: AnyCodable] = ["format": AnyCodable(format)]
            return (
                ErrorEnvelope(error: "unsupportedFormat", message: "Unsupported format: \(format)", details: details),
                .generalError
            )
        case .noFilePath:
            return (
                ErrorEnvelope(error: "noFilePath", message: "Document was created without a file path"),
                .generalError
            )
        }
    }
}
