# AgencyBench DevApps Specifications

## Overview

DevApps are self-contained features embedded within AgencyBench. Each DevApp provides a specific capability for working with The Agency.

---

## Markdown Browser

**Purpose:** Browse and preview markdown documentation files with live rendering.

### Features

| Feature | Priority | Status |
|---------|----------|--------|
| File tree navigation | P0 | MVP |
| Markdown rendering (GFM) | P0 | MVP |
| Syntax highlighting | P0 | MVP |
| Search within files | P1 | Planned |
| File watching (live reload) | P1 | Planned |
| Open in editor | P2 | Planned |
| Copy content | P2 | Planned |
| Export to PDF | P3 | Future |

### File Sources

- Project root (`CLAUDE.md`, `README.md`, etc.)
- `claude/agents/*/agent.md`
- `claude/agents/*/KNOWLEDGE.md`
- `claude/workstreams/*/KNOWLEDGE.md`
- `claude/docs/**/*.md`

### Implementation Notes

**Web mode:** Uses sample content for demo
**Tauri mode:** Uses `read_file` and `list_files` commands for real FS access

### UI Layout

```
┌─────────────────────────────────────────────────────┐
│ [Search files...]                                   │
├─────────────────┬───────────────────────────────────┤
│ File Tree       │ Content Preview                   │
│                 │                                   │
│ ▸ CLAUDE.md     │ # The Agency                      │
│ ▸ README.md     │                                   │
│ ▸ claude/       │ A multi-agent development...      │
│   ▸ agents/     │                                   │
│     housekeeping│ ## Quick Start                    │
│       agent.md  │ ```bash                           │
│       KNOWLEDGE │ ./tools/myclaude housekeeping...  │
│                 │ ```                               │
└─────────────────┴───────────────────────────────────┘
```

---

## Knowledge Indexer

**Purpose:** Search and index KNOWLEDGE.md files across the project.

### Features

| Feature | Priority | Status |
|---------|----------|--------|
| Full-text search | P0 | MVP |
| Results with context | P0 | MVP |
| File stats (indexed count) | P0 | MVP |
| Re-index trigger | P1 | MVP |
| Filter by directory | P1 | Planned |
| Search history | P2 | Planned |
| Fuzzy matching | P2 | Planned |
| Semantic search (embeddings) | P3 | Future |

### Index Targets

Primary:
- `claude/agents/*/KNOWLEDGE.md`
- `claude/workstreams/*/KNOWLEDGE.md`

Secondary:
- `claude/docs/**/*.md`
- `*.md` in project root

### Implementation Notes

**Phase 1 (MVP):** Simple grep-based search
**Phase 2:** SQLite FTS5 for fast full-text search
**Phase 3:** Embeddings for semantic search (using cookbook patterns)

### UI Layout

```
┌─────────────────────────────────────────────────────┐
│ [Search knowledge...                    ] [Search]  │
├─────────────────────────────────────────────────────┤
│ Files: 12 │ Lines: 2,450 │ Last indexed: 2 min ago  │
├─────────────────────────────────────────────────────┤
│ Found 5 matches in 3 files                          │
│                                                     │
│ 📄 claude/agents/housekeeping/KNOWLEDGE.md          │
│    Line 15 • ## Session Patterns                    │
│    "Pattern: Always read KNOWLEDGE.md before..."    │
│                                                     │
│    Line 42 • ## What is Knowledge                   │
│    "Knowledge is accumulated wisdom from past..."   │
│                                                     │
│ 📄 claude/workstreams/housekeeping/KNOWLEDGE.md     │
│    Line 8 • ## Overview                             │
│    "Shared knowledge across all agents in this..."  │
└─────────────────────────────────────────────────────┘
```

---

## Agent Monitor (Planned)

**Purpose:** Monitor running Claude Code agents and their status.

### Features (Planned)

- List running agents
- View agent logs (tail)
- CPU/memory usage
- Start/stop agents
- View current task

---

## Collaboration Inbox (Planned)

**Purpose:** View and respond to inter-agent collaboration requests.

### Features (Planned)

- List pending requests
- Request details with context
- Accept/decline/respond actions
- Request history
- Notifications

---

## Adding a New DevApp

1. Create route: `src/app/bench/(apps)/[app-name]/page.tsx`
2. Add to sidebar: `src/components/bench/AppSidebar.tsx`
3. Add header title: `src/components/bench/Header.tsx`
4. Update dashboard: `src/app/bench/page.tsx`
5. Document in this file

---

## Tech Stack per DevApp

| Layer | Technology |
|-------|------------|
| UI | React + Tailwind |
| State | React hooks (useState, useEffect) |
| Data | Tauri commands or REST API |
| Storage | SQLite via Drizzle (when needed) |
| Markdown | react-markdown + remark-gfm |
