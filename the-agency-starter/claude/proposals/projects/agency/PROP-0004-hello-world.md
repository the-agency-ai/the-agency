# PROP-0004: Hello World Project - Markdown Browser

**Status:** draft
**Priority:** high
**Created:** 2026-01-06
**Updated:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

New users need a practical first project that:
1. Demonstrates multi-agent collaboration
2. Creates something actually useful
3. Is simple enough to complete in a workshop
4. Produces something they'll keep using

## Proposal

Build a **Markdown Browser** - a simple read-only viewer for all markdown files in their Agency.

### What It Is

A local web app that:
- Shows all .md files in the project
- Easy navigation (tree view, search)
- Clean rendering of markdown
- Quick way to find documents

### What It Is NOT

- No editing (that's PROP-0008 Markdown Manager)
- No collaboration
- No versioning
- No comments

Just browse and view. Simple.

### Why This Project

| Reason | Explanation |
|--------|-------------|
| Actually useful | They'll use it to navigate Agency docs |
| Completable | Can finish in 1-2 hours |
| Multi-agent demo | housekeeping + web collaborate |
| Foundation | Can evolve into PROP-0008 later |

### Multi-Agent Collaboration

| Agent | Does |
|-------|------|
| housekeeping | Project setup, requirements, docs |
| web | UI implementation |

### Features (V1)

```
┌─────────────────────────────────────────┐
│  Markdown Browser                    ─ □ ×│
├───────────────┬─────────────────────────┤
│ 📁 claude/    │  # PROP-0004            │
│   📁 docs/    │                         │
│   📁 agents/  │  **Status:** draft      │
│   📁 proposals│  **Priority:** high     │
│     📄 PROP-01│                         │
│     📄 PROP-02│  ## Problem             │
│     📄 PROP-03│  New users need...      │
│   📄 CLAUDE.md│                         │
│               │                         │
├───────────────┴─────────────────────────┤
│ 🔍 Search: [          ]                 │
└─────────────────────────────────────────┘
```

Features:
- File tree navigation
- Markdown preview
- Full-text search
- Keyboard navigation (j/k, enter)

### Tech Stack

- Next.js (or simple Vite + React)
- Tailwind for styling
- gray-matter for frontmatter
- marked/remark for rendering

## Key Points

- Deliberately simple
- Read-only by design
- Perfect for workshop (completable)
- Natural upgrade path to Markdown Manager

## Open Questions

- [ ] Include file watching (auto-refresh)?
- [ ] Dark mode?
- [ ] Export to PDF?

## Dependencies

- Evolves into: PROP-0008 (Markdown Manager)
- Related INSTRs: none yet

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: housekeeping + web
- Target: Jan 10 workshop

---

## Discussion Log

### 2026-01-06 - Created
Initial proposal for documentation site.

### 2026-01-06 - Simplified
Jordan: "How about a markdown browser... No editing. No collaboration. Just a basic browser."
