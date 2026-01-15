# REQUEST-jordan-0055: Phase C - Project Operations

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** captain
**Status:** Pending
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

| ID | Task | Description | Depends On | Status |
|----|------|-------------|------------|--------|
| C1 | Create project | Hub runs project-new, registers result | B2, A4 | Pending |
| C2 | Update project | Hub updates single project | B2, A5 | Pending |
| C3 | Batch update | Hub updates all registered projects | C2 | Pending |
| C4 | Pre-update verify | Check git status, flag modified files | C2 | Pending |
| C5 | --check --json | Machine-readable update check for agents | A1 | Pending |

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

- [ ] Hub can create projects via natural language
- [ ] Hub can update individual projects
- [ ] Hub can batch update all projects
- [ ] Pre-update verification catches issues
- [ ] `--check --json` provides agent-consumable output

---

## Work Log

### 2026-01-15

- Created REQUEST from REQUEST-0052 Phase C
