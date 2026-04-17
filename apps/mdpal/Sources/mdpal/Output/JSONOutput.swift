// What Problem: Every command needs to emit JSON in a consistent shape
// (snake_case keys, ISO-8601 dates, sorted keys for reproducibility).
// Without a shared encoder, each command would drift in its choices and
// mdpal-app would have to handle multiple conventions.
//
// How & Why: Single shared JSONEncoder with explicit configuration:
// snake_case keys, ISO-8601 (UTC) date strategy, pretty-printed with
// sorted keys for diff-friendliness in tests and shell pipelines.
// Single shared decoder mirrors the same choices.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import Foundation

enum JSONOutput {

    /// Shared encoder used by every command. Configuration must match the
    /// dispatched JSON spec to mdpal-app — drift here is a wire-format break.
    static let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return enc
    }()

    /// Shared decoder for inputs (e.g., `mdpal edit --stdin` JSON payloads).
    static let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    /// Encode a value to a UTF-8 string. Throws on encode failure.
    static func string<T: Encodable>(_ value: T) throws -> String {
        let data = try encoder.encode(value)
        guard let s = String(data: data, encoding: .utf8) else {
            throw EngineCLIError.outputEncodingFailed
        }
        return s
    }

    /// Print a value as JSON to stdout, followed by a trailing newline.
    static func print<T: Encodable>(_ value: T) throws {
        let s = try string(value)
        Swift.print(s)
    }
}

/// CLI-internal errors that aren't engine errors.
enum EngineCLIError: Error, CustomStringConvertible {
    case outputEncodingFailed

    var description: String {
        switch self {
        case .outputEncodingFailed: return "failed to encode output as UTF-8 JSON"
        }
    }
}
