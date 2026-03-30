# markdown-pal Workstream Knowledge

**Created:** 2026-03-29 13:04:37 +08
**Updated:** 2026-03-29

## Overview

Definition, design, and development of **Markdown Pal** — a section-oriented Markdown review tool for structured design artifacts. Swift/SwiftUI native app (macOS + iPadOS + iOS) with CLI (`mdpal`), LSP server, and MCP server interfaces.

Core concept: the document IS the review artifact. Comments, decisions, and review state are tracked as YAML metadata inside the `.md` file itself, using a `.mdpal` bundle format for versioned revisions.

## Key Concepts

- **Section-oriented editing** — headings define the fundamental unit of all operations. Comments anchor to sections, edits target sections, the AST is the API.
- **Token efficiency** — agents never read an entire file for scoped work. Section-level reads, comments, and edits keep context windows small.
- **`.mdpal` bundle** — a directory the OS presents as a single document, containing versioned revisions. Version history is intrinsic, not dependent on git.
- **Comment lifecycle** — comments are anchored to sections with a context field (the exact text commented on), enabling staleness detection and portability.
- **Optimistic concurrency** — section version hashes enable compare-and-swap editing without locks.

## Seed Files

- `usr/jordan/markdown-pal/markdown-pal-seed-20260329.md` — full design doc (v0001.0003)
- `usr/jordan/markdown-pal/markdown-pal-analysis-20260329.md` — CoS session analysis
- `usr/jordan/markdown-pal/markdown-pal-chatlog-20250310.md` — original chatlog
- `usr/jordan/markdown-pal/markdown-pal-cli-spec-20250310.md` — CLI specification
- `usr/jordan/markdown-pal/markdown-pal-prompt-20250310.md` — original prompt

## Current Focus

- Run PVR and A&D discussions via `/discuss` using the seed files
- Resolve the 9 research comments (r001-r009) in the seed document
- Define CLI/LSP interface for Claude Code integration
- Determine platform priority (macOS CLI vs native app first)

## References

- Agent class: `claude/agents/tech-lead/agent.md`
- Registration: `.claude/agents/markdown-pal.md`
- 9 open research comments (r001-r009) in the seed document
