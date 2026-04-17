// What Problem: Every command takes a --format flag (json default, text
// optional). Defining the enum once keeps the contract uniform across
// commands and lets ArgumentParser handle parsing/validation.
//
// How & Why: Simple enum conforming to ExpressibleByArgument.
// Default is .json — agents and mdpal-app rely on machine-readable
// output. .text is the human convenience.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import ArgumentParser

enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
    case json
    case text
}
