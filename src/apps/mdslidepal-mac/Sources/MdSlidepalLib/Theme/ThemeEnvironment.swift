// What Problem: SwiftUI views need access to the current theme without
// passing it through every initializer. The @Environment pattern provides
// this via dependency injection.
//
// How & Why: Custom EnvironmentKey with Theme.agencyDefault as the default
// value. Views read @Environment(\.theme) to get colors, fonts, sizes.
// The theme is set at the top-level DeckWindowView and flows down.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.2

import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .agencyDefault
}

extension EnvironmentValues {
    public var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
