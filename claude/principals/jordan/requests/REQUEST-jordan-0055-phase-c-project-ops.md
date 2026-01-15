# REQUEST-jordan-0055: Phase C - Project Operations

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** captain
**Status:** Complete
**Priority:** High
**Created:** 2026-01-15
**Parent:** REQUEST-jordan-0052
**Blocked By:** REQUEST-jordan-0054

---

## Summary

Enable the Hub Agent to create and update projects - the core operational capabilities.

---

## Context

This is Phase C of REQUEST-0052. With the Hub core in place, we add the ability to create new projects and update existing ones through agent-driven operations.

---

## Tasks

| ID | Task | Description | Depends On | Status | Agent | Commit |
|----|------|-------------|------------|--------|-------|--------|
| C1 | Create project | Hub runs project-new, registers result | B2, A4 | Done | In Hub KNOWLEDGE | - |
| C2 | Update project | Hub updates single project | B2, A5 | Done | In Hub KNOWLEDGE | - |
| C3 | Batch update | Hub updates all registered projects | C2 | Done | foundation-beta | 89b3a5f |
| C4 | Pre-update verify | Check git status, flag modified files | C2 | Done | foundation-beta | 89b3a5f |
| C5 | --check --json | Machine-readable update check for agents | A1 | Done | foundation-alpha | f0de5b2 |

---

## Deliverables

### C1: Create Project

Hub Agent can:
```
User: "Create a new project called my-app"
Hub: Creates ~/my-app, initializes manifest, registers in project registry
```

### C2: Update Single Project

Hub Agent can:
```
User: "Update my-app to latest"
Hub: Runs pre-update checks, applies updates, reports results
```

### C3: Batch Update

Hub Agent can:
```
User: "Update all my projects"
Hub: Iterates through registry, updates each, reports summary
```

### C4: Pre-Update Verification

Before updating, Hub checks:
- Working tree is clean (git status)
- No uncommitted changes to framework files
- Flags which files are modified vs pristine

### C5: --check --json

```bash
./tools/project-update --check --json
```

Output:
```json
{
  "current_version": "1.0.9",
  "latest_version": "1.1.0",
  "updates_available": true,
  "files_to_update": ["tools/collaborate", "tools/news-post"],
  "files_modified_locally": ["tools/myclaude"],
  "breaking_changes": false
}
```

---

## Success Criteria

- [x] Hub can create projects via natural language
- [x] Hub can update individual projects
- [x] Hub can batch update all projects
- [x] Pre-update verification catches issues
- [x] `--check --json` provides agent-consumable output

---

## Work Log

### 2026-01-15

- Created REQUEST from REQUEST-0052 Phase C
- **C1, C2 Complete:** Already documented in Hub Agent's KNOWLEDGE.md during Phase B
  - Create project: Uses `./tools/project-new`
  - Update project: Uses `./tools/project-update`
- Started Phase C execution after Phase B completion
- Created COLLABORATE-0005 for C5 (--check --json) → foundation-alpha
- Created COLLABORATE-0006 for C3+C4 (Hub KNOWLEDGE batch/verify) → foundation-beta
- Posted NEWS-0012 notifying agents of Phase C assignments

**C3+C4 Complete:** foundation-beta enhanced Hub KNOWLEDGE.md
- Commit: 89b3a5f
- Added Pre-Update Verification procedure with checklist
- Added Batch Updating All Projects procedure with Python scripts

**C5 Complete:** foundation-alpha added --check --json to project-update
- Commit: f0de5b2
- --check mode for read-only update checking
- --json flag for machine-readable output

**Phase C Complete:** All success criteria met
