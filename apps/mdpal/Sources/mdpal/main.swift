// What Problem: Phase 2 introduces the real CLI. The mdpal binary needs an
// ArgumentParser-driven command tree so humans and agents can drive the
// engine over a stable wire format. mdpal-app (dispatch #407) is blocked
// waiting for this binary.
//
// How & Why: ArgumentParser AsyncParsableCommand at the root, with each
// subcommand in Commands/. Wire format is JSON by default (--format text
// for human reading), exit codes are deterministic per A&D §3.5, errors
// go to stderr as JSON envelopes, success payloads go to stdout.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import ArgumentParser

struct Mdpal: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "mdpal",
        abstract: "Markdown Pal — section-oriented Markdown document engine.",
        discussion: """
            mdpal operates on .mdpal bundles (a directory containing a versioned
            history of Markdown revisions plus YAML metadata for comments and flags).
            JSON is the default output; pass --format text for human-readable output.

            Exit codes:
              0 — success
              1 — general error (parse, invalid input)
              2 — version conflict (optimistic concurrency rejected)
              3 — not found (slug, comment, file)
              4 — bundle conflict (revision collision, concurrent write)
            """,
        version: "0.2.0-dev",
        subcommands: [
            VersionCommand.self,
            SectionsCommand.self,
            ReadCommand.self,
        ]
    )
}

Mdpal.main()
