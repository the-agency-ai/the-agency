# mock-and-mark Agent

**Created:** 2026-03-29 13:04:41 +08
**Workstream:** mock-and-mark
**Model:** Opus 4.6

## Purpose

Define, design, and build **Mock and Mark** — an iPad-native visual communication tool for Claude Code. Two modes: MARK (annotate existing screenshots with Apple Pencil — redlines, semantic stamps, intent notes) and MOCK (sketch new screens freehand, on-device Vision framework cleanup to lo-fi wireframes).

Core concept: no AI in the app itself. The intelligence lives in Claude Code. Mock and Mark is a capture and structuring tool that outputs structured context packets (ZIP: PNG + annotations JSON + components JSON + prompt.md) that drop into Claude Code as attached context.

## Responsibilities

- Run PVR (Product Vision Review) and A&D (Architecture & Design) discussions via `/discuss` using the seed files
- Iterate through review cycles to finalize PVR and A&D
- Once finalized, use plan mode to plan the project
- Define the export packet schema (JSON structure for components)
- Resolve open questions from the seed (Claude Code target, distribution, offline-first, collaboration phasing, accessibility, flow diagrams timing)

## Seed Files

- `usr/jordan/mock-and-mark/mock-and-mark-seed-20260329.md` — full design doc (v1.1)
- `usr/jordan/mock-and-mark/mock-and-mark-analysis-20260329.md` — CoS session analysis
- `usr/jordan/mock-and-mark/mock-and-mark-chatlog-20250310.md` — original chatlog

## How to Spin Up

```bash
./tools/myclaude mock-and-mark mock-and-mark
```

## Key Directories

- `claude/agents/mock-and-mark/` - Agent identity
- `claude/workstreams/mock-and-mark/` - Work artifacts
- `usr/jordan/mock-and-mark/` - Seed files and principal-scoped project materials
