// What Problem: When a section is edited, any unresolved comments
// anchored to it carry the old versionHash and become "stale". `mdpal
// refresh <slug> <bundle>` updates each stale comment's versionHash to
// the section's current hash so the app's "stale comment" badge clears.
// The original comment context is preserved as historical record.
//
// How & Why: Resolve bundle, fetch latest document, call
// `document.refreshSection(slug)` (engine returns the list of comments
// it actually updated — only those whose hash differed). Persist the
// updated metadata as a new revision (append-only), then emit the
// section's current versionHash, the count of refreshed comments, and
// the new revision's versionId per the dispatched spec.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct RefreshCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "refresh",
        abstract: "Refresh stale comment versionHashes on a section.",
        discussion: """
            Updates each unresolved comment anchored to <slug> so its
            versionHash matches the section's current hash. Resolved
            comments are NOT touched (they are frozen at resolution).
            Original comment context is preserved.

            A new revision is written even if no comments needed
            refreshing — call `mdpal history` to confirm.
            """
    )

    @Argument(help: "Section slug to refresh (e.g., 'introduction' or 'authentication/oauth').")
    var slug: String

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @Option(name: .long, help: "Required base revision id. Reject the refresh if the bundle has moved past this id (optimistic concurrency).")
    var baseRevision: String?

    @OptionGroup var output: GlobalOutputOptions

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            let document = try resolvedBundle.currentDocument()

            let refreshed = try document.refreshSection(slug)
            let section = try document.readSection(slug)

            // F1 fix: when refreshSection updated nothing, skip the
            // createRevision call — otherwise a same-minute retry hits
            // the engine's same-minute revision-collision guard and
            // surfaces a confusing bundleConflict for what was actually
            // a no-op. The wire payload still echoes the bundle's
            // current latest versionId so callers always have one.
            if refreshed.isEmpty {
                guard let latest = try resolvedBundle.latestRevision() else {
                    throw EngineError.bundleConflict("Bundle has no revisions: \(resolvedBundle.path)")
                }
                emit(
                    section: section,
                    refreshedCount: 0,
                    versionId: latest.versionId
                )
                return
            }

            // Persist the updated metadata as a new revision. expectedBase
            // (D3 fix) lets the caller catch a concurrent writer that
            // landed between our currentDocument() read and this write.
            let serialized = try document.serialize()
            let newRevision = try resolvedBundle.createRevision(
                content: serialized,
                expectedBase: baseRevision
            )

            emit(
                section: section,
                refreshedCount: refreshed.count,
                versionId: newRevision.versionId
            )
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }

    private func emit(section: Section, refreshedCount: Int, versionId: String) {
        switch output.format {
        case .json:
            let payload = RefreshPayload(
                slug: section.slug,
                versionHash: section.versionHash,
                commentsUpdated: refreshedCount,
                versionId: versionId
            )
            try? JSONOutput.print(payload)
        case .text:
            print("slug:            \(section.slug)")
            print("versionHash:     \(section.versionHash)")
            print("commentsUpdated: \(refreshedCount)")
            print("versionId:       \(versionId)")
        }
    }
}

/// Wire shape for `mdpal refresh` per the dispatched spec.
struct RefreshPayload: Encodable {
    let slug: String
    let versionHash: String
    let commentsUpdated: Int
    let versionId: String
}
