# PROP-0008: Markdown Manager

**Status:** draft
**Priority:** high
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

Managing markdown files across The Agency is cumbersome:
1. No unified view of all documentation
2. Switching between editor and preview
3. No collaborative review mechanism
4. No versioning beyond git
5. Can't easily share with non-technical stakeholders

## Proposal

A web application for markdown creation, editing, and management.

### Product Vision

**Local first → Self-hosted → Cloud (multi-tenant)**

Phase 1: Local web app running on developer's machine
Phase 2: Self-hosted option for teams
Phase 3: Cloud deployment with auth, multi-tenant

### Core Features

#### V1 (Local)

| Feature | Description |
|---------|-------------|
| File Browser | Navigate markdown files in project |
| Dual View | Side-by-side markdown + preview |
| Rich Preview | Rendered markdown with syntax highlighting |
| Basic Edit | Edit markdown in browser |
| Search | Full-text search across files |

#### V2 (Review System)

| Feature | Description |
|---------|-------------|
| Block Comments | Select text, add reviewer comment |
| Comment Format | `[(reviewer) comment text]` inline |
| Comment Sidebar | List of all comments |
| Resolve Comments | Mark comments as resolved |

**Comment Pattern:**
```markdown
[(jordan) This paragraph needs work on clarity]
[(jordan) Consider: "The agent orchestrates tools" instead]
```

#### V3 (Versioning)

| Feature | Description |
|---------|-------------|
| Versions | Save named versions |
| Compare | Diff between versions |
| Publish | Export clean version (comments stripped) |
| History | View version timeline |

#### V4 (Claude Integration)

| Feature | Description |
|---------|-------------|
| Add to Chat | Send document to Claude Desktop |
| Project Knowledge | Add to Claude project knowledge |
| AI Review | Request AI review of document |
| AI Suggestions | Get writing suggestions |

### Architecture

```
┌─────────────────────────────────────┐
│         Markdown Manager UI          │
│         (Next.js / React)            │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│       Markdown Manager Service       │
│           (Nitro API)                │
├─────────────────────────────────────┤
│ - File operations                    │
│ - Comment management                 │
│ - Version control                    │
│ - Search index                       │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│          Storage Layer               │
│  Local: Filesystem                   │
│  Cloud: Supabase / S3                │
└─────────────────────────────────────┘
```

### Claude Desktop Integration

Via MCP Server (extends existing agency-server):

```typescript
// New tools for agency-server
tools: [
  {
    name: "add_document_to_chat",
    description: "Add a markdown document to current chat",
    parameters: { path: string }
  },
  {
    name: "add_to_project_knowledge",
    description: "Add document to Claude project knowledge",
    parameters: { path: string, project: string }
  }
]
```

### Open Source vs Commercial

| Feature | Open Source (Starter) | Commercial |
|---------|----------------------|------------|
| File browsing | ✓ | ✓ |
| Dual view | ✓ | ✓ |
| Basic editing | ✓ | ✓ |
| Search | ✓ | ✓ |
| Review comments | ✓ | ✓ |
| Versioning | ✓ | ✓ |
| Multi-user | | ✓ |
| Cloud sync | | ✓ |
| Team features | | ✓ |
| Claude integration | | ✓ |
| Priority support | | ✓ |

## Key Points

- Solves real problem we have (managing Agency docs)
- Natural upgrade from Hello World (PROP-0004)
- Product revenue opportunity
- Claude integration is differentiator

## Open Questions

- [ ] Which framework for UI? (Next.js seems natural)
- [ ] How to handle large files?
- [ ] Real-time collaboration (V4+)?
- [ ] Mobile support?

## Dependencies

- Related proposals: PROP-0004 (Hello World)
- Related INSTRs: INSTR-0050 (TheAgency Services)

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: web + housekeeping
- Target: v0.3.0+ (post-initial release)

---

## Discussion Log

### 2026-01-06 - Created
Jordan: "Local web app that provides markdown creation, editing, and management... Has a mechanism for commenting or giving directions where I select a block of text..."
