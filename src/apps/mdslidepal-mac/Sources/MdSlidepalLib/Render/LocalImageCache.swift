// What Problem: ImageBlockView called NSImage(contentsOf:) directly inside its
// `body`. SwiftUI evaluates `body` on every slide change, window resize, theme
// change and live-reload tick, so a deck's images were re-read from disk and
// re-decoded continuously on the main thread. PDF export re-renders every slide
// and multiplied the cost.
//
// How & Why: A process-wide NSCache keyed by resolved path plus the file's
// modification date. NSCache is thread-safe and evicts under memory pressure on
// its own. Including the modification date in the key means the live-reload path
// picks up an edited image automatically — a changed file simply misses the
// cache — without any explicit invalidation call.
//
// Every path here runs on the main thread inside a SwiftUI view body, and the
// image path itself comes from untrusted Markdown, so the load is budgeted twice
// before anything is decoded: once against the file's size on disk and once
// against the pixel count declared in the image header. A 30000x30000 PNG is
// about a megabyte on disk and 3.6 GB decoded; NSImage(contentsOf:) accepts it
// happily. ImageIO reports the declared dimensions from the header without
// decoding a single pixel, which is what makes the refusal cheap enough to do on
// every call.
//
// Written: 2026-08-07 during mdslidepal-mac PR-prep QG — addresses repeated
// synchronous disk I/O and image decoding in a SwiftUI view body.
// Updated: 2026-08-12 PR-prep QG — the "no manual budget is needed" claim
//   previously here was wrong: the mtime-bearing key mints a fresh entry on every
//   live-reload save, and an unbounded NSCache stored with no cost has neither a
//   count nor a reachable cost limit to evict against. Both limits are now set
//   and entries carry their decoded size. Made public so the cache is testable.
// Updated: 2026-08-12 PR-prep QG wave 2 — decompression-bomb budget: byte and
//   pixel ceilings enforced before any decode.
// Updated: 2026-08-12 PR-prep QG wave 4 — the decode no longer re-opens the file
//   by name after the path was containment-checked (a symlink swapped in between
//   was followed straight out of the deck). Bytes now come from
//   ImagePathResolver.readContained, which checks the descriptor it read through.

import AppKit
import Foundation
import ImageIO

/// Caches decoded local images so a given file is read and decoded once.
public enum LocalImageCache {

    // MARK: - Budget

    /// Ceilings a local image must sit under before it is decoded.
    ///
    /// Both limits exist because neither alone is sufficient: a highly
    /// compressible image is tiny on disk and enormous in memory, and a large
    /// file is expensive to read even when its dimensions are modest.
    public struct ImageBudget: Equatable {
        /// Largest file, in bytes, that is read at all.
        public var maxFileBytes: Int
        /// Largest pixel count (width x height) that is decoded.
        public var maxPixels: Int

        public init(maxFileBytes: Int, maxPixels: Int) {
            self.maxFileBytes = maxFileBytes
            self.maxPixels = maxPixels
        }

        /// 64 MB on disk, 64 megapixels decoded (~256 MB of bitmap).
        ///
        /// Slides are a 1920x1080 logical box, so 64 MP is roughly 30x more
        /// pixels than any slide can display — generous for a retina-sourced
        /// photograph, far below the 900 MP of a 30000x30000 bomb.
        public static let `default` = ImageBudget(
            maxFileBytes: 64 * 1024 * 1024,
            maxPixels: 64_000_000
        )
    }

    /// Why a load was refused. `nil` from `refusal(for:budget:)` means the file
    /// is within budget and safe to decode.
    public enum ImageRefusal: Equatable {
        /// Missing, unstattable, or not an image ImageIO can describe.
        case unreadable
        case fileTooLarge(bytes: Int, limit: Int)
        case tooManyPixels(pixels: Int, limit: Int)
    }

    /// The file's size on disk, or nil when it cannot be stat'd.
    public static func fileByteSize(at url: URL) -> Int? {
        guard url.isFileURL,
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int
        else { return nil }
        return size
    }

    /// The image's declared pixel dimensions, read from its header **without
    /// decoding**. Nil when the file is not an image ImageIO recognizes.
    public static func pixelDimensions(at url: URL) -> CGSize? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else { return nil }
        return CGSize(width: width, height: height)
    }

    /// Decide whether `url` may be decoded. Returns nil when it is within budget.
    public static func refusal(
        for url: URL, budget: ImageBudget = .default
    ) -> ImageRefusal? {
        guard let bytes = fileByteSize(at: url) else { return .unreadable }
        if bytes > budget.maxFileBytes {
            return .fileTooLarge(bytes: bytes, limit: budget.maxFileBytes)
        }
        guard let size = pixelDimensions(at: url) else { return .unreadable }
        let pixels = Int(size.width) * Int(size.height)
        if pixels > budget.maxPixels {
            return .tooManyPixels(pixels: pixels, limit: budget.maxPixels)
        }
        return nil
    }

    // MARK: - Cache

    /// Entries are keyed by path *and* modification time, so a live-reload loop
    /// that rewrites an image mints a new key on every save. Without a bound,
    /// the superseded entries are never reclaimed — NSCache only evicts under
    /// memory pressure, and a cost-based limit cannot fire at all when nothing
    /// is stored with a cost. Both limits are set, and every entry carries the
    /// size of its decoded bitmap.
    private static let countLimit = 64

    /// Roughly 256 MB of decoded pixels.
    private static let totalCostLimit = 256 * 1024 * 1024

    private static let cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
        return cache
    }()

    /// Load the image at `url`, returning a cached copy when the file has not
    /// changed since it was last decoded. Returns nil if the file is missing, is
    /// not decodable as an image, exceeds `budget`, or — when `base` is given —
    /// fails the containment check on the file that is actually opened.
    ///
    /// `base` is the deck directory. Pass it for anything sourced from markdown:
    /// `ImagePathResolver.resolve` decides containment on a path, and this is the
    /// re-check on the open descriptor that closes the gap between the two. The
    /// bytes are then decoded from what that descriptor returned, so nothing is
    /// re-opened by name after the check.
    public static func image(
        at url: URL, containedIn base: URL? = nil, budget: ImageBudget = .default
    ) -> NSImage? {
        // The budget is checked ahead of the cache deliberately: a caller that
        // asks for a tighter budget must be refused even when a previous, more
        // permissive caller already decoded the same file. This first pass is
        // path-based and cheap; it is a fast reject, not the security boundary —
        // the authoritative byte count is taken from the data actually read.
        guard refusal(for: url, budget: budget) == nil else { return nil }

        let key = cacheKey(for: url) as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard case .success(let data) = ImagePathResolver.readContained(at: url, in: base)
        else { return nil }
        guard refusal(forData: data, budget: budget) == nil else { return nil }
        guard let image = NSImage(data: data) else { return nil }
        cache.setObject(image, forKey: key, cost: decodedByteCost(of: image))
        return image
    }

    /// The budget applied to bytes already in hand. Used after a contained read,
    /// where the file's size on disk is no longer the number that matters — the
    /// data being decoded is.
    public static func refusal(
        forData data: Data, budget: ImageBudget = .default
    ) -> ImageRefusal? {
        if data.count > budget.maxFileBytes {
            return .fileTooLarge(bytes: data.count, limit: budget.maxFileBytes)
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int
        else { return .unreadable }
        let pixels = width * height
        if pixels > budget.maxPixels {
            return .tooManyPixels(pixels: pixels, limit: budget.maxPixels)
        }
        return nil
    }

    /// Approximate decoded footprint: pixel area at 4 bytes per pixel. This is
    /// what makes `totalCostLimit` meaningful — a cost of zero (the default)
    /// leaves the limit permanently unreachable.
    private static func decodedByteCost(of image: NSImage) -> Int {
        max(1, Int(image.size.width * image.size.height * 4))
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
