// What Problem: Iteration 1.4 introduces the `.mdpal` bundle directory —
// a versioned container holding revisions of a single document. The bundle
// is the unit the CLI operates on for any saved document. The engine needs
// a type that creates bundles, lists/reads/creates revisions, updates the
// dual `latest` mechanism (symlink + pointer file), and prunes old
// revisions while merging forward resolved comment history.
//
// Revisions are append-only EXCEPT for the metadata merge-forward step
// during pruning, which rewrites the latest revision's metadata block
// in place to absorb resolved comments from pruned revisions. This is
// the only mutation of an existing revision file the engine performs;
// see A&D §6.5 for the rationale.
//
// How & Why: DocumentBundle is named to avoid shadowing Foundation.Bundle.
// All filesystem operations live here so Document stays focused on parsing
// and section operations. Bundles use the dual-latest mechanism: a Unix
// symlink `latest.md` for CLI/agents and a plain-text pointer file
// `.mdpal/latest` for the app's FileWrapper. Both are updated atomically
// per createRevision call.
//
// Pruning is the most subtle operation: it walks pruned revisions, extracts
// resolved comments missing from the latest, appends them to the latest's
// metadata, and only THEN deletes the pruned files. A revision-gating
// check before the delete step protects against another writer racing in
// during the merge.
//
// Path validation: bundle paths must end in `.mdpal` and contain a
// `.mdpal/config.yaml` config file (note: bundle root is `Foo.mdpal`, and
// the config is at `Foo.mdpal/.mdpal/config.yaml` per the spec). Bundles
// reject unrecognized files in the directory to keep the layout clean.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.4)

import Foundation

/// Bundle management for `.mdpal` directories.
///
/// Operates on the bundle directory: creates revisions, updates the
/// `latest.md` symlink and `.mdpal/latest` pointer file, prunes old
/// revisions while merging forward resolved comment history.
public final class DocumentBundle {

    /// Absolute path to the bundle directory (e.g., `/path/to/Foo.mdpal`).
    public let path: String

    /// Parsed bundle configuration.
    public internal(set) var config: BundleConfig

    private let fileManager: FileManager

    // MARK: - Init

    /// Open an existing bundle at the given path.
    /// Throws if the path doesn't exist, isn't a bundle, or has a malformed config.
    public init(at path: String) throws {
        self.path = path
        self.fileManager = FileManager.default

        try Self.validateBundlePath(path, fileManager: fileManager)

        let configPath = Self.configPath(forBundle: path)
        // Capped read — bundle config is tiny by design; refuse to load
        // anything large enough to indicate corruption or tampering.
        let yaml = try SizedFileReader.readConfigUTF8(at: configPath)
        self.config = try BundleConfig.fromYAML(yaml)

        // Reconcile dual-latest if symlink and pointer file disagree.
        // The symlink is authoritative — if a crash interrupted updateLatest
        // between the symlink rename and the pointer file write, repair the
        // pointer file to match the symlink. (This must come AFTER config
        // load so we have a stable bundle to reconcile.)
        try Self.reconcileLatest(bundlePath: path, fileManager: fileManager)

        // C-2: reap orphan `.tmp.<uuid>` files. The link(2)-based atomic
        // create writes a temp file then hardlinks to the final path; if
        // the writer was killed between the temp write and the link, the
        // temp file leaks. Bundle open is the natural reaping seam — list
        // the bundle root, delete entries matching the temp pattern.
        try Self.reapOrphanTempFiles(bundlePath: path, fileManager: fileManager)
    }

    /// Create a new bundle directory with an initial revision.
    @discardableResult
    public static func create(
        name: String,
        initialContent: String,
        at directory: String,
        timestamp: Date = Date()
    ) throws -> DocumentBundle {
        let fileManager = FileManager.default

        // Validate that the target directory's parent exists and we have a
        // place to put the bundle. The bundle path is `directory`.
        guard directory.hasSuffix(".mdpal") else {
            throw EngineError.invalidBundlePath(
                path: directory,
                reason: "Bundle directory must end in .mdpal"
            )
        }
        if fileManager.fileExists(atPath: directory) {
            throw EngineError.invalidBundlePath(
                path: directory,
                reason: "Target path already exists"
            )
        }

        // Create the bundle root and the .mdpal config directory.
        do {
            try fileManager.createDirectory(
                atPath: directory,
                withIntermediateDirectories: false,
                attributes: nil
            )
            try fileManager.createDirectory(
                atPath: configDirPath(forBundle: directory),
                withIntermediateDirectories: false,
                attributes: nil
            )
        } catch {
            throw EngineError.fileError(path: directory, description: "\(error)")
        }

        // Write the config file.
        let config = BundleConfig.defaults(name: name)
        let configYAML = try config.toYAML()
        let configPath = configPath(forBundle: directory)
        do {
            try configYAML.write(toFile: configPath, atomically: true, encoding: .utf8)
        } catch {
            throw EngineError.fileError(path: configPath, description: "\(error)")
        }

        // Write the initial revision file.
        let versionId = VersionId.format(version: 1, revision: 1, timestamp: timestamp)
        let revisionFilename = "\(versionId).md"
        let revisionPath = "\(directory)/\(revisionFilename)"
        do {
            try initialContent.write(toFile: revisionPath, atomically: true, encoding: .utf8)
        } catch {
            throw EngineError.fileError(path: revisionPath, description: "\(error)")
        }

        // Update the dual latest mechanism (symlink + pointer file).
        try Self.updateLatest(bundlePath: directory, to: revisionFilename, fileManager: fileManager)

        return try DocumentBundle(at: directory)
    }

    // MARK: - Revision read

    /// Get the current (latest) revision as a Document.
    public func currentDocument() throws -> Document {
        guard let revision = try latestRevision() else {
            throw EngineError.bundleConflict("Bundle has no revisions: \(path)")
        }
        return try Document(contentsOfFile: revision.filePath)
    }

    /// Read a revision file's raw bytes through the engine's defensive
    /// size cap. Use this when verbatim content is required (e.g.,
    /// `version bump` carrying the prior latest forward without the
    /// re-serialize round-trip that would normalize body whitespace and
    /// metadata key order). Reads through `SizedFileReader.readRevisionUTF8`
    /// so the same cap applied to writes is applied to reads.
    public func rawRevisionContent(versionId: String) throws -> String {
        let revisions = try listRevisions()
        guard let info = revisions.first(where: { $0.versionId == versionId }) else {
            throw EngineError.bundleConflict("Revision not found in bundle: '\(versionId)'")
        }
        return try SizedFileReader.readRevisionUTF8(at: info.filePath)
    }

    /// Return the latest revision info, or nil if the bundle is empty.
    public func latestRevision() throws -> RevisionInfo? {
        let revisions = try listRevisions()
        return revisions.last
    }

    /// List all revisions in the bundle, sorted oldest → newest by version ID.
    ///
    /// Files in the bundle root that don't match the revision filename
    /// pattern `V{NNNN}.{NNNN}.{YYYYMMDD}T{HHMM}Z.md` are SILENTLY SKIPPED
    /// (not rejected). This is intentional: users may legitimately drop
    /// `README.md`, `.DS_Store`, editor swap files, or other artifacts in
    /// the bundle directory. The engine treats anything that doesn't parse
    /// as a revision as "not a revision" and ignores it. The `latest.md`
    /// symlink is also explicitly skipped.
    public func listRevisions() throws -> [RevisionInfo] {
        let entries: [String]
        do {
            entries = try fileManager.contentsOfDirectory(atPath: path)
        } catch {
            throw EngineError.fileError(path: path, description: "\(error)")
        }
        var revisions: [RevisionInfo] = []
        for entry in entries {
            // Only consider .md files at the bundle root, skip latest.md.
            guard entry.hasSuffix(".md") else { continue }
            guard entry != "latest.md" else { continue }

            // Security: reject symlinks. A malicious bundle (via git/tar/zip)
            // could ship a revision filename as a symlink to /etc/passwd or
            // ~/.ssh/id_rsa. Following it gives arbitrary read; pruning it
            // gives arbitrary deletion. Only regular files are valid revisions.
            let entryPath = "\(path)/\(entry)"
            do {
                let attrs = try fileManager.attributesOfItem(atPath: entryPath)
                guard (attrs[.type] as? FileAttributeType) == .typeRegular else { continue }
            } catch {
                // Can't stat — skip silently (same policy as non-revision files).
                continue
            }

            let stem = String(entry.dropLast(".md".count))
            // Silently skip non-revision .md files (README.md, etc.).
            // VersionId.parse rejects anything that doesn't match the
            // strict format, so this is the gate.
            guard let components = VersionId.parse(stem) else { continue }
            revisions.append(RevisionInfo(
                versionId: stem,
                version: components.version,
                revision: components.revision,
                timestamp: components.timestamp,
                filePath: "\(path)/\(entry)"
            ))
        }
        return revisions.sorted()
    }

    // MARK: - Revision write

    /// Create a new revision from modified content.
    /// Increments the revision number and updates both latest pointers.
    ///
    /// When `expectedBase` is supplied, the bundle's current latest revision
    /// must equal it exactly OR `EngineError.bundleConflict` is thrown
    /// BEFORE the new file is written. This closes the TOCTOU window
    /// between the caller's "I last saw revision X" check and this method's
    /// own latest-discovery in `listRevisions`. Pass nil (the default) to
    /// retain the existing append-anything semantics.
    @discardableResult
    public func createRevision(
        content: String,
        timestamp: Date = Date(),
        expectedBase: String? = nil
    ) throws -> RevisionInfo {
        let revisions = try listRevisions()

        // Optimistic concurrency: if the caller named the base they expect,
        // verify the bundle hasn't moved underneath them. Done INSIDE the
        // engine so the file-existence check at writeRevision time and the
        // base check share the same `revisions` snapshot.
        if let expectedBase {
            let currentBase = revisions.last?.versionId ?? ""
            if currentBase != expectedBase {
                throw EngineError.bundleBaseConflict(
                    expected: expectedBase,
                    actual: currentBase
                )
            }
        }

        let nextVersion: Int
        let nextRevision: Int
        if let latest = revisions.last {
            nextVersion = latest.version
            nextRevision = latest.revision + 1
        } else {
            nextVersion = 1
            nextRevision = 1
        }
        return try writeRevision(
            version: nextVersion,
            revision: nextRevision,
            content: content,
            timestamp: timestamp
        )
    }

    /// Bump the version number and reset the revision counter to 1.
    @discardableResult
    public func bumpVersion(content: String, timestamp: Date = Date()) throws -> RevisionInfo {
        let revisions = try listRevisions()
        let nextVersion = (revisions.last?.version ?? 0) + 1
        return try writeRevision(
            version: nextVersion,
            revision: 1,
            content: content,
            timestamp: timestamp
        )
    }

    private func writeRevision(
        version: Int,
        revision: Int,
        content: String,
        timestamp: Date
    ) throws -> RevisionInfo {
        let versionId = VersionId.format(version: version, revision: revision, timestamp: timestamp)
        let filename = "\(versionId).md"
        let revisionPath = "\(path)/\(filename)"

        // Atomic create-or-fail. The previous implementation used
        //   if fileExists(...) { throw }
        //   write(toFile:atomically:true)
        // which had two races: (1) TOCTOU between the fileExists check
        // and the write, (2) write(toFile:atomically:) uses temp+rename
        // and POSIX rename atomically REPLACES — so two concurrent
        // writers both produce successful renames, with last-rename-wins
        // silently overwriting the loser. The concurrent-CLI test caught
        // both processes succeeding with exit 0; bundle integrity broken.
        //
        // Fix: write content to a temp file in the same directory, then
        // use link(2) to atomically create the final name. link(2) is
        // POSIX-atomic and fails with EEXIST if the destination exists.
        // Same-minute collisions, multi-process races, and TOCTOU swaps
        // all produce a clean EEXIST → bundleConflict, with the loser's
        // temp file cleaned up by the defer.
        let tempPath = "\(revisionPath).tmp.\(UUID().uuidString)"
        do {
            try content.write(toFile: tempPath, atomically: false, encoding: .utf8)
        } catch {
            throw EngineError.fileError(path: tempPath, description: "\(error)")
        }
        defer { try? fileManager.removeItem(atPath: tempPath) }

        if link(tempPath, revisionPath) != 0 {
            let savedErrno = errno
            if savedErrno == EEXIST {
                throw EngineError.bundleConflict(
                    "Revision already exists: \(versionId). Wait until the next minute or pass a distinct timestamp."
                )
            }
            // C-16: distinguish resource exhaustion from generic I/O.
            // ENOSPC (no space) and EDQUOT (disk quota) are recoverable
            // by freeing space, not by retrying — surface as fileError
            // with explicit "disk full / quota exceeded" message so
            // callers can route appropriately. (We keep fileError as the
            // discriminator rather than adding a new case because the
            // recovery action — "free space" — is a user / system task,
            // not an engine retry.)
            let errStr = String(cString: strerror(savedErrno))
            let detail: String
            if savedErrno == ENOSPC {
                detail = "no space left on device (ENOSPC): \(errStr)"
            } else if savedErrno == EDQUOT {
                detail = "disk quota exceeded (EDQUOT): \(errStr)"
            } else {
                detail = "link(temp, final) failed: \(errStr)"
            }
            throw EngineError.fileError(
                path: revisionPath,
                description: detail
            )
        }

        try Self.updateLatest(bundlePath: path, to: filename, fileManager: fileManager)

        // Auto-prune if configured. Auto-prune failures are non-fatal but
        // are surfaced via stderr so the user/agent learns about silent
        // degradation rather than wondering why the bundle keeps growing.
        if config.prune.auto {
            do {
                _ = try prune(keep: config.prune.keep)
            } catch {
                FileHandle.standardError.write(
                    Data("mdpal: auto-prune failed: \(error)\n".utf8)
                )
            }
        }

        return RevisionInfo(
            versionId: versionId,
            version: version,
            revision: revision,
            timestamp: timestamp,
            filePath: revisionPath
        )
    }

    // MARK: - Configuration

    /// Update the bundle configuration on disk.
    public func updateConfig(_ newConfig: BundleConfig) throws {
        let configPath = Self.configPath(forBundle: path)
        let yaml = try newConfig.toYAML()
        do {
            try yaml.write(toFile: configPath, atomically: true, encoding: .utf8)
        } catch {
            throw EngineError.fileError(path: configPath, description: "\(error)")
        }
        self.config = newConfig
    }

    // MARK: - Pruning

    /// Prune old revisions, keeping the most recent N. Merges forward
    /// any resolved comments from pruned revisions into the latest revision
    /// so no comment history is lost.
    @discardableResult
    public func prune(keep: Int) throws -> PruneResult {
        guard keep > 0 else {
            throw EngineError.bundleConflict("prune.keep must be > 0; got \(keep)")
        }

        let revisions = try listRevisions()
        guard revisions.count > keep else {
            return PruneResult(
                prunedRevisions: [],
                mergedComments: 0,
                remainingRevisions: revisions.count
            )
        }

        // Capture the latest revision id BEFORE merging — used as the gate
        // to detect concurrent writers.
        guard let initialLatest = revisions.last else {
            return PruneResult(prunedRevisions: [], mergedComments: 0, remainingRevisions: 0)
        }

        // Split into kept (most recent N) and pruned (the rest).
        let keepCount = keep
        let pruned = Array(revisions.prefix(revisions.count - keepCount))
        let kept = Array(revisions.suffix(keepCount))
        guard let latest = kept.last else {
            return PruneResult(prunedRevisions: [], mergedComments: 0, remainingRevisions: kept.count)
        }

        // Load the latest as a Document so we can merge resolved comments
        // into its metadata.
        let latestDoc = try Document(contentsOfFile: latest.filePath)
        var latestResolvedById = Dictionary(
            uniqueKeysWithValues: latestDoc.metadata.resolvedComments.map { ($0.id, $0) }
        )

        var mergedCount = 0
        for prunedRevision in pruned {
            let prunedDoc: Document
            do {
                prunedDoc = try Document(contentsOfFile: prunedRevision.filePath)
            } catch {
                // If a pruned revision is corrupted, skip it but record
                // the failure in a future iteration. For now, surface as
                // a bundle conflict.
                throw EngineError.bundleConflict(
                    "Failed to load pruned revision \(prunedRevision.versionId): \(error)"
                )
            }
            for resolved in prunedDoc.metadata.resolvedComments {
                if latestResolvedById[resolved.id] == nil {
                    latestResolvedById[resolved.id] = resolved
                    mergedCount += 1
                }
            }
        }

        // Re-check the latest gate. If a writer added a new revision since
        // we started, abort.
        let postMergeRevisions = try listRevisions()
        guard let postMergeLatest = postMergeRevisions.last,
              postMergeLatest.versionId == initialLatest.versionId else {
            throw EngineError.bundleConflict(
                "Bundle was modified during prune; aborting"
            )
        }

        // Write ONLY the updated metadata block back to the latest revision
        // file, preserving the body content byte-for-byte. The previous
        // approach called `latestDoc.save()` which re-serializes the entire
        // document — reformatting body whitespace on every save. With
        // `prune.auto: true`, every save would silently rewrite supposedly-
        // immutable revision content, violating the append-only invariant.
        //
        // Fix: read the raw file, encode the updated metadata to YAML, and
        // splice it into the raw content via `writeMetadataBlock`.
        if mergedCount > 0 {
            // Order resolved comments by id for stable output.
            latestDoc.metadata.resolvedComments = latestResolvedById.values
                .sorted(by: { $0.id < $1.id })

            // Read the raw file content to preserve body verbatim. Capped
            // read for the same defense-in-depth reasons as Document(contentsOfFile:).
            let rawContent = try SizedFileReader.readRevisionUTF8(at: latest.filePath)

            // Encode the updated metadata and splice it into the raw content.
            let updatedYAML = try MetadataSerializer.encode(latestDoc.metadata)
            let parser = MarkdownParser()
            let updatedContent = parser.writeMetadataBlock(updatedYAML, into: rawContent)

            do {
                try updatedContent.write(toFile: latest.filePath, atomically: true, encoding: .utf8)
            } catch {
                throw EngineError.fileError(path: latest.filePath, description: "\(error)")
            }
        }

        // Delete pruned revision files. Failure to delete a single file
        // is not fatal — log it and continue. (For V1 we throw to surface
        // the issue; future iterations may add a "best effort" mode.)
        var prunedIds: [String] = []
        for prunedRevision in pruned {
            // Defense-in-depth: verify the file is still a regular file
            // before deletion. listRevisions already filters out symlinks,
            // but a TOCTOU race could replace a file between list and delete.
            do {
                let attrs = try fileManager.attributesOfItem(atPath: prunedRevision.filePath)
                guard (attrs[.type] as? FileAttributeType) == .typeRegular else {
                    throw EngineError.bundleConflict(
                        "Refusing to delete non-regular file during prune: \(prunedRevision.filePath)"
                    )
                }
            } catch let e as EngineError {
                throw e
            } catch {
                throw EngineError.fileError(
                    path: prunedRevision.filePath,
                    description: "Cannot verify file type before prune: \(error)"
                )
            }
            do {
                try fileManager.removeItem(atPath: prunedRevision.filePath)
                prunedIds.append(prunedRevision.versionId)
            } catch {
                throw EngineError.fileError(
                    path: prunedRevision.filePath,
                    description: "Failed to delete pruned revision: \(error)"
                )
            }
        }

        return PruneResult(
            prunedRevisions: prunedIds,
            mergedComments: mergedCount,
            remainingRevisions: kept.count
        )
    }

    // MARK: - Latest pointer management

    /// Update the dual latest mechanism atomically: write the symlink
    /// (replacing any existing one) and write the pointer file.
    private static func updateLatest(
        bundlePath: String,
        to revisionFilename: String,
        fileManager: FileManager
    ) throws {
        let symlinkPath = "\(bundlePath)/latest.md"

        // Atomic symlink replacement: create at a temp path then rename
        // over the existing one. `createSymbolicLink` fails if the target
        // exists, hence the temp + rename dance.
        let tempSymlink = "\(bundlePath)/.latest.md.\(UUID().uuidString)"
        do {
            try fileManager.createSymbolicLink(
                atPath: tempSymlink,
                withDestinationPath: revisionFilename
            )
        } catch {
            throw EngineError.fileError(path: tempSymlink, description: "\(error)")
        }
        do {
            // Use POSIX rename for atomic replacement. FileManager's
            // moveItem fails if the destination exists.
            if rename(tempSymlink, symlinkPath) != 0 {
                let errStr = String(cString: strerror(errno))
                try? fileManager.removeItem(atPath: tempSymlink)
                throw EngineError.fileError(
                    path: symlinkPath,
                    description: "rename(latest.md) failed: \(errStr)"
                )
            }
        } catch let e as EngineError {
            throw e
        } catch {
            throw EngineError.fileError(path: symlinkPath, description: "\(error)")
        }

        // Write the pointer file.
        let pointerPath = pointerPath(forBundle: bundlePath)
        do {
            try revisionFilename.write(toFile: pointerPath, atomically: true, encoding: .utf8)
        } catch {
            throw EngineError.fileError(path: pointerPath, description: "\(error)")
        }
    }

    /// Reap orphan `.tmp.<uuid>` files in the bundle root.
    ///
    /// The link(2)-based atomic create writes `<revision>.tmp.<UUID>`,
    /// then hardlinks it to the final revision name, then unlinks the
    /// temp. If the writer was killed between the temp write and the
    /// link, OR between the link and the unlink, the temp leaks. This
    /// reaper runs at bundle open and removes any matching files,
    /// preventing unbounded accumulation.
    ///
    /// Pattern: any `.md.tmp.*` filename in the bundle root. We scope to
    /// `.md.tmp.*` (not just `.tmp.*`) so we never delete an unrelated
    /// file a user might have placed in the bundle directory.
    ///
    /// Failures are silent: the reaper is best-effort. A locked or
    /// permission-denied removal doesn't block bundle open.
    private static func reapOrphanTempFiles(
        bundlePath: String,
        fileManager: FileManager
    ) throws {
        let entries: [String]
        do {
            entries = try fileManager.contentsOfDirectory(atPath: bundlePath)
        } catch {
            // Don't block bundle open on a directory-listing failure;
            // the rest of the engine will surface a clearer error if
            // the bundle is genuinely unreadable.
            return
        }
        for entry in entries where entry.contains(".md.tmp.") {
            try? fileManager.removeItem(atPath: "\(bundlePath)/\(entry)")
        }
    }

    /// Reconcile the dual-latest mechanism on bundle open.
    /// If the symlink and the pointer file disagree (e.g., from a crash
    /// between updates), the symlink wins and the pointer file is rewritten.
    private static func reconcileLatest(
        bundlePath: String,
        fileManager: FileManager
    ) throws {
        let symlinkPath = "\(bundlePath)/latest.md"
        guard fileManager.fileExists(atPath: symlinkPath) else { return }
        let symlinkDest: String
        do {
            symlinkDest = try fileManager.destinationOfSymbolicLink(atPath: symlinkPath)
        } catch {
            // Not a symlink (or unreadable) — skip reconciliation.
            return
        }
        let pointerPath = pointerPath(forBundle: bundlePath)
        // D-1 fix: route through SizedFileReader so a malicious or
        // corrupt pointer (multi-GB file) doesn't OOM the engine on
        // bundle open. We discard the read result on failure (still
        // tolerate missing/unreadable pointer for crash-recovery
        // resilience), but we no longer trust an unbounded read.
        let pointerContents = (try? SizedFileReader.readPointerUTF8(at: pointerPath))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if pointerContents != symlinkDest {
            try? symlinkDest.write(toFile: pointerPath, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Path helpers

    private static func validateBundlePath(_ path: String, fileManager: FileManager) throws {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
            throw EngineError.fileError(path: path, description: "Bundle path is not a directory")
        }
        guard path.hasSuffix(".mdpal") else {
            throw EngineError.invalidBundlePath(
                path: path,
                reason: "Bundle path must end in .mdpal"
            )
        }
        let configPath = Self.configPath(forBundle: path)
        guard fileManager.fileExists(atPath: configPath) else {
            throw EngineError.invalidBundlePath(
                path: path,
                reason: "Bundle missing config file: \(configPath)"
            )
        }
    }

    static func configDirPath(forBundle bundlePath: String) -> String {
        "\(bundlePath)/.mdpal"
    }

    static func configPath(forBundle bundlePath: String) -> String {
        "\(bundlePath)/.mdpal/config.yaml"
    }

    static func pointerPath(forBundle bundlePath: String) -> String {
        "\(bundlePath)/.mdpal/latest"
    }

    /// Read the pointer file (`.mdpal/latest`). Returns the filename of the
    /// current revision (e.g., `V0001.0003.20260404T1200Z.md`), or nil if
    /// the pointer file is missing.
    ///
    /// The contents are validated against the canonical revision-filename
    /// pattern (`V{NNNN}.{NNNN}.{YYYYMMDD}T{HHMM}Z.md`). A pointer file
    /// containing anything else — random text, a path traversal payload
    /// (`../../etc/passwd`), absolute path, multiple lines, etc. — is
    /// rejected as `EngineError.metadataError`. This blocks the
    /// "tampered pointer file" attack: a malicious or corrupt pointer
    /// would otherwise dictate which file `currentDocument()` reads (if
    /// callers ever route through the pointer rather than the symlink).
    public func readPointerFile() throws -> String? {
        let pointerPath = Self.pointerPath(forBundle: path)
        guard fileManager.fileExists(atPath: pointerPath) else { return nil }
        // C-6 fix: catch fileTooLarge and rewrap as metadataError. The
        // pointer file is part of the bundle metadata; mdpal-app expects
        // pointer corruption to surface as `metadataError`, not the
        // generic `fileTooLarge` discriminator.
        let contents: String
        do {
            contents = try SizedFileReader.readPointerUTF8(at: pointerPath)
        } catch let error as EngineError {
            if case .fileTooLarge(_, let sizeBytes, let limitBytes) = error {
                throw EngineError.metadataError(
                    "Pointer file at \(pointerPath) is \(sizeBytes) bytes, exceeds the \(limitBytes)-byte cap (likely corrupt or tampered)"
                )
            }
            throw error
        }
        let trimmed = contents.trimmingCharacters(in: .whitespacesAndNewlines)
        try Self.validatePointerContents(trimmed, pointerPath: pointerPath)
        return trimmed
    }

    /// Reject pointer files that don't look like a single canonical
    /// revision filename. Same regex shape as VersionId.parse + ".md".
    private static func validatePointerContents(
        _ contents: String,
        pointerPath: String
    ) throws {
        // Reject empty contents — pointer file should be missing entirely
        // if there's nothing to point at, not present-but-empty.
        if contents.isEmpty {
            throw EngineError.metadataError(
                "Pointer file is empty: \(pointerPath)"
            )
        }
        // Reject path separators and any traversal markers — the pointer
        // names a file in the bundle root, never a path.
        if contents.contains("/") || contents.contains("\\") || contents.contains("..") {
            throw EngineError.metadataError(
                "Pointer file contains path separator or traversal marker: \(pointerPath)"
            )
        }
        // C-12: explicit NUL / control character rejection. VersionId.parse
        // catches these implicitly via its strict-format gate, but a future
        // refactor that loosens parse should not silently accept embedded
        // NULs (which Foundation truncates) or other control chars.
        if contents.unicodeScalars.contains(where: { $0.value < 0x20 || $0.value == 0x7F }) {
            throw EngineError.metadataError(
                "Pointer file contains control characters: \(pointerPath)"
            )
        }
        // Reject anything not matching V{4}.{4}.{YYYYMMDD}T{HHMM}Z.md.
        // Full regex: V[0-9]{4}\.[0-9]{4}\.[0-9]{8}T[0-9]{4}Z\.md
        guard contents.hasSuffix(".md") else {
            throw EngineError.metadataError(
                "Pointer file does not name a .md revision: \(pointerPath)"
            )
        }
        let stem = String(contents.dropLast(3))
        guard VersionId.parse(stem) != nil else {
            throw EngineError.metadataError(
                "Pointer file does not name a canonical revision (V{4}.{4}.{YYYYMMDD}T{HHMM}Z.md): \(pointerPath)"
            )
        }
    }
}
