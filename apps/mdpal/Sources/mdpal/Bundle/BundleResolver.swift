// What Problem: Every command that operates on a bundle takes a path
// argument that may be: an absolute path to a .mdpal directory, a
// relative path, a `~`-prefixed home-relative path, or a path with
// `..` segments. Resolving this in each command duplicates logic and
// invites drift.
//
// How & Why: Single resolver that takes the user-supplied path string
// and returns a DocumentBundle. Handles tilde expansion, relative-to-cwd
// resolution, and `..` normalization via standardizedFileURL. Does NOT
// mutate working directory.
//
// **Phase 3 iter 3.4: optional sandbox-root policy via MDPAL_ROOT env
// var.** When set, the resolver canonicalizes the bundle path, resolves
// any symlinks via realpath, and rejects any path that does not share
// the MDPAL_ROOT prefix. REJECT mode (no relative-resolution magic).
// Closes Sec-1 from Phase 2 phase-complete backlog.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)
// Updated: 2026-04-19 (Phase 3 iter 3.4 — MDPAL_ROOT sandbox)

import Foundation
import MarkdownPalEngine

enum BundleResolver {

    /// Environment variable name for the optional sandbox root.
    /// When set to a non-empty path, BundleResolver.resolve rejects any
    /// bundle path whose canonicalized + symlink-resolved form does not
    /// share this prefix. When unset, no sandbox is enforced (legacy
    /// behavior — backwards compatible).
    static let sandboxEnvVar = "MDPAL_ROOT"

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
    /// **Sandbox enforcement (iter 3.4):** if `MDPAL_ROOT` is set in the
    /// environment, the resolved path is symlink-followed via realpath
    /// and checked against the root prefix. Paths outside the root throw
    /// `EngineError.invalidBundlePath` with reason "outside MDPAL_ROOT
    /// sandbox" — no resolution attempted, the caller learns the bundle
    /// is forbidden.
    ///
    /// Throws EngineError.invalidBundlePath if the path doesn't resolve
    /// to a valid .mdpal bundle directory or escapes the sandbox, or
    /// any error from DocumentBundle.init(at:).
    static func resolve(_ path: String) throws -> DocumentBundle {
        let absolute = canonicalize(path)
        try enforceSandbox(absolute, originalArgument: path)
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

    /// **Phase 3 iter 3.4.** Enforce the MDPAL_ROOT sandbox if configured.
    ///
    /// When MDPAL_ROOT is set:
    ///   1. Canonicalize the root and the bundle path (tilde + abs + lexical normalize).
    ///   2. Resolve symlinks in BOTH paths via realpath. Without this step a
    ///      symlink at <root>/foo.mdpal pointing at /etc would let the
    ///      bundle escape the sandbox via prefix-check on the link path.
    ///   3. Compare the resolved bundle path's prefix against the resolved
    ///      root with a trailing-slash gate so that root="/a/b" rejects "/a/bcd".
    ///   4. Reject with invalidBundlePath("outside MDPAL_ROOT sandbox: ...").
    ///
    /// When MDPAL_ROOT is unset or empty, no enforcement (legacy behavior).
    static func enforceSandbox(_ absoluteBundlePath: String, originalArgument: String) throws {
        let env = ProcessInfo.processInfo.environment
        guard let rawRoot = env[sandboxEnvVar], !rawRoot.isEmpty else {
            return
        }
        let rootCanonical = canonicalize(rawRoot)
        let rootResolved = realpathOrSelf(rootCanonical)
        // The bundle path may not exist yet (e.g., wrap-create scenarios)
        // so realpath may fall back to the lexical canonical. That's OK —
        // we still enforce the prefix check on the lexical form.
        let bundleResolved = realpathOrSelf(absoluteBundlePath)
        let rootWithSlash = rootResolved.hasSuffix("/") ? rootResolved : rootResolved + "/"
        // Bundle path equal to root is rejected (root itself is not a bundle);
        // bundle path that starts with root + "/" is accepted.
        if bundleResolved == rootResolved {
            throw EngineError.invalidBundlePath(
                path: originalArgument,
                reason: "Resolved path equals MDPAL_ROOT itself; bundle must be a child"
            )
        }
        guard bundleResolved.hasPrefix(rootWithSlash) else {
            throw EngineError.invalidBundlePath(
                path: originalArgument,
                reason: "Resolved path is outside MDPAL_ROOT sandbox (\(rootResolved))"
            )
        }
    }

    /// realpath() with fallback to the input on failure (typical for
    /// not-yet-existing paths). Uses the POSIX C function directly.
    private static func realpathOrSelf(_ path: String) -> String {
        var buffer = [CChar](repeating: 0, count: Int(PATH_MAX) + 1)
        guard let resolved = realpath(path, &buffer) else {
            return path
        }
        return String(cString: resolved)
    }
}
