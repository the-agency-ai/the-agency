// What Problem: The engine needs deterministic content hashing for optimistic
// concurrency — each section gets a version hash computed from its content,
// and edit operations compare hashes to detect conflicts.
//
// How & Why: SHA-256 of the section content, truncated to 12 hex characters.
// Using CryptoKit (available on macOS 10.15+) for the hash. 12 hex chars =
// 48 bits of entropy, giving collision probability of ~1 in 281 trillion —
// more than sufficient for version comparison within a single document.
// Deterministic: same content always produces the same hash.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.1 rebuild)

import Foundation
import CryptoKit

/// Compute a deterministic version hash for section content.
///
/// Uses SHA-256, truncated to 12 hex characters. Same content → same hash.
/// Used for optimistic concurrency in edit operations.
public enum VersionHash {

    /// Compute the version hash for the given content string.
    ///
    /// - Parameter content: The section content to hash.
    /// - Returns: 12-character lowercase hex string.
    public static func compute(_ content: String) -> String {
        let data = Data(content.utf8)
        let digest = SHA256.hash(data: data)
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return String(hex.prefix(12))
    }
}
