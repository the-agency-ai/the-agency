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
    /// Bounded deliberately. NSCache with no `countLimit` only evicts under
    /// memory pressure, and the key is an arbitrary theme-supplied string — a
    /// deck that varies its font stacks would grow this without limit. A handful
    /// of distinct stacks per theme means a small cap costs nothing.
    private static let cache: NSCache<NSString, CachedResolution> = {
        let cache = NSCache<NSString, CachedResolution>()
        cache.countLimit = 64
        return cache
    }()

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

    /// The families a stack names, in order, cleaned of quotes and whitespace,
    /// with empty entries and CSS generic keywords dropped.
    ///
    /// Split out from resolution so the parsing rules can be tested without a
    /// font probe: which families are on the host is not the parser's business,
    /// and a test that asserts `.family("Helvetica")` is really asserting the
    /// contents of /System/Library/Fonts.
    public static func candidateFamilies(in stack: String) -> [String] {
        stack.split(separator: ",").compactMap { raw in
            let name = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty { return nil }
            if genericFamilies.contains(name.lowercased()) { return nil }
            return name
        }
    }

    /// Whether AppKit knows a family by that name. The real probe.
    private static func isRegistered(_ name: String) -> Bool {
        NSFont(name: name, size: 12) != nil
    }

    /// Walk a stack with an explicit registration probe, bypassing the memo.
    ///
    /// The probe is a parameter so the stack-walking rules — first resolvable
    /// wins, system tokens short-circuit, despaced PostScript-name retry — can be
    /// pinned against a known font inventory instead of the host's.
    public static func resolution(
        for stack: String, probe: (String) -> Bool
    ) -> Resolution {
        for name in candidateFamilies(in: stack) {
            if systemFamilies.contains(name.lowercased()) { return .system }

            if probe(name) { return .family(name) }

            // Family names carry spaces ("Helvetica Neue"); the PostScript name
            // often does not ("HelveticaNeue"). Try the despaced form before
            // giving up. This only recovers PostScript names that ARE the
            // despaced family — removing spaces cannot add a style suffix, so
            // "SF Mono" reaches "SFMono" and not "SFMono-Regular".
            let withoutSpaces = name.replacingOccurrences(of: " ", with: "")
            if withoutSpaces != name, probe(withoutSpaces) {
                return .family(withoutSpaces)
            }
        }

        return .system
    }

    private static func computeResolution(for stack: String) -> Resolution {
        resolution(for: stack, probe: isRegistered)
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
