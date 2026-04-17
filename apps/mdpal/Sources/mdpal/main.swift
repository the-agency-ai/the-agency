// What Problem: Phase 2 introduces the real CLI. The mdpal binary needs an
// ArgumentParser-driven command tree so humans and agents can drive the
// engine over a stable wire format. mdpal-app (dispatch #407) is blocked
// waiting for this binary.
//
// How & Why: ParsableCommand at the root, with each subcommand in
// Commands/. Wire format is JSON by default (--format text for human
// reading), exit codes are deterministic per A&D §3.5, errors go to
// stderr as JSON envelopes, success payloads go to stdout. Tool version
// is exposed via `--version` (auto from `version:` in configuration) —
// `version` itself is reserved as a SUBCOMMAND GROUP for document-
// version operations (`mdpal version show/bump <bundle>`) per the
// dispatched spec, landing in a later iteration.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
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

            Use --version to print the tool version. The `version` subcommand
            group operates on the document version of a bundle
            (`mdpal version show/bump <bundle>`).

            Exit codes (see error envelope `error` field for category):
              0 — success
              1 — general error
              2 — version conflict (optimistic concurrency)
              3 — not found (slug, comment, file)
              4 — bundle conflict (revision collision, concurrent write)
            """,
        version: "0.2.0-dev",
        subcommands: [
            SectionsCommand.self,
            ReadCommand.self,
            EditCommand.self,
            CommentCommand.self,
            CommentsCommand.self,
            ResolveCommand.self,
            FlagCommand.self,
            FlagsCommand.self,
            ClearFlagCommand.self,
            CreateCommand.self,
            HistoryCommand.self,
            VersionCommand.self,
            RevisionCommand.self,
            DiffCommand.self,
            PruneCommand.self,
            RefreshCommand.self,
        ]
    )
}

Mdpal.main()
