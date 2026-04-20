# mdpal — Workstream Knowledge

**Product name:** Markdown Pal (human), `mdpal` (machine)
**Agents:** `mdpal-cli` (engine + CLI), `mdpal-app` (macOS native app)

## Scope

Section-oriented Markdown review tool. Parses Markdown into sections, enables review workflows (approve, comment, request changes) at the section level rather than line level. Two deliverables: a CLI/engine library and a macOS native app.

## Patterns and Conventions

<!-- Accumulate patterns discovered during development -->

## Key Decisions

- Workstream renamed from `markdown-pal` to `mdpal` (2026-04-02)
- Two agents: `mdpal-cli` owns engine + CLI, `mdpal-app` owns macOS native UI
- Both agents share one worktree, coordinate via dispatches in `usr/{principal}/mdpal/`
