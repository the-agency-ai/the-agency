// What Problem: `mdpal version show <bundle>` reports the current
// document version, and `mdpal version bump <bundle>` increments the
// version number (resetting revision to 1) — both are needed to manage
// the document-version namespace in the bundle. The root command's
// `--version` flag prints the TOOL version; this subcommand group
// targets DOCUMENT versions, per the dispatched spec.
//
// How & Why: VersionCommand is a parent command with two subcommands.
// `show` reads `bundle.latestRevision()`; `bump` calls
// `bundle.bumpVersion(content:)` which writes a new revision with
// version+1 and revision=1. The CLI needs the prior content to feed
// back into bump — we use `currentDocument().serialize()` so the body
// is preserved verbatim across the version boundary.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct VersionCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "version",
        abstract: "Show or bump the document version of a bundle.",
        discussion: """
            The bundle's document version (V0001, V0002, ...) is separate
            from the CLI tool version printed by `mdpal --version`. Use
            `version show` to read the current document version and
            `version bump` to start a new version line (resets the
            revision counter to 1).
            """,
        subcommands: [VersionShowCommand.self, VersionBumpCommand.self]
    )
}

// MARK: - version show

struct VersionShowCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Print the current document version of a bundle."
    )

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @OptionGroup var output: GlobalOutputOptions

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            guard let latest = try resolvedBundle.latestRevision() else {
                throw EngineError.bundleConflict("Bundle has no revisions: \(resolvedBundle.path)")
            }

            switch output.format {
            case .json:
                let payload = VersionShowPayload(
                    version: latest.version,
                    versionId: latest.versionId,
                    revision: latest.revision,
                    timestamp: latest.timestamp
                )
                try JSONOutput.print(payload)
            case .text:
                print("version:   \(latest.version)")
                print("versionId: \(latest.versionId)")
                print("revision:  \(latest.revision)")
                print("timestamp: \(latest.timestamp)")
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}

// MARK: - version bump

struct VersionBumpCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "bump",
        abstract: "Bump the document version of a bundle (resets revision to 1).",
        discussion: """
            Increments the bundle's document version by 1 and resets the
            revision counter to 1. The current latest revision's content
            is carried forward verbatim into the first revision of the
            new version.
            """
    )

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @OptionGroup var output: GlobalOutputOptions

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            guard let priorLatest = try resolvedBundle.latestRevision() else {
                throw EngineError.bundleConflict("Bundle has no revisions to bump: \(resolvedBundle.path)")
            }
            let priorVersion = priorLatest.version

            // F6 fix: carry the existing latest content forward BYTE-FOR-BYTE.
            // The previous implementation called document.serialize(), which
            // re-renders the body and metadata via the parser — silently
            // reformatting whitespace, list indentation, and YAML key
            // ordering. The append-only invariant (mirrors the prune-side
            // fix at DocumentBundle.swift) requires the new V0002.0001 file
            // to be byte-identical to the prior latest. The bundle helper
            // applies the engine's revision-size cap.
            let content = try resolvedBundle.rawRevisionContent(versionId: priorLatest.versionId)
            let newRevision = try resolvedBundle.bumpVersion(content: content)

            switch output.format {
            case .json:
                let payload = VersionBumpPayload(
                    previousVersion: priorVersion,
                    version: newRevision.version,
                    versionId: newRevision.versionId,
                    revision: newRevision.revision,
                    timestamp: newRevision.timestamp
                )
                try JSONOutput.print(payload)
            case .text:
                print("previousVersion: \(priorVersion)")
                print("version:         \(newRevision.version)")
                print("versionId:       \(newRevision.versionId)")
                print("revision:        \(newRevision.revision)")
                print("timestamp:       \(newRevision.timestamp)")
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}

// MARK: - Wire shapes

/// Wire shape for `mdpal version show` per the dispatched spec.
struct VersionShowPayload: Encodable {
    let version: Int
    let versionId: String
    let revision: Int
    let timestamp: Date
}

/// Wire shape for `mdpal version bump` per the dispatched spec.
/// `previousVersion` is the version this bundle was at before the bump.
struct VersionBumpPayload: Encodable {
    let previousVersion: Int
    let version: Int
    let versionId: String
    let revision: Int
    let timestamp: Date
}
