// What Problem: Theme JSON files specify colors as hex strings (#ffffff).
// SwiftUI needs Color values. This extension bridges the gap.
//
// How & Why: Parses 6-digit hex strings into Color via RGB components.
// Handles the # prefix, validates length. Returns a fallback color on
// parse failure rather than crashing — matches contract §11 error handling
// philosophy (warn, don't abort).
//
// Two entry points: `Color(hex:)` falls back to magenta so a broken theme is
// visually obvious, while `Color(validatingHex:)` returns nil so callers taking
// untrusted input (per-slide `background:` metadata) can choose their own
// fallback. 3-, 6- and 8-digit forms are all accepted.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.2
// Updated: 2026-08-07 PR-prep QG — added the validating initializer and
//   3-/8-digit support; slide metadata no longer renders magenta on a valid but
//   previously unsupported CSS color.
// Updated: 2026-08-12 PR-prep QG — trim before stripping the `#`; the other
//   order rejected " #ff0000" outright.

import SwiftUI

extension Color {
    /// Initialize a Color from a hex string (e.g., "#ff0000" or "ff0000").
    ///
    /// Falls back to magenta when the string is not a valid hex color, so a
    /// broken *theme* is visually obvious. Callers handling untrusted input —
    /// per-slide `background:` metadata, for instance — should use
    /// `Color(validatingHex:)` and supply their own fallback instead.
    public init(hex: String) {
        self = Color(validatingHex: hex) ?? Color(red: 1.0, green: 0.0, blue: 1.0)
    }

    /// Initialize from a hex string, returning nil when it is not a valid
    /// color. Accepts 3-digit (`#fff`), 6-digit (`#ffffff`) and 8-digit RGBA
    /// (`#ffffffcc`) forms, with or without a leading `#`.
    public init?(validatingHex hex: String) {
        // Trim first, then strip. The other order leaves the `#` embedded in
        // " #ff0000" — the hex-digit check then rejects a perfectly good color.
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed

        guard cleaned.allSatisfy({ $0.isHexDigit }),
              let raw = UInt64(cleaned, radix: 16)
        else { return nil }

        switch cleaned.count {
        case 3:
            // Shorthand: each digit is doubled — #abc means #aabbcc.
            let r = Double((raw >> 8) & 0xF) / 15.0
            let g = Double((raw >> 4) & 0xF) / 15.0
            let b = Double(raw & 0xF) / 15.0
            self.init(red: r, green: g, blue: b)
        case 6:
            let r = Double((raw >> 16) & 0xFF) / 255.0
            let g = Double((raw >> 8) & 0xFF) / 255.0
            let b = Double(raw & 0xFF) / 255.0
            self.init(red: r, green: g, blue: b)
        case 8:
            let r = Double((raw >> 24) & 0xFF) / 255.0
            let g = Double((raw >> 16) & 0xFF) / 255.0
            let b = Double((raw >> 8) & 0xFF) / 255.0
            let a = Double(raw & 0xFF) / 255.0
            self.init(red: r, green: g, blue: b, opacity: a)
        default:
            return nil
        }
    }
}
