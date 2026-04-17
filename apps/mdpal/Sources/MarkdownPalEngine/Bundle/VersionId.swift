// What Problem: The version ID format `V{NNNN}.{NNNN}.{YYYYMMDD}T{HHMM}Z`
// is parsed and constructed from many places. Centralizing the format
// logic in one type prevents drift and makes the format easy to test.
//
// How & Why: A namespace enum (no instances) with parse + format functions.
// Parse is strict — rejects malformed strings. Format uses POSIX locale
// to avoid calendar-dependent year corruption.
//
// The numeric fields are validated with an explicit all-digits check
// because Swift's Int(_:) accepts leading `+`/`-` signs, which would
// let `V+001.0003.20260407T1200Z` parse as version 1 — a malformed
// ID slipping through validation.
//
// DateFormatter is cached at static scope. Foundation formatters are
// thread-safe for read-only formatting on Apple platforms, and the
// formatter here is configured once and never mutated. Caching
// eliminates per-call allocation on every revision walk.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.4)
// Updated: 2026-04-15 — QG fixes: reject leading sign in numeric parse,
//          cache DateFormatter at static scope.

import Foundation

/// Composite version identifier helpers for `V{NNNN}.{NNNN}.{YYYYMMDD}T{HHMM}Z`.
public enum VersionId {

    /// Parsed components of a version ID.
    public struct Components: Equatable, Sendable {
        public let version: Int
        public let revision: Int
        public let timestamp: Date

        public init(version: Int, revision: Int, timestamp: Date) {
            self.version = version
            self.revision = revision
            self.timestamp = timestamp
        }
    }

    /// Format components into a version ID string.
    public static func format(version: Int, revision: Int, timestamp: Date) -> String {
        let datePart = Self.formatTimestamp(timestamp)
        return String(format: "V%04d.%04d.%@", version, revision, datePart)
    }

    /// Parse a version ID string into components.
    /// Returns nil if the string doesn't match the format.
    public static func parse(_ string: String) -> Components? {
        // Format: V {4} . {4} . {8} T {4} Z = 1+4+1+4+1+8+1+4+1 = 25 chars.
        // Index map:
        //   V = 0
        //   version = 1..<5
        //   . = 5
        //   revision = 6..<10
        //   . = 10
        //   date = 11..<19
        //   T = 19
        //   time = 20..<24
        //   Z = 24
        guard string.count == 25 else { return nil }
        guard string.hasPrefix("V") else { return nil }
        guard string.hasSuffix("Z") else { return nil }
        let chars = Array(string)
        guard chars[5] == "." else { return nil }
        guard chars[10] == "." else { return nil }
        guard chars[19] == "T" else { return nil }

        let versionStr = String(chars[1..<5])
        let revisionStr = String(chars[6..<10])
        let dateStr = String(chars[11..<19])
        let timeStr = String(chars[20..<24])

        // Reject leading sign (`+001`, `-001`) — Int(_:) would accept it
        // and mis-parse version numbers from malformed IDs.
        guard versionStr.allSatisfy(\.isASCIIDigit) else { return nil }
        guard revisionStr.allSatisfy(\.isASCIIDigit) else { return nil }
        guard let version = Int(versionStr) else { return nil }
        guard let revision = Int(revisionStr) else { return nil }

        guard let timestamp = cachedFormatter.date(from: "\(dateStr)T\(timeStr)Z") else {
            return nil
        }

        return Components(version: version, revision: revision, timestamp: timestamp)
    }

    /// Format a Date as the date+time portion (e.g., "20260404T1200Z").
    public static func formatTimestamp(_ date: Date) -> String {
        cachedFormatter.string(from: date)
    }

    /// Cached DateFormatter for UTC + POSIX locale + Gregorian calendar.
    /// Thread-safe for read-only formatting on Apple platforms.
    private static let cachedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmm'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()
}

private extension Character {
    /// True only for ASCII digits `0`–`9`. Locale-independent.
    var isASCIIDigit: Bool {
        guard let ascii = asciiValue else { return false }
        return ascii >= 0x30 && ascii <= 0x39
    }
}
