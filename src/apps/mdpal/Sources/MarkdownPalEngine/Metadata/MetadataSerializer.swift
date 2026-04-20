// What Problem: DocumentMetadata needs to round-trip through YAML in the
// document metadata block. Yams handles the YAML primitive translation, but
// the engine needs an explicit schema mapping between the in-memory types
// and the YAML structure (which uses snake_case keys, splits comments into
// `unresolved`/`resolved` lists, and uses ISO8601 timestamps).
//
// How & Why: We use Yams' Node API directly so we control key ordering. YAML
// in version-controlled markdown must produce deterministic output — every
// `Document.serialize` call on identical metadata must yield byte-identical
// YAML, otherwise saves create noisy diffs and tests become flaky. We also
// own the schema explicitly: snake_case keys, comment list membership
// (resolved vs unresolved) determines which list a comment belongs to (NOT
// presence of a `response` field), and required fields are validated with
// specific error messages.
//
// Date formatters use the en_US_POSIX locale and Gregorian calendar so
// non-default user locales (Thai Buddhist, Japanese Imperial) don't corrupt
// timestamps. Numeric fields tolerate Int / Int64 / NSNumber to survive
// Yams' platform-dependent integer parsing.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

import Foundation
import Yams

/// Serializes and deserializes DocumentMetadata to/from YAML.
///
/// The YAML schema:
/// ```yaml
/// document:
///   version_id: "V0001.0001.20260407T1234Z"
///   version: 1
///   revision: 1
///   timestamp: 2026-04-07T12:34:00Z
///   created: 2026-04-07T12:34:00Z
///   authors: [jordan, claude]
/// flags:
///   - section: authentication
///     note: "Discuss OAuth flow choice"
///     author: jordan
///     timestamp: 2026-04-07T14:00:00Z
/// unresolved:
///   - id: c001
///     type: question
///     ...
/// resolved:
///   - id: c002
///     type: suggestion
///     ...
///     response: "..."
///     resolved_date: 2026-04-07T12:00:00Z
///     resolved_by: jordan
/// ```
public enum MetadataSerializer {

    // MARK: - Encode

    /// Top-level YAML keys the engine knows how to interpret.
    /// Anything outside this set is captured into
    /// `DocumentMetadata.unknownTopLevelYAML` on decode and re-emitted
    /// verbatim on encode (Phase 3 iter 3.1 — round-trip preservation
    /// for additive metadata like mdpal-app's `review:` block).
    private static let knownTopLevelKeys: Set<String> = [
        "document", "flags", "unresolved", "resolved",
    ]

    /// Encode DocumentMetadata as a deterministic YAML string.
    public static func encode(_ metadata: DocumentMetadata) throws -> String {
        // Use an ordered Node mapping so key order is stable across runs.
        var topLevel: [(Node, Node)] = []
        topLevel.append((Node("document"), encodeDocumentInfo(metadata.document)))
        if !metadata.flags.isEmpty {
            topLevel.append((Node("flags"), Node(metadata.flags.map { encodeFlag($0) })))
        }
        if !metadata.unresolvedComments.isEmpty {
            topLevel.append((
                Node("unresolved"),
                Node(metadata.unresolvedComments.map { encodeComment($0) })
            ))
        }
        if !metadata.resolvedComments.isEmpty {
            topLevel.append((
                Node("resolved"),
                Node(metadata.resolvedComments.map { encodeComment($0) })
            ))
        }
        // Phase 3 iter 3.1: re-emit unknown top-level keys captured at
        // decode time. Sort by key for deterministic output. Each value
        // is a YAML-serialized subtree captured verbatim from the source.
        for key in metadata.unknownTopLevelYAML.keys.sorted() {
            let serializedSubtree = metadata.unknownTopLevelYAML[key]!
            // Re-parse the captured YAML into a Node so it nests as a
            // proper mapping/scalar/sequence under the top-level key.
            // (Storing as raw String would force us to splice text with
            // the right indentation; a Node round-trip via Yams is
            // safer and preserves the original structure.)
            do {
                guard let node = try Yams.compose(yaml: serializedSubtree) else {
                    // Malformed captured subtree — skip rather than
                    // corrupt the whole metadata block. This shouldn't
                    // happen in practice (we serialized it ourselves on
                    // decode) but we defend against it anyway.
                    continue
                }
                topLevel.append((Node(key), node))
            } catch {
                throw EngineError.metadataError(
                    "Failed to re-emit unknown YAML key '\(key)': \(error)"
                )
            }
        }
        let root = Node.mapping(orderedMapping(topLevel))

        do {
            return try Yams.serialize(node: root)
        } catch {
            throw EngineError.metadataError("YAML encode failed: \(error)")
        }
    }

    private static func encodeDocumentInfo(_ info: DocumentInfo) -> Node {
        let pairs: [(Node, Node)] = [
            (Node("version_id"), Node(info.versionId)),
            (Node("version"), Node(String(info.version), Tag(.int))),
            (Node("revision"), Node(String(info.revision), Tag(.int))),
            (Node("timestamp"), Node(formatISODate(info.timestamp))),
            (Node("created"), Node(formatISODate(info.created))),
            (Node("authors"), Node(info.authors.map { Node($0) })),
        ]
        return Node.mapping(orderedMapping(pairs))
    }

    private static func encodeFlag(_ flag: Flag) -> Node {
        var pairs: [(Node, Node)] = [
            (Node("section"), Node(flag.sectionSlug)),
        ]
        if let note = flag.note {
            pairs.append((Node("note"), Node(note)))
        }
        pairs.append((Node("author"), Node(flag.author)))
        pairs.append((Node("timestamp"), Node(formatISODate(flag.timestamp))))
        return Node.mapping(orderedMapping(pairs))
    }

    private static func encodeComment(_ comment: Comment) -> Node {
        var pairs: [(Node, Node)] = [
            (Node("id"), Node(comment.id)),
            (Node("type"), Node(comment.type.rawValue)),
            (Node("author"), Node(comment.author)),
            (Node("section"), Node(comment.sectionSlug)),
            (Node("version_hash"), Node(comment.versionHash)),
            (Node("timestamp"), Node(formatISODate(comment.timestamp))),
            (Node("context"), Node(comment.context)),
            (Node("text"), Node(comment.text)),
        ]
        if comment.priority != .normal {
            pairs.append((Node("priority"), Node(comment.priority.rawValue)))
        }
        if !comment.tags.isEmpty {
            pairs.append((Node("tags"), Node(comment.tags.map { Node($0) })))
        }
        if let resolution = comment.resolution {
            pairs.append((Node("response"), Node(resolution.response)))
            pairs.append((Node("resolved_date"), Node(formatISODate(resolution.resolvedDate))))
            pairs.append((Node("resolved_by"), Node(resolution.resolvedBy)))
        }
        return Node.mapping(orderedMapping(pairs))
    }

    /// Build an ordered Yams mapping from key-value pairs.
    /// Yams' Node.Mapping preserves the order of the pairs array, giving us
    /// deterministic key order in serialized YAML.
    private static func orderedMapping(_ pairs: [(Node, Node)]) -> Node.Mapping {
        Node.Mapping(pairs)
    }

    // MARK: - Decode

    /// Decode DocumentMetadata from a YAML string.
    public static func decode(_ yaml: String) throws -> DocumentMetadata {
        let parsed: Any?
        do {
            parsed = try Yams.load(yaml: yaml)
        } catch {
            throw EngineError.metadataError("YAML parse failed: \(error)")
        }
        guard let dict = parsed as? [String: Any] else {
            throw EngineError.metadataError("Metadata YAML root must be a mapping")
        }

        let document = try decodeDocumentInfo(dict["document"])

        let flags: [Flag]
        if let raw = dict["flags"] as? [Any] {
            flags = try raw.map { try decodeFlag($0) }
        } else {
            flags = []
        }

        // List membership determines resolution state. A comment in the
        // `unresolved` list never gets a resolution attached, even if its
        // YAML mapping contains a stray `response` field. A comment in the
        // `resolved` list MUST have a `response` field.
        let unresolved: [Comment]
        if let raw = dict["unresolved"] as? [Any] {
            unresolved = try raw.map { try decodeComment($0, requireResolution: false) }
        } else {
            unresolved = []
        }

        let resolved: [Comment]
        if let raw = dict["resolved"] as? [Any] {
            resolved = try raw.map { try decodeComment($0, requireResolution: true) }
        } else {
            resolved = []
        }

        // Phase 3 iter 3.1: capture unknown top-level keys for
        // round-trip preservation. Re-parse the same YAML via Yams.compose
        // so we get Node objects for each unknown key (Yams.load returns
        // generic Any which can't be cleanly re-serialized to YAML
        // preserving types). Each captured subtree is serialized back to
        // YAML for storage on DocumentMetadata; encode re-parses and
        // emits as a proper nested mapping.
        var unknownTopLevelYAML: [String: String] = [:]
        let composed: Node?
        do {
            composed = try Yams.compose(yaml: yaml)
        } catch {
            // Compose failed but load succeeded — extremely unlikely
            // (same parser). Fall back to no preservation rather than
            // erroring; the decode still succeeds with known fields.
            composed = nil
        }
        if let mapping = composed?.mapping {
            for (k, v) in mapping {
                guard let key = k.string else { continue }
                if knownTopLevelKeys.contains(key) { continue }
                do {
                    let subtreeYAML = try Yams.serialize(node: v)
                    unknownTopLevelYAML[key] = subtreeYAML
                } catch {
                    continue
                }
            }
        }

        return DocumentMetadata(
            document: document,
            unresolvedComments: unresolved,
            resolvedComments: resolved,
            flags: flags,
            unknownTopLevelYAML: unknownTopLevelYAML
        )
    }

    private static func decodeDocumentInfo(_ raw: Any?) throws -> DocumentInfo {
        guard let dict = raw as? [String: Any] else {
            throw EngineError.metadataError("`document` is required and must be a mapping")
        }
        guard let versionId = dict["version_id"] as? String else {
            throw EngineError.metadataError("`document.version_id` is required")
        }
        guard let version = parseInt(dict["version"]) else {
            throw EngineError.metadataError("`document.version` is required and must be an integer")
        }
        guard let revision = parseInt(dict["revision"]) else {
            throw EngineError.metadataError("`document.revision` is required and must be an integer")
        }
        let timestamp = try parseDate(dict["timestamp"], field: "document.timestamp")
        let created = try parseDate(dict["created"], field: "document.created")
        let authors = (dict["authors"] as? [String]) ?? []
        return DocumentInfo(
            versionId: versionId,
            version: version,
            revision: revision,
            timestamp: timestamp,
            created: created,
            authors: authors
        )
    }

    private static func decodeFlag(_ raw: Any) throws -> Flag {
        guard let dict = raw as? [String: Any] else {
            throw EngineError.metadataError("flag entry must be a mapping")
        }
        guard let section = dict["section"] as? String else {
            throw EngineError.metadataError("flag.section is required")
        }
        guard let author = dict["author"] as? String else {
            throw EngineError.metadataError("flag.author is required")
        }
        let timestamp = try parseDate(dict["timestamp"], field: "flag.timestamp")
        let note = dict["note"] as? String
        return Flag(sectionSlug: section, note: note, author: author, timestamp: timestamp)
    }

    private static func decodeComment(_ raw: Any, requireResolution: Bool) throws -> Comment {
        guard let dict = raw as? [String: Any] else {
            throw EngineError.metadataError("comment entry must be a mapping")
        }
        guard let id = dict["id"] as? String else {
            throw EngineError.metadataError("comment.id is required")
        }
        guard let typeRaw = dict["type"] as? String else {
            throw EngineError.metadataError("comment.type is required")
        }
        guard let type = CommentType(rawValue: typeRaw) else {
            throw EngineError.metadataError("comment.type \"\(typeRaw)\" is not a known CommentType")
        }
        guard let author = dict["author"] as? String else {
            throw EngineError.metadataError("comment.author is required")
        }
        guard let section = dict["section"] as? String else {
            throw EngineError.metadataError("comment.section is required")
        }
        guard let versionHash = dict["version_hash"] as? String else {
            throw EngineError.metadataError("comment.version_hash is required")
        }
        let timestamp = try parseDate(dict["timestamp"], field: "comment.timestamp")
        let context = (dict["context"] as? String) ?? ""
        guard let text = dict["text"] as? String else {
            throw EngineError.metadataError("comment.text is required")
        }
        let priority: Priority
        if let priorityRaw = dict["priority"] as? String {
            guard let parsed = Priority(rawValue: priorityRaw) else {
                throw EngineError.metadataError("comment.priority \"\(priorityRaw)\" is not a known Priority")
            }
            priority = parsed
        } else {
            priority = .normal
        }
        let tags = (dict["tags"] as? [String]) ?? []

        let resolution: Resolution?
        if requireResolution {
            guard let response = dict["response"] as? String else {
                throw EngineError.metadataError("resolved comment \(id) is missing `response` field")
            }
            let resolvedDate = try parseDate(dict["resolved_date"], field: "comment.resolved_date")
            guard let resolvedBy = dict["resolved_by"] as? String else {
                throw EngineError.metadataError("resolved comment \(id) is missing `resolved_by` field")
            }
            resolution = Resolution(
                response: response,
                resolvedDate: resolvedDate,
                resolvedBy: resolvedBy
            )
        } else {
            // Unresolved list — ignore any stray resolution fields entirely.
            resolution = nil
        }

        return Comment(
            id: id,
            type: type,
            author: author,
            sectionSlug: section,
            versionHash: versionHash,
            timestamp: timestamp,
            context: context,
            text: text,
            resolution: resolution,
            priority: priority,
            tags: tags
        )
    }

    // MARK: - Numeric helpers

    /// Parse an integer from a Yams-decoded value, accepting Int, Int64,
    /// UInt, NSNumber, and stringified integers.
    private static func parseInt(_ raw: Any?) -> Int? {
        if let i = raw as? Int { return i }
        if let i = raw as? Int64 { return Int(i) }
        if let u = raw as? UInt { return Int(u) }
        if let n = raw as? NSNumber { return n.intValue }
        if let s = raw as? String { return Int(s) }
        return nil
    }

    // MARK: - Date helpers

    /// Build a fresh ISO8601 formatter on each call.
    /// Foundation's date formatters are not Sendable, so we cannot share a
    /// static instance under Swift 6 strict concurrency. The cost of
    /// constructing a formatter is negligible relative to YAML I/O.
    private static func makeISOFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    private static func makeDateOnlyFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }

    /// Format a Date as an ISO8601 datetime string for YAML output.
    static func formatISODate(_ date: Date) -> String {
        makeISOFormatter().string(from: date)
    }

    private static func parseDate(_ raw: Any?, field: String) throws -> Date {
        if let date = raw as? Date {
            return date
        }
        if let string = raw as? String {
            if let date = makeISOFormatter().date(from: string) {
                return date
            }
            if let date = makeDateOnlyFormatter().date(from: string) {
                return date
            }
            throw EngineError.metadataError("\(field) is not a valid date: \(string)")
        }
        throw EngineError.metadataError("\(field) is required")
    }
}
