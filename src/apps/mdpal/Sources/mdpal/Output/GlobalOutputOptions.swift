// What Problem: Every command takes `--format json|text`. Re-declaring
// it on every command duplicates the help text and makes future shared
// flags (e.g., --quiet, --verbose) a multi-file change.
//
// How & Why: Single ParsableArguments struct that commands embed via
// @OptionGroup. ArgumentParser composes the help and parsing.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.2)

import ArgumentParser

struct GlobalOutputOptions: ParsableArguments {
    @Option(name: .long, help: "Output format: json (default) or text.")
    var format: OutputFormat = .json
}
