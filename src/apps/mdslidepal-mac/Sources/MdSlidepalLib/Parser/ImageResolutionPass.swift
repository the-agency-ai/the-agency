// What Problem: Contract §11 requires a **warning** for a missing local image
// (line 295) and for an asset path escaping the source directory (line 300).
// The renderer drew the placeholder box for both and produced no Diagnostic:
// ImageBlockView lives inside a SwiftUI `body`, which has no channel back to the
// document's diagnostics array, and mutating observable state from a body is not
// a channel we want. So the deck rendered with a grey box and the diagnostics
// banner stayed empty — the author was never told which path was wrong.
//
// How & Why: Resolve every image once, at load time, where the document is a
// value we can append to. This runs after DeckParser has produced the slides and
// after the source URL is known (a relative path cannot be resolved without it),
// which is DeckState.load. Failure reasons come from ImagePathResolver's
// `ImageResolution`, so a refusal and a typo produce different messages.
//
// The pass deliberately does NOT touch remote URLs: probing them means network
// I/O at load time, and the deck must open instantly and offline. Contract line
// 296's "unreachable remote URL" warning belongs to the loader that actually
// attempts the fetch — see RemoteImageLoader.
//
// Written: 2026-08-12 during mdslidepal-mac PR-prep QG wave 4.

import Foundation
import Markdown

/// Resolves every image in a deck once, at load time, and reports the failures
/// as contract §11 diagnostics.
public enum ImageResolutionPass {

    /// Diagnostics for every unresolvable image in `document`.
    ///
    /// Returns an empty array when the document has no source URL: an unsaved or
    /// synthesised deck (the welcome deck, a string passed to `load(from:)`) has
    /// no directory to resolve relative paths against, and warning about every
    /// image in it would be noise about the deck's provenance, not its content.
    public static func diagnostics(for document: DeckDocument) -> [Diagnostic] {
        guard let sourceURL = document.sourceURL else { return [] }

        var diagnostics: [Diagnostic] = []
        var reported: Set<String> = []

        for slide in document.slides {
            for image in slide.markupChildren.flatMap({ images(in: $0) }) {
                let source = image.source ?? ""
                // The same asset referenced twice on one slide is one problem.
                guard reported.insert("\(slide.id)|\(source)").inserted else { continue }

                guard let message = failure(
                    for: source, relativeTo: sourceURL, alt: image.plainText
                ) else { continue }

                diagnostics.append(
                    Diagnostic(severity: .warning, message: message, slideIndex: slide.id)
                )
            }
        }
        return diagnostics
    }

    /// `document` with the image diagnostics appended.
    public static func applied(to document: DeckDocument) -> DeckDocument {
        var copy = document
        copy.diagnostics.append(contentsOf: diagnostics(for: document))
        return copy
    }

    /// The §11 warning text for one image source, or nil when it is fine.
    ///
    /// Kept separate from the walk so the message wording is testable on its own
    /// and the two failure classes cannot drift into the same sentence.
    public static func failure(
        for source: String, relativeTo sourceURL: URL, alt: String
    ) -> String? {
        switch ImagePathResolver.resolution(for: source, relativeTo: sourceURL) {
        case .remote:
            // Not probed here — see the file header.
            return nil

        case .local(let url):
            guard !FileManager.default.fileExists(atPath: url.path) else { return nil }
            return "Missing image: \(source)\(altSuffix(alt))"

        case .outsideDeck:
            // Contract §11 line 300. The refused path is deliberately reported as
            // the deck author wrote it rather than as the absolute path it
            // resolved to — the absolute form leaks where the deck lives into a
            // banner that may be on a projector.
            return "Image refused — path is outside the deck directory: \(source)"

        case .emptySource:
            return "Image has no source path\(altSuffix(alt))"

        case .noBaseDirectory:
            // Unreachable while `diagnostics(for:)` guards on sourceURL, but this
            // function is public and the case must not fall through silently.
            return "Cannot resolve image \(source) — the deck has not been saved"
        }
    }

    private static func altSuffix(_ alt: String) -> String {
        alt.isEmpty ? "" : " (\(alt))"
    }

    /// Every image node reachable from a markup subtree — block-level images and
    /// inline references alike. A broken reference is broken either way.
    private static func images(in markup: Markup) -> [Markdown.Image] {
        var found: [Markdown.Image] = []
        if let image = markup as? Markdown.Image { found.append(image) }
        for child in markup.children {
            found.append(contentsOf: images(in: child))
        }
        return found
    }
}
