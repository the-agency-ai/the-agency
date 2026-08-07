// What Problem: ImageBlockView called NSImage(contentsOf:) directly inside its
// `body`. SwiftUI evaluates `body` on every slide change, window resize, theme
// change and live-reload tick, so a deck's images were re-read from disk and
// re-decoded continuously on the main thread. PDF export re-renders every slide
// and multiplied the cost.
//
// How & Why: A process-wide NSCache keyed by resolved path plus the file's
// modification date. NSCache is thread-safe and evicts under memory pressure on
// its own, so no manual budget is needed. Including the modification date in the
// key means the live-reload path picks up an edited image automatically — a
// changed file simply misses the cache — without any explicit invalidation call.
//
// Written: 2026-08-07 during mdslidepal-mac PR-prep QG — addresses repeated
// synchronous disk I/O and image decoding in a SwiftUI view body.

import AppKit
import Foundation

/// Caches decoded local images so a given file is read and decoded once.
enum LocalImageCache {

    private static let cache = NSCache<NSString, NSImage>()

    /// Load the image at `url`, returning a cached copy when the file has not
    /// changed since it was last decoded. Returns nil if the file is missing or
    /// is not decodable as an image.
    static func image(at url: URL) -> NSImage? {
        let key = cacheKey(for: url) as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let image = NSImage(contentsOf: url) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    /// Key combining the file path with its modification date, so an edited
    /// file misses the cache and is re-read on the next render.
    private static func cacheKey(for url: URL) -> String {
        let modified = (try? FileManager.default.attributesOfItem(atPath: url.path))
            .flatMap { $0[.modificationDate] as? Date }
            .map { String($0.timeIntervalSince1970) }
            ?? "unknown"
        return "\(url.path)|\(modified)"
    }
}
