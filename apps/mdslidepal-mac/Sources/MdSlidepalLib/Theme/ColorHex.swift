// What Problem: Theme JSON files specify colors as hex strings (#ffffff).
// SwiftUI needs Color values. This extension bridges the gap.
//
// How & Why: Parses 6-digit hex strings into Color via RGB components.
// Handles the # prefix, validates length. Returns a fallback color on
// parse failure rather than crashing — matches contract §11 error handling
// philosophy (warn, don't abort).
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.2

import SwiftUI

extension Color {
    /// Initialize a Color from a hex string (e.g., "#ff0000" or "ff0000").
    public init(hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex

        guard cleaned.count == 6,
              let rgb = UInt64(cleaned, radix: 16)
        else {
            // Fallback to magenta so it's visually obvious something is wrong
            self.init(red: 1.0, green: 0.0, blue: 1.0)
            return
        }

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
