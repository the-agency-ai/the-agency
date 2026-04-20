// What Problem: Codable theme struct that maps the shared theme JSON schema
// (themes/agency-default.json, agency-dark.json) to Swift types for SwiftUI
// rendering. Every visual property in the app comes from this struct — no
// hardcoded colors or sizes.
//
// How & Why: Mirrors the theme-schema.json exactly with snake_case JSON
// mapping via CodingKeys. Codable for JSONDecoder. A static `agencyDefault`
// constant provides the fallback when no theme file loads. SwiftUI views
// read theme tokens via @Environment(\.theme).
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.2

import Foundation
import SwiftUI

// MARK: - Theme

public struct Theme: Codable, Equatable, Sendable {
    public let name: String
    public let version: String
    public let description: String?
    public let aspectRatio: String
    public let logicalDimensions: LogicalDimensions
    public let colors: ColorPalette
    public let fonts: FontStack
    public let headingScale: HeadingScale
    public let bodySize: Int
    public let lineHeight: Double
    public let spacingUnit: Int
    public let slidePadding: SlidePadding
    public let codeTheme: CodeTheme
    public let transitions: Transitions

    enum CodingKeys: String, CodingKey {
        case name, version, description
        case aspectRatio = "aspect_ratio"
        case logicalDimensions = "logical_dimensions"
        case colors, fonts
        case headingScale = "heading_scale"
        case bodySize = "body_size"
        case lineHeight = "line_height"
        case spacingUnit = "spacing_unit"
        case slidePadding = "slide_padding"
        case codeTheme = "code_theme"
        case transitions
    }
}

// MARK: - Sub-types

public struct LogicalDimensions: Codable, Equatable, Sendable {
    public let width: Int
    public let height: Int
}

public struct ColorPalette: Codable, Equatable, Sendable {
    public let background: String
    public let foreground: String
    public let accent: String
    public let muted: String
    public let subtle: String
    public let border: String
    public let link: String
    public let codeBackground: String
    public let codeBorder: String

    enum CodingKeys: String, CodingKey {
        case background, foreground, accent, muted, subtle, border, link
        case codeBackground = "code_background"
        case codeBorder = "code_border"
    }
}

public struct FontStack: Codable, Equatable, Sendable {
    public let sansFamily: String
    public let monoFamily: String
    public let displayFamily: String

    enum CodingKeys: String, CodingKey {
        case sansFamily = "sans_family"
        case monoFamily = "mono_family"
        case displayFamily = "display_family"
    }
}

public struct HeadingScale: Codable, Equatable, Sendable {
    public let h1: Int
    public let h2: Int
    public let h3: Int
    public let h4: Int
    public let h5: Int
    public let h6: Int

    public init(h1: Int, h2: Int, h3: Int, h4: Int, h5: Int, h6: Int) {
        self.h1 = h1; self.h2 = h2; self.h3 = h3
        self.h4 = h4; self.h5 = h5; self.h6 = h6
    }

    /// Get heading size for a given level (1–6).
    public func size(for level: Int) -> Int {
        switch level {
        case 1: return h1
        case 2: return h2
        case 3: return h3
        case 4: return h4
        case 5: return h5
        case 6: return h6
        default: return h6
        }
    }
}

public struct SlidePadding: Codable, Equatable, Sendable {
    public let top: Int
    public let right: Int
    public let bottom: Int
    public let left: Int

    public var edgeInsets: EdgeInsets {
        EdgeInsets(
            top: CGFloat(top),
            leading: CGFloat(left),
            bottom: CGFloat(bottom),
            trailing: CGFloat(right)
        )
    }
}

public struct CodeTheme: Codable, Equatable, Sendable {
    public let background: String
    public let foreground: String
    public let comment: String
    public let keyword: String
    public let string: String
    public let number: String
    public let function: String
    public let variable: String
    public let type: String
    public let `operator`: String
    public let punctuation: String
}

public struct Transitions: Codable, Equatable, Sendable {
    public let `default`: String
    public let fadeDurationMs: Int
    public let fadeEasing: String

    enum CodingKeys: String, CodingKey {
        case `default`
        case fadeDurationMs = "fade_duration_ms"
        case fadeEasing = "fade_easing"
    }
}

// MARK: - Bundled Default

extension Theme {
    /// The bundled agency-default theme, used as fallback when no theme file loads.
    public static let agencyDefault = Theme(
        name: "agency-default",
        version: "0.1.0",
        description: "The Agency default theme for mdslidepal.",
        aspectRatio: "16:9",
        logicalDimensions: LogicalDimensions(width: 1920, height: 1080),
        colors: ColorPalette(
            background: "#ffffff",
            foreground: "#1a1a1a",
            accent: "#0066cc",
            muted: "#666666",
            subtle: "#eeeeee",
            border: "#dddddd",
            link: "#0066cc",
            codeBackground: "#f5f5f5",
            codeBorder: "#e0e0e0"
        ),
        fonts: FontStack(
            sansFamily: "system-ui, -apple-system, 'SF Pro Text', sans-serif",
            monoFamily: "'SF Mono', 'Menlo', monospace",
            displayFamily: "system-ui, -apple-system, 'SF Pro Display', sans-serif"
        ),
        headingScale: HeadingScale(h1: 72, h2: 56, h3: 44, h4: 36, h5: 28, h6: 24),
        bodySize: 32,
        lineHeight: 1.4,
        spacingUnit: 16,
        slidePadding: SlidePadding(top: 96, right: 120, bottom: 96, left: 120),
        codeTheme: CodeTheme(
            background: "#f5f5f5",
            foreground: "#1a1a1a",
            comment: "#6a737d",
            keyword: "#d73a49",
            string: "#032f62",
            number: "#005cc5",
            function: "#6f42c1",
            variable: "#24292e",
            type: "#6f42c1",
            operator: "#d73a49",
            punctuation: "#24292e"
        ),
        transitions: Transitions(default: "none", fadeDurationMs: 250, fadeEasing: "linear")
    )
}
