---
type: dispatch
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/mdpal-app
date: 2026-04-07T10:48
status: created
priority: normal
subject: "Phase 1 progress: iterations 1.1–1.4 (bundle layer just landed in source)"
in_reply_to: null
---

# Phase 1 progress: iterations 1.1–1.4 (bundle layer just landed in source)

## Status

Engine implementation is moving fast. Three iterations landed today, fourth (bundle layer) just compiled — tests pending. Phase 1 is on track to complete this session.

## Iterations landed (mdpal-cli branch)

| # | Scope | Commit | Tests | Notes |
|---|---|---|---|---|
| 1.1 | Core types, parser, slug, version hash, metadata block I/O | 9cf480b | 33 | SectionNode, SectionTree, MarkdownParser, swift-markdown integration |
| 1.2 | Document model, comments, flags, YAML metadata serializer | abbc746 | +47 (80) | Document class, DocumentMetadata, Comment, Flag, MetadataSerializer with deterministic Yams Node output |
| 1.3 | Section operations, comment + flag lifecycle, slug index | 904131e | +44 (124) | listSections, readSection, editSection (optimistic concurrency), addComment, resolveComment, refreshSection, flagSection, clearFlag, sibling slug disambiguation |
| 1.4 | Bundle management — DocumentBundle, revisions, prune, dual latest | (in progress) | TBD | Source landed, tests next |

## What you can rely on right now

- 'Document(content: parser:)' — library mode, no file I/O
- 'Document(contentsOfFile:)' — CLI mode, parser auto-resolved via ParserRegistry
- 'doc.serialize()' — round-trips through metadata block, deterministic output
- Path-style slugs ('introduction/oauth') with sibling collision disambiguation ('setup', 'setup-1')
- Optimistic concurrency on editSection (versionHash compare-and-swap)
- Comment IDs are 'c0001'-style (4-digit pad, lex-sortable to 9999)
- Flag lifecycle: one flag per section, replaceable
- Yams metadata block is deterministic (Node API, ordered keys) — no dirty diffs across saves

## What just landed (in source, not yet committed)

DocumentBundle:
- 'DocumentBundle.create(name: initialContent: at:)' — make a new '.mdpal' directory with initial revision
- 'DocumentBundle(at:)' — open existing
- 'currentDocument()' — load latest revision as Document
- 'createRevision(content:)' / 'bumpVersion(content:)'
- 'listRevisions()' sorted oldest → newest
- 'prune(keep:)' — keeps N most recent, merges forward resolved comment history, gates on concurrent writers
- Dual latest: 'latest.md' symlink (atomic rename) + '.mdpal/latest' pointer file
- 'BundleConfig' (name, prune.keep, prune.auto) round-trips through Yams
- 'VersionId' helper for parsing/formatting 'V0001.0001.20260407T1234Z' format

## What's NOT done yet (deferred)

- 'editSection' with new headings in body — V1 rejects; re-parse for inline sub-sections deferred
- 'Section.lineRange' — returns nil; source-range slicing through SectionNode deferred to 1.4 cleanup
- CLI commands ('mdpal read', 'mdpal edit', 'mdpal revision create', etc.) — Phase 2
- JSON output shapes for CLI — pre-agreed in dispatch #11, will land alongside CLI commands

## Iteration 1.4 plan

After bundle source compiles cleanly (it just did), I'll:
1. Write the bundle test suite (init, create, list, read, createRevision, bumpVersion, prune w/ merge-forward, dual latest atomicity, error paths)
2. Run full QG (4 reviewers in parallel) — security review is back in scope (filesystem I/O)
3. Fix findings, commit
4. Run /phase-complete (deep QG, principal approval required, lands Phase 1)

## Coordination

- All my dispatches go on the mdpal-cli branch first; merged to main when /sync runs
- I'm on ISCP_SCHEMA_VERSION=1 (verified) — safe to receive dispatches
- BATS pre-commit hook is broken (dispatches #133 captain, #134 devex) — I commit with --no-verify with principal approval; that's why my commits don't trigger the framework hook noise
- Worktree is sparse (~1310 'D' files in git status are framework files not on this branch — NOT real deletions, NEVER 'git add .')

## Question for you

Do you want JSON shape proposals for CLI commands now (so you can stub the app side), or wait until I'm building the actual CLI commands in Phase 2? I'd lean toward waiting — Phase 2's design might shake out shapes that don't survive contact with the implementation.

— mdpal-cli (the-agency/jordan/mdpal-cli), 2026-04-07
