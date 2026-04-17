// What Problem: A bundle has configuration that lives in `.mdpal/config.yaml`:
// the bundle name and the prune policy. The engine needs an in-memory type
// for this configuration that can round-trip through Yams.
//
// How & Why: Plain value struct, custom Yams encode/decode (NOT Codable
// auto-synthesis) for the same reasons as DocumentMetadata: snake_case
// keys, deterministic key order, and explicit error messages on missing
// or malformed fields.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.4)

import Foundation
import Yams

/// Bundle configuration stored in `.mdpal/config.yaml`.
public struct BundleConfig: Equatable, Sendable {

    /// Human-readable name of the bundle (e.g., "MarkdownPalDesign").
    public var name: String

    /// Prune policy.
    public var prune: PruneConfig

    public struct PruneConfig: Equatable, Sendable {
        /// Number of most-recent revisions to keep when pruning.
        public var keep: Int

        /// If true, the engine prunes automatically after each revision.
        public var auto: Bool

        public init(keep: Int, auto: Bool) {
            self.keep = keep
            self.auto = auto
        }
    }

    public init(name: String, prune: PruneConfig) {
        self.name = name
        self.prune = prune
    }

    /// Default configuration for a new bundle: keep 20, no auto-prune.
    public static func defaults(name: String) -> BundleConfig {
        BundleConfig(name: name, prune: PruneConfig(keep: 20, auto: false))
    }
}

// MARK: - YAML serialization

extension BundleConfig {

    /// Encode the config as deterministic YAML for `.mdpal/config.yaml`.
    public func toYAML() throws -> String {
        let pruneNode = Node.mapping(Node.Mapping([
            (Node("keep"), Node(String(prune.keep), Tag(.int))),
            (Node("auto"), Node(prune.auto ? "true" : "false", Tag(.bool))),
        ]))
        let root = Node.mapping(Node.Mapping([
            (Node("name"), Node(name)),
            (Node("prune"), pruneNode),
        ]))
        do {
            return try Yams.serialize(node: root)
        } catch {
            throw EngineError.metadataError("Bundle config encode failed: \(error)")
        }
    }

    /// Decode a config from YAML loaded from `.mdpal/config.yaml`.
    public static func fromYAML(_ yaml: String) throws -> BundleConfig {
        let parsed: Any?
        do {
            parsed = try Yams.load(yaml: yaml)
        } catch {
            throw EngineError.metadataError("Bundle config YAML parse failed: \(error)")
        }
        guard let dict = parsed as? [String: Any] else {
            throw EngineError.metadataError("Bundle config root must be a mapping")
        }
        guard let name = dict["name"] as? String else {
            throw EngineError.metadataError("Bundle config missing required field `name`")
        }
        guard let pruneDict = dict["prune"] as? [String: Any] else {
            throw EngineError.metadataError("Bundle config missing required field `prune`")
        }
        let keep: Int
        if let i = pruneDict["keep"] as? Int { keep = i }
        else if let i64 = pruneDict["keep"] as? Int64 { keep = Int(i64) }
        else if let s = pruneDict["keep"] as? String, let i = Int(s) { keep = i }
        else {
            throw EngineError.metadataError("Bundle config `prune.keep` is required and must be an integer")
        }
        // `auto` is optional. If absent, default to false. If present, it
        // must be a real boolean — no silent type coercion that hides
        // config bugs (e.g., `auto: "yes"` or `auto: 1`).
        let auto: Bool
        if pruneDict["auto"] == nil {
            auto = false
        } else if let b = pruneDict["auto"] as? Bool {
            auto = b
        } else {
            throw EngineError.metadataError(
                "Bundle config `prune.auto` must be a boolean (true/false) when present"
            )
        }
        guard keep > 0 else {
            throw EngineError.metadataError(
                "Bundle config `prune.keep` must be > 0 (got \(keep))"
            )
        }
        return BundleConfig(name: name, prune: PruneConfig(keep: keep, auto: auto))
    }
}
