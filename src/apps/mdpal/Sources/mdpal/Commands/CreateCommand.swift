// What Problem: `mdpal create <name> [--dir <path>]` is the bootstrap
// command — creates a new .mdpal bundle directory with an empty initial
// revision so subsequent edit/comment/flag commands have something to
// operate on. mdpal-app's "New Document" flow drives this.
//
// How & Why: Resolves the destination directory (defaults to cwd),
// appends `<name>.mdpal`, and calls `DocumentBundle.create` which writes
// the config, initial empty revision, and dual-latest pointers
// atomically. The wire shape carries the bundle filename, absolute path,
// versionId, revision, and version per the dispatched spec.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct CreateCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new .mdpal bundle.",
        discussion: """
            Creates a new bundle directory at <dir>/<name>.mdpal (defaults
            to the current working directory). Writes the bundle config,
            an empty initial revision, and the dual-latest pointers.

            The <name> argument is the bare bundle name; the .mdpal suffix
            is appended automatically. To create at a custom location,
            pass --dir.
            """
    )

    @Argument(help: "Bundle name (without .mdpal suffix). Becomes <name>.mdpal.")
    var name: String

    @Option(name: .long, help: "Directory in which to create the bundle. Defaults to the current working directory.")
    var dir: String?

    @Option(name: .long, help: "Initial markdown content for the first revision. Defaults to a single-line heading derived from <name>.")
    var content: String?

    @OptionGroup var output: GlobalOutputOptions

    func run() throws {
        do {
            // Resolve the parent directory — explicit --dir, or cwd.
            let parentDir: String
            if let dir {
                parentDir = BundleResolver.canonicalize(dir)
            } else {
                parentDir = FileManager.default.currentDirectoryPath
            }

            // Build the full bundle path: parent / "<name>.mdpal".
            // Reject names that already contain the suffix or path
            // separators — the engine takes a clean name, and slashes
            // would silently traverse directories.
            try Self.validateName(name)
            let bundleFilename = "\(name).mdpal"
            let bundlePath = (parentDir as NSString).appendingPathComponent(bundleFilename)

            // Default initial content is a single H1 heading that mirrors
            // the bundle name. Empty content is valid but produces a bundle
            // with no sections — surprising for new users, so we provide
            // a friendlier default.
            let initialContent = content ?? "# \(name)\n"

            let bundle = try DocumentBundle.create(
                name: name,
                initialContent: initialContent,
                at: bundlePath
            )

            // The freshly-created bundle has exactly one revision.
            guard let firstRevision = try bundle.latestRevision() else {
                // Should be impossible — DocumentBundle.create writes the
                // initial revision before returning.
                throw EngineError.bundleConflict("Newly created bundle has no revisions: \(bundlePath)")
            }

            switch output.format {
            case .json:
                let payload = CreatePayload(
                    bundle: bundleFilename,
                    path: bundle.path,
                    versionId: firstRevision.versionId,
                    revision: firstRevision.revision,
                    version: firstRevision.version
                )
                try JSONOutput.print(payload)
            case .text:
                print("bundle:    \(bundleFilename)")
                print("path:      \(bundle.path)")
                print("versionId: \(firstRevision.versionId)")
                print("revision:  \(firstRevision.revision)")
                print("version:   \(firstRevision.version)")
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }

    /// Reject names that would silently traverse paths, embed control
    /// characters, or already carry the bundle suffix. The CLI surface is
    /// "bare name" — let the engine own the suffix and the parent directory.
    ///
    /// Allowed: ASCII letters, digits, `_`, `-`, `.` — but NOT as a leading
    /// character (a leading dot creates a hidden bundle on Unix; a leading
    /// dash makes scripted callers fight ArgumentParser's flag parsing).
    /// `..` and `.` (entire name) are rejected explicitly because they
    /// resolve as directory traversal under any `--dir` argument.
    static func validateName(_ name: String) throws {
        if name.isEmpty {
            throw EngineError.invalidBundlePath(
                path: name,
                reason: "Bundle name must not be empty"
            )
        }
        if name == "." || name == ".." {
            throw EngineError.invalidBundlePath(
                path: name,
                reason: "Bundle name must not be '.' or '..' — those resolve as directory traversal"
            )
        }
        if name.contains("/") || name.contains("\\") {
            throw EngineError.invalidBundlePath(
                path: name,
                reason: "Bundle name must not contain path separators — pass a directory via --dir instead"
            )
        }
        if name.hasSuffix(".mdpal") {
            throw EngineError.invalidBundlePath(
                path: name,
                reason: "Bundle name must not include the .mdpal suffix — it is appended automatically"
            )
        }
        if name.hasPrefix(".") {
            throw EngineError.invalidBundlePath(
                path: name,
                reason: "Bundle name must not start with '.' — that creates a hidden bundle"
            )
        }
        if name.hasPrefix("-") {
            throw EngineError.invalidBundlePath(
                path: name,
                reason: "Bundle name must not start with '-' — clashes with CLI option parsing"
            )
        }
        // Reject control characters (NUL through 0x1F, plus 0x7F DEL).
        // These either get silently truncated by Foundation (NUL) or land
        // in the filesystem as unreadable garbage.
        for scalar in name.unicodeScalars where scalar.value < 0x20 || scalar.value == 0x7F {
            throw EngineError.invalidBundlePath(
                path: name,
                reason: "Bundle name must not contain control characters"
            )
        }
    }
}

/// Wire shape for `mdpal create` per the dispatched spec.
struct CreatePayload: Encodable {
    let bundle: String
    let path: String
    let versionId: String
    let revision: Int
    let version: Int
}
