// What Problem: Theme JSON files specify fonts as CSS-style comma-separated
// family lists (e.g. "system-ui, -apple-system, 'SF Pro Display', sans-serif").
// SwiftUI needs a concrete Font. We have to pick the first family that
// actually resolves on this machine and fall back to the system font.
//
// How & Why: Parse the stack, strip quotes and whitespace, skip CSS generic
// families (sans-serif, serif, monospace), map "-apple-system" and
// "system-ui" to Font.system, and for every other named family try
// NSFont(name:size:) to see whether it resolves before returning
// Font.custom(...). If nothing resolves, fall back to .system. This is what
// closes the visual gap with reveal.js — reveal uses the browser's native
// font matching; we emulate it manually.
//
// Written: 2026-04-15 during mdslidepal-mac Phase 5.2 (visual polish)

// Updated: 2026-08-07 PR-prep QG — split family resolution out of Font
// construction so the stack-walking rules are unit-testable (SwiftUI Font
// values do not compare usefully), memoized the AppKit registration probes
// that were running on every view body, and made the type public so the app
// target and PDF export can share the same typography.

import SwiftUI
import AppKit

public enum FontResolver {

    /// Which font a stack resolves to, independent of size and weight.
    ///
    /// Separating this from `Font` construction is what makes resolution
    /// testable — SwiftUI `Font` values do not compare usefully, but this does.
    public enum Resolution: Equatable {
        /// No named family resolved; use the system font.
        case system
        /// A registered family, named as AppKit knows it.
        case family(String)
    }

    /// CSS generic family keywords. They name a category, not a font, so they
    /// are skipped — the system-font fallback covers them.
    private static let genericFamilies: Set<String> = [
        "sans-serif", "serif", "monospace", "cursive", "fantasy"
    ]

    /// Families that mean "whatever the platform's UI font is". `bodyfont` is
    /// the token emitted by the shared theme JSON in
    /// agency/workstreams/mdslidepal/themes/ for body copy.
    private static let systemFamilies: Set<String> = [
        "-apple-system", "system-ui", "bodyfont",
        "ui-sans-serif", "ui-serif", "ui-monospace"
    ]

    /// Resolution is pure string work plus AppKit font-registration probes, and
    /// `resolve` is called from view bodies on every render pass. Font
    /// registration does not change during a run, so results are memoized by
    /// stack.
    private static let cache = NSCache<NSString, CachedResolution>()

    /// Box type — NSCache requires a class value.
    private final class CachedResolution {
        let value: Resolution
        init(_ value: Resolution) { self.value = value }
    }

    /// Resolve a CSS-style font stack to the first family that actually exists.
    ///
    /// Walks the stack left to right, skipping empty entries and generic
    /// keywords, and returns `.system` when nothing named resolves.
    public static func resolution(for stack: String) -> Resolution {
        let key = stack as NSString
        if let cached = cache.object(forKey: key) { return cached.value }

        let resolved = computeResolution(for: stack)
        cache.setObject(CachedResolution(resolved), forKey: key)
        return resolved
    }

    private static func computeResolution(for stack: String) -> Resolution {
        for raw in stack.split(separator: ",") {
            let name = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if name.isEmpty { continue }

            let lower = name.lowercased()
            if genericFamilies.contains(lower) { continue }
            if systemFamilies.contains(lower) { return .system }

            // Probe with NSFont to see whether this family actually resolves.
            if NSFont(name: name, size: 12) != nil {
                return .family(name)
            }
            // Family names carry spaces ("SF Mono"); PostScript names do not
            // ("SFMono-Regular"). Try the despaced form before giving up.
            let withoutSpaces = name.replacingOccurrences(of: " ", with: "")
            if withoutSpaces != name, NSFont(name: withoutSpaces, size: 12) != nil {
                return .family(withoutSpaces)
            }
        }

        return .system
    }

    /// Resolve a CSS-style font stack to a SwiftUI Font at the given size/weight.
    /// If no named family resolves, falls back to the system font with the
    /// requested design.
    public static func resolve(
        stack: String,
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> Font {
        switch resolution(for: stack) {
        case .system:
            return .system(size: size, weight: weight, design: design)
        case .family(let name):
            return Font.custom(name, size: size).weight(weight)
        }
    }

    /// Convenience: resolve a theme's sans/display/mono family for a given role.
    public static func sans(_ theme: Theme, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        resolve(stack: theme.fonts.sansFamily, size: size, weight: weight, design: .default)
    }

    public static func display(_ theme: Theme, size: CGFloat, weight: Font.Weight = .bold) -> Font {
        resolve(stack: theme.fonts.displayFamily, size: size, weight: weight, design: .default)
    }

    public static func mono(_ theme: Theme, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        resolve(stack: theme.fonts.monoFamily, size: size, weight: weight, design: .monospaced)
    }
}
