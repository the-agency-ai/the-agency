// What Problem: `mdpal history <bundle>` lists every revision in the
// bundle so mdpal-app can populate a "version history" picker and so
// agents can choose --base-revision for `mdpal revision create`. Per
// the dispatched spec, output is newest-first with `latest: true` on
// the most recent revision.
//
// How & Why: Resolve bundle, call `bundle.listRevisions()` (returns
// oldest→newest sorted), reverse to newest-first, mark the first entry
// as latest. The `currentVersion` field carries the version number of
// the latest revision so callers can detect a version bump without
// parsing the versionId.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import ArgumentParser
import Foundation
import MarkdownPalEngine

struct HistoryCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "history",
        abstract: "List all revisions in a bundle, newest first.",
        discussion: """
            Returns every revision sorted newest → oldest. The most recent
            revision (the one `latest.md` symlink points to) is marked
            with `latest: true`. The top-level `currentVersion` field
            carries the version number of the latest revision.
            """
    )

    @Argument(help: "Path to the .mdpal bundle directory.")
    var bundle: String

    @OptionGroup var output: GlobalOutputOptions

    func run() throws {
        do {
            let resolvedBundle = try BundleResolver.resolve(self.bundle)
            // listRevisions returns oldest→newest; reverse for newest-first.
            let revisions = try resolvedBundle.listRevisions().reversed()
            let revisionList = Array(revisions)
            // F5 fix: emit currentVersion as explicit null on empty bundle
            // rather than fabricating 0 (not a valid version number).
            let currentVersion: Int? = revisionList.first?.version

            switch output.format {
            case .json:
                let entries = revisionList.enumerated().map { index, info in
                    HistoryRevisionPayload(
                        versionId: info.versionId,
                        version: info.version,
                        revision: info.revision,
                        timestamp: info.timestamp,
                        filePath: (info.filePath as NSString).lastPathComponent,
                        latest: index == 0
                    )
                }
                let payload = HistoryPayload(
                    revisions: entries,
                    count: entries.count,
                    currentVersion: currentVersion
                )
                try JSONOutput.print(payload)
            case .text:
                if revisionList.isEmpty {
                    print("(no revisions)")
                } else {
                    for (index, info) in revisionList.enumerated() {
                        let marker = index == 0 ? " (latest)" : ""
                        print("\(info.versionId)\(marker)")
                    }
                }
            }
        } catch let error as EngineError {
            let (envelope, exit) = EngineErrorMapper.envelope(for: error)
            envelope.emit(format: output.format)
            throw exit.argumentParserCode
        }
    }
}

/// Wire shape for `mdpal history` per the dispatched spec.
///
/// `currentVersion` is nullable: an empty bundle has no current version
/// and we emit explicit JSON `null` rather than fabricate `0` (custom
/// `encode(to:)` is required because synthesized Encodable would omit
/// the key entirely on nil — and the wire spec calls for the field
/// always being present).
struct HistoryPayload: Encodable {
    let revisions: [HistoryRevisionPayload]
    let count: Int
    let currentVersion: Int?

    private enum CodingKeys: String, CodingKey {
        case revisions, count, currentVersion
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(revisions, forKey: .revisions)
        try c.encode(count, forKey: .count)
        if let currentVersion {
            try c.encode(currentVersion, forKey: .currentVersion)
        } else {
            try c.encodeNil(forKey: .currentVersion)
        }
    }
}

/// One row in the `revisions` array. `filePath` is the basename of the
/// revision file (e.g., "V0001.0003.20260406T0100Z.md"), not the full
/// absolute path — the spec uses relative-to-bundle paths for portability.
struct HistoryRevisionPayload: Encodable {
    let versionId: String
    let version: Int
    let revision: Int
    let timestamp: Date
    let filePath: String
    let latest: Bool
}
