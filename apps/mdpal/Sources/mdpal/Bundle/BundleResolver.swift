// What Problem: Every command that operates on a bundle takes a path
// argument that may be: an absolute path to a .mdpal directory, a
// relative path, or (in some commands) a path to the latest.md file
// inside one. Resolving this in each command duplicates logic and
// invites drift.
//
// How & Why: Single resolver that takes the user-supplied path string
// and returns a DocumentBundle. Handles relative-to-cwd resolution,
// validates the bundle exists, and surfaces a usable EngineError if not.
// Does NOT mutate working directory.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import Foundation
import MarkdownPalEngine

enum BundleResolver {

    /// Resolve a user-supplied bundle path string into a DocumentBundle.
    ///
    /// Accepts:
    ///   - Absolute path to a .mdpal directory
    ///   - Relative path (resolved against current working directory)
    ///
    /// Throws EngineError.invalidBundlePath if the path doesn't resolve
    /// to a directory, or any error from DocumentBundle.init(at:).
    static func resolve(_ path: String) throws -> DocumentBundle {
        let absolute: String
        if path.hasPrefix("/") {
            absolute = path
        } else {
            let cwd = FileManager.default.currentDirectoryPath
            absolute = (cwd as NSString).appendingPathComponent(path)
        }
        return try DocumentBundle(at: absolute)
    }
}
