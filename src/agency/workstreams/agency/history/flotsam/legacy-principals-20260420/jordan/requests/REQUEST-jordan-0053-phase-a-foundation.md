# REQUEST-jordan-0053: Phase A - Foundation

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** captain
**Status:** Complete
**Priority:** High
**Created:** 2026-01-15
**Parent:** REQUEST-jordan-0052

---

## Summary

Build the foundation infrastructure for the Agency Hub system: manifest schema, registry schema, project registry, and service checks.

---

## Context

This is Phase A of REQUEST-0052 (Agency Manifest and Agent-Driven Updates). These are the foundational pieces that everything else builds on.

---

## Tasks

| ID | Task | Description | Depends On | Status | Commit |
|----|------|-------------|------------|--------|--------|
| A1 | Manifest Schema | Create `.agency/manifest.json` schema | - | Done | 86ba7ce |
| A2 | Registry Schema | Create `registry.json` schema for starter | - | Done | 86ba7ce |
| A3 | Project Registry | Create `.agency/projects.json` schema (local, gitignored) | - | Done | 86ba7ce |
| A4 | Update project-create | Generate manifest + register project on creation | A1, A3 | Done | 39086da |
| A5 | Update project-update | Add `--init` for existing projects | A1 | Done | f99368e |
| A6 | Service check | Add service check to `myclaude` | - | Done | cda8f39 |

### Parallelization

```
Parallel Wave 1:        A1, A2, A3, A6  (4 tasks)
                              ↓
Parallel Wave 2:           A4, A5       (2 tasks, after A1/A3)
```

---

## Deliverables

### A1: Manifest Schema

Location: `.agency/manifest.json` (in each project)

```json
{
  "schema_version": "1.0",
  "project": {
    "name": "string",
    "created_at": "ISO8601",
    "starter_version": "string"
  },
  "source": {
    "type": "local|github",
    "path": "string (if local)",
    "repo": "string (if github)"
  },
  "components": {
    "component-name": {
      "version": "string",
      "status": "installed|available|modified",
      "dependencies": "installed|pending|none"
    }
  },
  "files": {
    "relative/path": {
      "hash": "sha256",
      "version": "string",
      "modified": "boolean"
    }
  }
}
```

### A2: Registry Schema

Location: `registry.json` (in the-agency-starter root)

```json
{
  "schema_version": "1.0",
  "starter_version": "string",
  "components": {
    "component-name": {
      "version": "string",
      "description": "string",
      "files": ["glob patterns"],
      "install_hook": "optional command",
      "dependencies": ["other components"]
    }
  }
}
```

### A3: Project Registry Schema

Location: `.agency/projects.json` (in the-agency-starter, gitignored)

```json
{
  "schema_version": "1.0",
  "projects": [
    {
      "name": "string",
      "path": "absolute path",
      "created_at": "ISO8601",
      "starter_version": "string",
      "last_updated": "ISO8601"
    }
  ]
}
```

### A4: project-create Updates

- Generate `.agency/manifest.json` on project creation
- Register project in starter's `.agency/projects.json`
- Run install hooks for components with dependencies

### A5: project-update --init

- Generate manifest for existing projects (no manifest yet)
- Compute file hashes for modification detection
- Register in project registry if not present

### A6: myclaude Service Check

- On launch, check if required services are running
- If not running, offer to start them
- Check: agency-service (if present)

---

## Success Criteria

- [x] Manifest schema defined and documented
- [x] Registry schema defined with component definitions
- [x] Project registry schema defined
- [x] `project-create` creates manifest and registers project
- [x] `project-update --init` works for existing projects
- [x] `myclaude` checks and offers to start services

---

## Work Log

### 2026-01-15

- Created REQUEST from REQUEST-0052 Phase A
- Defined task breakdown and dependencies
- Documented deliverable schemas

**Wave 1 Complete:**
- A1, A2, A3: Created JSON Schema files in `claude/docs/schemas/`
  - `manifest.schema.json` - project manifest structure
  - `registry.schema.json` - starter component registry
  - `projects.schema.json` - project tracking list
  - Also created actual `registry.json` with component definitions
  - Commit: 86ba7ce
- A6: Added `check_services()` to myclaude
  - Interactive prompts for Bun, dependencies, service start
  - Quiet-by-default pattern
  - Commit: cda8f39

**Wave 2 Started:**
- Created foundation-alpha agent for A4
- Created foundation-beta agent for A5
- Created COLLABORATE-0001 and COLLABORATE-0002
- Agents working in parallel

**Issue Discovered:**
- AGENTNIT-0001: Agents don't auto-check for pending collaborations on launch
- Workaround: Manually prompt agents to check collaborations

**Wave 2 Complete:**
- A4: foundation-alpha implemented manifest generation in project-create
  - Commit: 39086da
  - Generates .agency/manifest.json with component tracking
  - Registers projects in .agency/projects.json
  - Runs install hooks
- A5: foundation-beta implemented --init in project-update
  - Commit: f99368e
  - Generates manifest for existing projects
  - Computes SHA256 file hashes (356 files)
  - Detects modifications vs starter

**Additional Issues Discovered:**
- AGENTNIT-0002: Need message checking during work
- AGENTNIT-0003: Agent identity confusion in tools

**Fixes Applied During Phase A:**
- Session-start hook now checks news + collaborations
- Permissions fixed for coordination tools (news-post, etc.)
- Added knowledge doc: claude/knowledge/claude-code-startup-behavior.md

**Phase A Complete:** All 6 tasks done, all success criteria met.
