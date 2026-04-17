// What Problem: Multiple commands accept content via stdin (`mdpal edit
// --stdin`, `mdpal revision create --stdin`, `mdpal comment --text-stdin`,
// `mdpal resolve --response-stdin`). Each one originally hand-rolled the
// FileHandle.standardInput.readDataToEndOfFile() + UTF-8 decode + isatty
// dance. Two issues result: (a) duplication invites drift between commands,
// and (b) the unbounded read is a denial-of-service vector — a multi-GB
// pipe-in causes OOM and writes a multi-GB revision file before any
// engine-side check.
//
// How & Why: Single shared reader that (1) refuses to read from an
// interactive TTY (would hang forever, surfacing a useless "blocked on
// stdin" experience), (2) caps total bytes read at a defensive ceiling
// (16 MiB by default — well above any real human document, well below the
// memory pressure threshold), and (3) decodes as UTF-8, returning a
// well-defined error envelope on bytes that don't decode. Returns the
// decoded string or throws an emit-and-exit pair.
//
// The 16 MiB cap is the same order of magnitude as `git`'s `core.bigFileThreshold`
// default (512 MiB is too generous for a Markdown document; 1 MiB too tight
// for a dump of an entire research transcript). Callers can override per
// command if they have a strong reason; the default is safe.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4 QG fix D2)

import Foundation

enum StdinReader {

    /// Default ceiling on stdin reads (16 MiB).
    static let defaultMaxBytes: Int = 16 * 1024 * 1024

    /// Failure modes — each carries its own error envelope so callers can
    /// `emit` and `throw` from a single switch.
    enum ReadFailure: Error {
        case isTTY
        case payloadTooLarge(maxBytes: Int)
        case invalidEncoding

        var envelope: ErrorEnvelope {
            switch self {
            case .isTTY:
                return ErrorEnvelope(
                    error: "stdinIsTTY",
                    message: "stdin is a terminal; pipe content or pass --content"
                )
            case .payloadTooLarge(let maxBytes):
                return ErrorEnvelope(
                    error: "payloadTooLarge",
                    message: "stdin exceeded the \(maxBytes)-byte ceiling",
                    details: ["maxBytes": AnyCodable(maxBytes)]
                )
            case .invalidEncoding:
                return ErrorEnvelope(
                    error: "invalidEncoding",
                    message: "stdin contained non-UTF-8 bytes"
                )
            }
        }
    }

    /// Read all of stdin (up to `maxBytes`), refusing TTY input and
    /// rejecting non-UTF-8 bytes. Reading is incremental — if the pipe
    /// exceeds the cap we abort BEFORE materializing the full payload as
    /// a String, so a multi-GB attacker stream costs at most `maxBytes`
    /// of resident memory.
    static func readAll(maxBytes: Int = defaultMaxBytes) throws -> String {
        // Refuse interactive-TTY stdin — would block forever.
        if isatty(0) != 0 {
            throw ReadFailure.isTTY
        }

        let handle = FileHandle.standardInput
        var buffer = Data()
        // 64 KiB chunks — small enough to short-circuit on a flood, large
        // enough to amortize syscall overhead on normal reads.
        let chunkSize = 64 * 1024
        while true {
            let chunk = handle.readData(ofLength: chunkSize)
            if chunk.isEmpty { break }
            if buffer.count + chunk.count > maxBytes {
                throw ReadFailure.payloadTooLarge(maxBytes: maxBytes)
            }
            buffer.append(chunk)
        }

        guard let decoded = String(data: buffer, encoding: .utf8) else {
            throw ReadFailure.invalidEncoding
        }
        return decoded
    }
}
