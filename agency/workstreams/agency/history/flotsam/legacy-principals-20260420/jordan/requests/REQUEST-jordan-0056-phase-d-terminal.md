# REQUEST-jordan-0056: Phase D - Terminal Integration

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** captain
**Status:** Pending
**Priority:** Medium
**Created:** 2026-01-15
**Parent:** REQUEST-jordan-0052
**Blocked By:** REQUEST-jordan-0054

---

## Summary

Enable the Hub Agent to launch into projects in new terminal tabs (macOS + iTerm2).

---

## Context

This is Phase D of REQUEST-0052. A key Hub capability is "launch into project" - opening a new terminal tab, navigating to the project, and starting myclaude.

Platform scope: macOS + iTerm2 only (for now).

---

## Tasks

| ID | Task | Description | Depends On | Status |
|----|------|-------------|------------|--------|
| D1 | Launch into project | Open iTerm tab, cd to project, run myclaude | B2 | Pending |
| D2 | Tab naming | Set tab title/color for launched projects | D1 | Pending |

---

## Deliverables

### D1: Launch Into Project

Hub Agent can:
```
User: "Launch into my-app"
Hub: Opens new iTerm tab, cd ~/my-app, runs ./tools/myclaude housekeeping captain
```

Implementation via AppleScript or iTerm2's Python API.

### D2: Tab Naming

When launching:
- Tab title: "Agency: my-app"
- Tab color: Consistent with project (optional)

---

## Success Criteria

- [ ] Hub can launch into any registered project
- [ ] New tab opens in iTerm2
- [ ] Tab is properly named
- [ ] myclaude starts in the project

---

## Work Log

### 2026-01-15

- Created REQUEST from REQUEST-0052 Phase D
