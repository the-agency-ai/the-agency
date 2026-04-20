// What Problem: Load theme JSON files from the app bundle or arbitrary paths
// and decode them into Theme structs. The app ships with agency-default and
// agency-dark bundled; Phase 5 adds custom theme loading.
//
// How & Why: Singleton with a thread-safe cache. Uses a dictionary with a
// lock (replacing NSCache which is not Sendable). Looks for themes in the
// bundle's Resources/Themes/ directory first. JSONDecoder handles the
// snake_case → camelCase mapping via CodingKeys on the Theme struct.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.2
// Updated: 2026-04-12 — replaced NSCache with lock-guarded dictionary
//   to resolve Sendable compliance (QG finding #3)

import Foundation

public final class ThemeLoader: @unchecked Sendable {
    public static let shared = ThemeLoader()

    private var cache: [String: Theme] = [:]
    private let lock = NSLock()

    private init() {}

    /// Load a theme by name from the bundle's Resources/Themes/ directory.
    /// Returns nil if the theme file is not found or fails to decode.
    public func load(name: String) -> Theme? {
        lock.lock()
        if let cached = cache[name] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: "json",
            subdirectory: "Themes"
        ) else {
            return nil
        }

        return loadFromURL(url, cacheKey: name)
    }

    /// Load a theme from an arbitrary file URL.
    public func load(from url: URL) -> Theme? {
        let key = url.absoluteString
        lock.lock()
        if let cached = cache[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()
        return loadFromURL(url, cacheKey: key)
    }

    private func loadFromURL(_ url: URL, cacheKey: String) -> Theme? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let theme = try decoder.decode(Theme.self, from: data)
            lock.lock()
            cache[cacheKey] = theme
            lock.unlock()
            return theme
        } catch {
            // Diagnostic will be surfaced by the caller
            return nil
        }
    }
}
