// What Problem: Per-slide metadata parsed from <!-- slide: ... --> HTML comment
// blocks immediately after a slide break (contract §3).
//
// How & Why: Simple struct with optional fields for the reserved keys
// (background, transition, class). Layout and notes_file are deferred to
// Phase 2 but the field is present for forward compatibility. Unknown keys
// are captured in `extra` for theme pass-through.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.1

import Foundation

/// Per-slide metadata from `<!-- slide: ... -->` blocks.
public struct SlideMetadata: Equatable {
    /// Background color override (hex string).
    public var background: String?
    /// Transition type: "none" or "fade".
    public var transition: String?
    /// CSS class name(s) for the slide.
    public var slideClass: String?
    /// Layout name (Phase 2 — deferred, present for forward compatibility).
    public var layout: String?
    /// Any additional keys from the YAML block.
    public var extra: [String: String]

    public init(
        background: String? = nil,
        transition: String? = nil,
        slideClass: String? = nil,
        layout: String? = nil,
        extra: [String: String] = [:]
    ) {
        self.background = background
        self.transition = transition
        self.slideClass = slideClass
        self.layout = layout
        self.extra = extra
    }
}
