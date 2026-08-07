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

import SwiftUI
import AppKit

enum FontResolver {
    /// Resolve a CSS-style font stack to a SwiftUI Font at the given size/weight.
    /// If no named family resolves, falls back to the system font with the
    /// requested design.
    static func resolve(
        stack: String,
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> Font {
        let generics: Set<String> = [
            "sans-serif", "serif", "monospace", "cursive", "fantasy"
        ]

        for raw in stack.split(separator: ",") {
            let name = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if name.isEmpty { continue }
            if generics.contains(name.lowercased()) { continue }

            // System-ish families — use SwiftUI system font (best rendering).
            let lower = name.lowercased()
            if lower == "-apple-system" || lower == "system-ui" || lower == "bodyfont" || lower == "ui-sans-serif" || lower == "ui-serif" || lower == "ui-monospace" {
                return .system(size: size, weight: weight, design: design)
            }

            // Probe with NSFont to see whether this family actually resolves.
            if NSFont(name: name, size: size) != nil {
                return Font.custom(name, size: size).weight(weight)
            }
            // Also try common PostScript-style variants (family names vs face names).
            let withoutSpaces = name.replacingOccurrences(of: " ", with: "")
            if NSFont(name: withoutSpaces, size: size) != nil {
                return Font.custom(withoutSpaces, size: size).weight(weight)
            }
        }

        return .system(size: size, weight: weight, design: design)
    }

    /// Convenience: resolve a theme's sans/display/mono family for a given role.
    static func sans(_ theme: Theme, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        resolve(stack: theme.fonts.sansFamily, size: size, weight: weight, design: .default)
    }

    static func display(_ theme: Theme, size: CGFloat, weight: Font.Weight = .bold) -> Font {
        resolve(stack: theme.fonts.displayFamily, size: size, weight: weight, design: .default)
    }

    static func mono(_ theme: Theme, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        resolve(stack: theme.fonts.monoFamily, size: size, weight: weight, design: .monospaced)
    }
}
