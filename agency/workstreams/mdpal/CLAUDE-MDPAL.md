# CLAUDE-MDPAL.md — mdpal workstream

The **mdpal** workstream builds **Markdown Pal** — a section-oriented Markdown engine and toolchain for AIADLC workflows. Two agents share the workstream: `mdpal-cli` (the headless engine + CLI tool) and `mdpal-app` (the macOS native review app).

## Purpose

Markdown is the medium of AIADLC. Plans, handoffs, seeds, dispatches, QGRs, documentation — everything is markdown. But treating a large markdown file as one opaque blob is hostile to iterative work. **Markdown Pal** treats markdown as a tree of addressable sections so tools and humans can read, revise, and review individual sections without touching the rest of the document.

The engine is language-agnostic. The CLI exposes section-level read/write/diff/compose. The macOS app provides native UI for reviewers who want a rich editing experience without leaving their workflow.

## Scope

- **In scope:** section addressing, section-level read/write, section diff, section compose, markdown frontmatter handling, table of contents generation, native macOS reviewer UI, CLI tool and skill, BATS + Swift tests.
- **Licensing:** Reference Source License per-directory (see `agency/workstreams/mdpal/LICENSE`). Not MIT like the framework.
- **Out of scope:** general-purpose markdown rendering, static site generation, Markdown flavor conversion (CommonMark / GFM / etc.) — mdpal is about STRUCTURE and REVIEW, not rendering.

## Agents

- **mdpal-cli** — headless engine + CLI tool. Worktree: `.claude/worktrees/mdpal-cli/`.
- **mdpal-app** — macOS native app using SwiftUI + the shared engine. Worktree: `.claude/worktrees/mdpal-app/`.

Both agents share the workstream directory and artifacts (PVR, A&D, Plan) but commit to their own branches. The shared artifacts are the contract between them.

## Conventions

- **Engine changes go to mdpal-cli first, then mdpal-app picks them up via merge** — the CLI is the source of truth for engine behavior.
- **Swift-specific work** (UI, native macOS features) lives in mdpal-app and does not bleed into mdpal-cli.
- **Test coverage parity** — every engine feature has tests on both sides.

## Related

- `agency/workstreams/mdpal/LICENSE` — Reference Source License
- PVR, A&D, Plan at `agency/workstreams/mdpal/` top level
- Upcoming: mdslide / mdslidepal — markdown-based slides feature (captured as seed pending build)

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
