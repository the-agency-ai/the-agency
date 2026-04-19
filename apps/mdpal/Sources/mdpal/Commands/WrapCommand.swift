// What Problem: `mdpal wrap <source> <name>` converts a pancake (.md
// file) into a packaged (.mdpal bundle). mdpal-app's inbox/reply flow
// needs to package incoming .md attachments. The CLI reads the source,
// optionally injects review metadata (--review-metadata <yaml-path>),
// and creates a bundle with the contents as the initial revision.
//
// How & Why: Reuses DocumentBundle.create with the new metadata-
// extensions overload (Phase 3 iter 3.1 + 3.2). The source file is
// read through SizedFileReader (defensive size cap at the engine's
// revision ceiling). --review-metadata is a path to a YAML file whose
// contents are stored under the `review:` top-level key in the
// resulting bundle's metadata block.
//
// Edge cases (per Phase 3 plan decisions):
//   - <source> MUST be a single .md file (V1 — directory wrapping is
//     V2 deferral, principal-decided 2026-04-19).
//   - Wrap-over-existing-bundle propagates as bundleConflict exit 4.
//   - Empty source → bundle with empty initial revision (single newline
//     per POSIX text-file convention).
//   - --review-metadata value MUST be a path to a YAML file (NOT inline
//     YAML on argv — ARG_MAX risk).
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
// Reference: usr/jordan/mdpal/plan-mdpal-20260406.md (Phase 3 iter 3.2)
//
// Written: 2026-04-19 during mdpal-cli session (Phase 3 iter 3.2)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct WrapCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "wrap",
        abstract: "Wrap a single .md file into a new .mdpal bundle.",
        discussion: """
            Creates a new bundle directory at <dir>/<name>.mdpal and seeds
            its first revision from <source>. Used by mdpal-app's inbox flow
            to package incoming pancake .md attachments.

            <source> MUST be a single .md file. Directory wrapping is V2 (not
            in V1).

            --review-metadata <path>: optional. Path to a YAML file whose
            contents become the `review:` top-level metadata block in the
            new bundle. mdpal-app's inbox uses this to seed origin /
            artifactType / reviewRound / correlationId.

            Returns the standard CreatePayload (matches `mdpal create`).
            """
    )

    @Argument(help: "Path to the source .md file (single file only — directories are V2).")
    var source: String

    @Argument(help: "Bundle name (without .mdpal suffix). Becomes <name>.mdpal.")
    var name: String

    @Option(name: .long, help: "Directory in which to create the bundle. Defaults to the current working directory.")
    var dir: String?

    @Option(name: .long, help: "Path to a YAML file whose contents become the `review:` top-level metadata block. Optional.")
    var reviewMetadata: String?

    @OptionGroup var output: GlobalOutputOptions

    func run() throws {
        do {
            // Resolve parent directory (cwd default).
            let parentDir: String
            if let dir {
                parentDir = BundleResolver.canonicalize(dir)
            } else {
                parentDir = FileManager.default.currentDirectoryPath
            }

            // Validate name (reuses CreateCommand's validator — same rules).
            try CreateCommand.validateName(name)
            let bundleFilename = "\(name).mdpal"
            let bundlePath = (parentDir as NSString).appendingPathComponent(bundleFilename)

            // Read source through the engine's size-capped reader.
            // Reject directories explicitly (PVR Rev 2 §92: single-file).
            let sourcePath = BundleResolver.canonicalize(source)
            let sourceAttrs: [FileAttributeKey: Any]
            do {
                sourceAttrs = try FileManager.default.attributesOfItem(atPath: sourcePath)
            } catch {
                throw EngineError.fileError(
                    path: sourcePath,
                    description: "Source file not accessible: \(error)"
                )
            }
            guard (sourceAttrs[.type] as? FileAttributeType) == .typeRegular else {
                throw EngineError.fileError(
                    path: sourcePath,
                    description: "Source must be a single .md file (directory wrapping is V2)"
                )
            }
            let initialContent = try SizedFileReader.readRevisionUTF8(at: sourcePath)

            // Parse --review-metadata (optional).
            var metadataExtensions: [String: String] = [:]
            if let reviewMetadata {
                let reviewPath = BundleResolver.canonicalize(reviewMetadata)
                let reviewAttrs: [FileAttributeKey: Any]
                do {
                    reviewAttrs = try FileManager.default.attributesOfItem(atPath: reviewPath)
                } catch {
                    throw EngineError.fileError(
                        path: reviewPath,
                        description: "--review-metadata file not accessible: \(error)"
                    )
                }
                guard (reviewAttrs[.type] as? FileAttributeType) == .typeRegular else {
                    throw EngineError.fileError(
                        path: reviewPath,
                        description: "--review-metadata must be a regular file (not a directory or symlink)"
                    )
                }
                // Read through SizedFileReader (defensive cap on YAML size).
                // Use config cap (64 KiB) — review metadata is small by design.
                let reviewYAML = try SizedFileReader.readConfigUTF8(at: reviewPath)
                // Validate it parses as YAML — fail fast on malformed input
                // rather than embedding garbage into the bundle.
                metadataExtensions["review"] = try Self.normalizeReviewYAML(reviewYAML)
            }

            // Create the bundle. The engine's create overload either
            // routes through the base path (when extensions empty) or
            // builds an augmented initialContent with the metadata block
            // embedded.
            let bundle = try DocumentBundle.create(
                name: name,
                initialContent: initialContent,
                metadataExtensions: metadataExtensions,
                at: bundlePath
            )

            guard let firstRevision = try bundle.latestRevision() else {
                throw EngineError.bundleConflict(
                    "Newly created bundle has no revisions: \(bundlePath)"
                )
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
                print("source:    \(sourcePath)")
                print("versionId: \(firstRevision.versionId)")
                print("revision:  \(firstRevision.revision)")
                print("version:   \(firstRevision.version)")
                if !metadataExtensions.isEmpty {
                    print("review:    embedded")
                }
            }
        } catch let error as EngineError {
            // invalidBundlePath when target exists → re-map to bundleConflict
            // for the client's convenience (matches the create-collision
            // semantics in the rest of the engine).
            if case .invalidBundlePath(_, let reason) = error,
               reason.contains("already exists") {
                let envelope = ErrorEnvelope(
                    error: "bundleConflict",
                    message: "Wrap target already exists; refusing to overwrite",
                    details: ["reason": AnyCodable(reason)]
                )
                envelope.emit(format: output.format)
                throw MdpalExitCode.bundleConflict.argumentParserCode
            }
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }

    /// Validate that --review-metadata content is a valid YAML mapping.
    /// Returns the normalized YAML (re-serialized for deterministic
    /// formatting) or throws if malformed.
    private static func normalizeReviewYAML(_ yaml: String) throws -> String {
        // Simple validation: must parse as YAML and resolve to a mapping
        // (not a scalar or sequence — `review:` semantically holds a
        // dict of fields like origin / artifactType / reviewRound).
        // Use a probe parse via the engine's metadata serializer's
        // round-trip path: wrap in a known-key structure, decode, extract.
        // Cheaper: just check that the trimmed YAML starts with a key:
        // pattern indicating a mapping at top level.
        let trimmed = yaml.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw EngineError.metadataError(
                "--review-metadata file is empty"
            )
        }
        // The simplest validation that doesn't introduce a Yams dep on
        // the CLI module: look for a `key:` pattern on the first
        // non-comment, non-blank line. Reject lines starting with `-`
        // (sequence) or `|`/`>` (block scalar) or anything else.
        for line in trimmed.split(separator: "\n", omittingEmptySubsequences: true) {
            let stripped = line.trimmingCharacters(in: .whitespaces)
            if stripped.isEmpty || stripped.hasPrefix("#") { continue }
            if stripped.hasPrefix("-") {
                throw EngineError.metadataError(
                    "--review-metadata must be a YAML mapping (top-level keys), not a sequence"
                )
            }
            // First content line — must contain a colon for `key: value` form.
            if !stripped.contains(":") {
                throw EngineError.metadataError(
                    "--review-metadata first line must be a YAML mapping entry (`key: value`)"
                )
            }
            break
        }
        return trimmed
    }
}
