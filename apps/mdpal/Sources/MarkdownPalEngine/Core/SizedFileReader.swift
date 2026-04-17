// What Problem: The engine reads .mdpal bundle files (config YAML +
// revision markdown) without any defensive cap on file size. A malicious
// bundle (planted by an attacker, downloaded from a registry, or shipped
// in a git/tar) can include a multi-GB revision file or a YAML
// billion-laughs amplification — both OOM the engine before it has a
// chance to fail gracefully. The same vector applies to bundles users
// import from elsewhere on disk.
//
// How & Why: Single shared reader that statvfs-style checks the file
// size BEFORE reading the contents. Two ceilings:
//   - configMaxBytes (64 KiB) — bundle config YAML is tiny by design;
//     a config larger than this is either corrupt or hostile.
//   - revisionMaxBytes (16 MiB) — matches the StdinReader ceiling so a
//     revision created via stdin can never exceed what the engine will
//     subsequently read back. 16 MiB is well above any real document.
//
// Failure mode: surfaces as `EngineError.fileTooLarge` with both the
// observed size and the limit, so callers can re-cap (programmatic) or
// surface to the user (CLI) with actionable detail. The check happens
// BEFORE the read, so the offending bytes never enter memory.
//
// Note on YAML billion-laughs: libyaml (which Yams wraps) has a built-in
// alias recursion limit, so a CRAFTED billion-laughs YAML hits the alias
// guard before this size cap matters. But the size cap also blocks
// plain-text amplification (e.g., a 1 GB YAML file with no aliases at
// all), which the alias guard does not catch.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.5)

import Foundation

/// Bounded file readers used throughout the engine. All inputs go
/// through this gate so size limits are enforced at one seam.
///
/// `public` so the CLI layer (which has its own size cap on stdin via
/// `StdinReader`) can reference the same constants — single source of
/// truth across both the read and write paths.
public enum SizedFileReader {

    /// Defensive ceiling for `.mdpal/config.yaml`. The bundle config
    /// schema is fixed (name, prune.keep, prune.auto) — well under 1 KB
    /// in practice. 64 KiB is a generous safety net.
    public static let configMaxBytes: Int = 64 * 1024

    /// Defensive ceiling for revision file reads. The CLI's `StdinReader`
    /// must use this exact value as its stdin cap so a revision created
    /// via `revision create --stdin` is always readable back through the
    /// engine. Single source of truth — do NOT duplicate this constant.
    public static let revisionMaxBytes: Int = 16 * 1024 * 1024

    /// Defensive ceiling for the `.mdpal/latest` pointer file (matches
    /// `readPointerFile` validation expectations).
    public static let pointerMaxBytes: Int = 256

    /// Read the file at `path` as UTF-8, refusing the read if the
    /// on-disk size exceeds `maxBytes` OR if the path is not a regular
    /// file (symlinks, directories, sockets, devices all rejected).
    ///
    /// The regular-file check closes the symlink TOCTOU window:
    /// `listRevisions` filters symlinks at list time (Phase 1 C2 fix),
    /// but a malicious actor could swap a revision file for a symlink
    /// to `/etc/passwd` between the list and a subsequent
    /// `Document(contentsOfFile:)` read. Checking again at read time
    /// (and using the same FileAttributeType result for the size check)
    /// blocks the swap. Following the symlink would otherwise let an
    /// attacker read arbitrary files with the engine's privileges.
    ///
    /// Read a revision file (`<bundlePath>/V{NNNN}.{NNNN}.{ts}.md`)
    /// at the engine's revision cap.
    public static func readRevisionUTF8(at path: String) throws -> String {
        try readUTF8(at: path, maxBytes: revisionMaxBytes)
    }

    /// Read the bundle config (`.mdpal/config.yaml`) at the engine's
    /// config cap.
    public static func readConfigUTF8(at path: String) throws -> String {
        try readUTF8(at: path, maxBytes: configMaxBytes)
    }

    /// Read the pointer file (`.mdpal/latest`) at the engine's pointer cap.
    public static func readPointerUTF8(at path: String) throws -> String {
        try readUTF8(at: path, maxBytes: pointerMaxBytes)
    }

    /// - Throws: `EngineError.fileError` for any I/O failure (missing
    ///   file, permission denied, unreadable bytes, non-regular type),
    ///   and `EngineError.fileTooLarge` if the file exceeds `maxBytes`.
    public static func readUTF8(at path: String, maxBytes: Int) throws -> String {
        let fileManager = FileManager.default

        // Stat the file: get type AND size from one syscall.
        let attrs: [FileAttributeKey: Any]
        do {
            attrs = try fileManager.attributesOfItem(atPath: path)
        } catch {
            throw EngineError.fileError(path: path, description: "stat failed: \(error)")
        }

        // Reject non-regular files (symlinks, directories, devices, sockets).
        // Phase 1 C2 follow-up: closes the TOCTOU window between list-time
        // type filter and read-time symlink follow.
        if let type = attrs[.type] as? FileAttributeType, type != .typeRegular {
            throw EngineError.fileError(
                path: path,
                description: "Refusing to read non-regular file (type: \(type.rawValue))"
            )
        }

        // Extract size from same attributes block.
        let sizeBytes: Int
        if let size = attrs[.size] as? Int {
            sizeBytes = size
        } else if let size = attrs[.size] as? Int64 {
            sizeBytes = Int(size)
        } else if let size = attrs[.size] as? NSNumber {
            sizeBytes = size.intValue
        } else {
            // Fall back to read-then-check if size attribute is missing.
            // This is a defense-in-depth path; size is normally present.
            // Use Data to measure ON-DISK byte count (raw.utf8.count is a
            // post-decode count and may not match the file size if the
            // bytes contained a BOM or were lossily decoded).
            let url = URL(fileURLWithPath: path)
            let rawData: Data
            do {
                rawData = try Data(contentsOf: url)
            } catch {
                throw EngineError.fileError(path: path, description: "\(error)")
            }
            if rawData.count > maxBytes {
                throw EngineError.fileTooLarge(
                    path: path,
                    sizeBytes: rawData.count,
                    limitBytes: maxBytes
                )
            }
            guard let decoded = String(data: rawData, encoding: .utf8) else {
                throw EngineError.fileError(path: path, description: "non-UTF-8 bytes")
            }
            return decoded
        }

        if sizeBytes > maxBytes {
            throw EngineError.fileTooLarge(
                path: path,
                sizeBytes: sizeBytes,
                limitBytes: maxBytes
            )
        }

        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw EngineError.fileError(path: path, description: "\(error)")
        }
    }
}
