# REQUEST-jordan-0057: Phase E - Contributor Flow

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

Enable agent-driven upstream contributions: Hub creates PRs, Reviewer Agent reviews, Merger Agent merges.

---

## Context

This is Phase E of REQUEST-0052 - the Minimally Viable Contributor Flow (MVCF). Users who improve The Agency tools can contribute back via agents. The entire contribution lifecycle is agent-driven.

Key dependency: `anthropics/claude-code-action` for GitHub Actions integration.

---

## Tasks

| ID | Task | Description | Depends On | Status |
|----|------|-------------|------------|--------|
| E1 | GitHub Action setup | Add `anthropics/claude-code-action` to the-agency repo | - | Pending |
| E2 | Reviewer workflow | Create workflow triggered on PR | E1 | Pending |
| E3 | Detect modifications | Hub identifies modified framework files | B2, A1 | Pending |
| E4 | Create upstream PR | Hub forks, branches, commits, creates PR via gh | E3 | Pending |
| E5 | Check PR status | Hub shows status of open contributions | E4 | Pending |
| E6 | Merger workflow | Workflow triggered on approval to merge | E1 | Pending |

**Note:** E1 and E2 can start immediately (independent of Hub).

---

## Deliverables

### E1: GitHub Action Setup

```yaml
# .github/workflows/claude-review.yml
name: Claude Code Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### E2: Reviewer Agent Workflow

Claude automatically:
- Reviews PR changes
- Posts feedback as comments
- Requests changes or approves

### E3-E5: Hub Contribution Commands

```
User: "I improved the collaborate tool, contribute it upstream"
Hub: Detects modified files, creates fork, branch, PR

User: "Check my PR status"
Hub: Shows open PRs, their review status, any requested changes
```

### E6: Merger Workflow

On approval:
- Run final checks
- Auto-merge if passing
- Notify contributor

---

## Success Criteria

- [ ] `anthropics/claude-code-action` configured in the-agency repo
- [ ] PRs trigger automatic Claude review
- [ ] Hub can detect modified framework files
- [ ] Hub can create upstream PRs
- [ ] Hub can check PR status
- [ ] Approved PRs auto-merge

---

## Work Log

### 2026-01-15

- Created REQUEST from REQUEST-0052 Phase E
