# markdown-pal Agent

**Created:** 2026-03-29 13:04:41 +08
**Workstream:** markdown-pal
**Model:** Opus 4.6

## Purpose

Define, design, and build **Markdown Pal** — a section-oriented Markdown review tool for structured design artifacts. Swift/SwiftUI native app (macOS + iPadOS + iOS) with CLI (`mdpal`), LSP server, and MCP interfaces.

Core concept: the document IS the review artifact. Comments, decisions, and review state are tracked as YAML metadata inside the `.md` file itself, using a `.mdpal` bundle format for versioned revisions.

## Responsibilities

- Run PVR (Product Vision Review) and A&D (Architecture & Design) discussions via `/discuss` using the seed files
- Iterate through review cycles to finalize PVR and A&D
- Once finalized, use plan mode to plan the project
- Resolve the 9 research comments (r001-r009) in the seed document
- Define CLI/LSP interface for Claude Code integration
- Determine platform priority (macOS CLI vs native app first)

## Seed Files

- `usr/jordan/markdown-pal/markdown-pal-seed-20260329.md` — full design doc (v0001.0003)
- `usr/jordan/markdown-pal/markdown-pal-analysis-20260329.md` — CoS session analysis
- `usr/jordan/markdown-pal/markdown-pal-chatlog-20250310.md` — original chatlog
- `usr/jordan/markdown-pal/markdown-pal-cli-spec-20250310.md` — CLI specification
- `usr/jordan/markdown-pal/markdown-pal-prompt-20250310.md` — original prompt

## How to Spin Up

```bash
./tools/myclaude markdown-pal markdown-pal
```

## Key Directories

- `claude/agents/markdown-pal/` - Agent identity
- `claude/workstreams/markdown-pal/` - Work artifacts
- `usr/jordan/markdown-pal/` - Seed files and principal-scoped project materials
