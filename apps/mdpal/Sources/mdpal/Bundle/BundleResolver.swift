// What Problem: Every command that operates on a bundle takes a path
// argument that may be: an absolute path to a .mdpal directory, a
// relative path, a `~`-prefixed home-relative path, or a path with
// `..` segments. Resolving this in each command duplicates logic and
// invites drift.
//
// How & Why: Single resolver that takes the user-supplied path string
// and returns a DocumentBundle. Handles tilde expansion, relative-to-cwd
// resolution, and `..` normalization via standardizedFileURL. Does NOT
// mutate working directory. Does NOT enforce a sandbox root — that's a
// caller policy choice (see security finding deferred to Phase 1.5).
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import Foundation
import MarkdownPalEngine

enum BundleResolver {

    /// Resolve a user-supplied bundle path string into a DocumentBundle.
    ///
    /// Accepts:
    ///   - Absolute path (`/Users/jdm/docs/foo.mdpal`)
    ///   - Tilde-relative (`~/docs/foo.mdpal`)
    ///   - Working-directory-relative (`./foo.mdpal`, `../sibling/foo.mdpal`,
    ///     or bare `foo.mdpal`)
    ///
    /// Path is normalized: `..` segments are resolved, redundant slashes
    /// removed. Symlinks in the path are NOT resolved here (engine-side
    /// `validateBundlePath` and `listRevisions` enforce file-type checks).
    ///
    /// Throws EngineError.invalidBundlePath if the path doesn't resolve
    /// to a valid .mdpal bundle directory, or any error from
    /// DocumentBundle.init(at:).
    static func resolve(_ path: String) throws -> DocumentBundle {
        let absolute = canonicalize(path)
        return try DocumentBundle(at: absolute)
    }

    /// Convert a user-supplied path to an absolute, normalized form.
    /// Exposed (internal) so tests can verify resolution behavior
    /// without spinning up a full bundle.
    static func canonicalize(_ path: String) -> String {
        // Tilde expansion first — `~` and `~user` become real home dirs.
        let expanded = (path as NSString).expandingTildeInPath

        // If still relative after expansion, anchor to current working dir.
        let absolute: String
        if expanded.hasPrefix("/") {
            absolute = expanded
        } else {
            let cwd = FileManager.default.currentDirectoryPath
            absolute = (cwd as NSString).appendingPathComponent(expanded)
        }

        // Normalize `..` segments and redundant slashes via URL standardization.
        // standardizedFileURL handles `.` and `..` purely lexically — it does
        // NOT consult the filesystem, so it doesn't follow symlinks (which is
        // what we want; the engine enforces file-type policy).
        return URL(fileURLWithPath: absolute).standardizedFileURL.path
    }
}
