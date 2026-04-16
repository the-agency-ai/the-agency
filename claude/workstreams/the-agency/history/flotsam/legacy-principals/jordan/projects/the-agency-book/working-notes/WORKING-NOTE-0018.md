# THE-AGENCY-BOOK-WORKING-NOTE-0018

**Date:** 2026-01-06 14:30 SGT
**Participants:** jordan (principal), housekeeping (agent)
**Subject:** Publication Blockers - Must Haves Before Launch

---

## Purpose

Consolidated list of items that MUST be complete before book publication. Extracted from housekeeping's review of outline, Chapter 1, and Chapter 4.

---

## Critical Blockers (Cannot Publish Without)

### 1. The Agency Starter Repository

| Item | Status | Notes |
|------|--------|-------|
| **Repo exists and is public** | 🔴 Needed | `https://github.com/the-agency-ai/the-agency-starter.git` |
| **`./tools/init-agency`** | 🔴 Needed | Interactive setup script described in Chapter 4 |
| **All 35+ tools present** | 🔴 Needed | Tools referenced throughout the book |
| **CLAUDE.md template** | 🔴 Needed | The constitution |
| **Directory structure** | 🔴 Needed | agents/, principals/, workstreams/, docs/ |
| **Housekeeping agent template** | 🔴 Needed | `claude/agents/housekeeping/agent.md` |

### 2. Content Placeholders to Replace

| Location | Item | Owner |
|----------|------|-------|
| Chapter 1 | Yak Shaving example (Day 6 storage pattern) | Jordan |
| Chapter 1 | Broken Windows example (Day 4 - "much bigger") | Jordan |

### 3. URLs and References to Verify

| Item | Current Value | Action |
|------|---------------|--------|
| Claude Code install URL | `curl -fsSL https://claude.ai/install.sh \| bash` | Verify against docs |
| Windows install | `irm https://claude.ai/install.ps1 \| iex` | Verify against docs |
| Claude pricing | Pro $20, Max 5x $100, Max 20x $200 | Verify at claude.ai/pricing |
| "Claude Console" product name | May be "Anthropic Console" | Verify correct name |

---

## High Priority (Should Have)

### 4. Community Infrastructure

| Item | Status | Notes |
|------|--------|-------|
| GitHub Discussions enabled | 🟡 Open Issue | Referenced in Appendix C |
| Discord server | 🟡 Open Issue | Referenced in outline |
| Access gating investigation | 🟡 Open Issue | Subscribers-only access? |

### 5. Tool Verification

| Tool | Issue | Action |
|------|-------|--------|
| `./tools/sync --dry-run` | May not exist | Verify or add flag |
| `./tools/now` timezone config | Where to change? | Document location |

### 6. Workbench Scope Decision

| Question | Options |
|----------|---------|
| Which modules in Starter? | Staff Manager, Agent Manager, Content Manager, Pulse Beat, Catalog |
| Minimum viable? | TBD by Jordan |
| Full Project X version? | Likely too much for starter |

---

## Nice to Have (Enhance Quality)

### 7. External Validation References

| Item | Source | Integration Point |
|------|--------|-------------------|
| Boris Cherny parallel instances | WORKING-NOTE-0017 | Chapter 1, Chapter 12 |
| Boris "Plan mode first" | WORKING-NOTE-0017 | Chapter 12 (two-tier) |
| Boris verification loops | WORKING-NOTE-0017 | Chapter 9 (quality) |

### 8. Clarifications

| Item | Issue | Suggestion |
|------|-------|------------|
| Christmas friction points | Readers may confuse Claude Desktop vs Code | Add note clarifying which product |
| "Interviewer" Day 4 | Product name unclear | Add context or rename |
| Prophetic call wording | "building the team" vs "becoming the practitioner" | Consider revision |

---

## Tracking

| Category | Count | Status |
|----------|-------|--------|
| Critical Blockers | 6 items | 🔴 Not started |
| Content Placeholders | 2 items | 🟡 Waiting on Jordan |
| URLs to Verify | 4 items | 🟡 Pre-publication task |
| Community Infrastructure | 3 items | 🟡 Open issues |
| Tool Verification | 2 items | 🟡 Pre-publication task |
| Workbench Decision | 1 item | 🟡 Needs Jordan decision |

---

## Dependencies

```
Book Publication
    ├── Starter Repo Ready
    │   ├── init-agency tool
    │   ├── All tools present
    │   ├── Templates in place
    │   └── Workbench (scoped modules)
    ├── Content Complete
    │   ├── Jordan's real examples
    │   └── All chapters drafted
    ├── Verification Pass
    │   ├── URLs verified
    │   ├── Pricing verified
    │   └── Product names verified
    └── Community Ready (optional for launch)
        ├── GitHub Discussions
        └── Discord
```

---

## Next Actions

1. **Jordan:** Decide Workbench scope for Starter
2. **Jordan:** Provide real examples for Yak Shaving and Broken Windows
3. **Housekeeping:** Create starter repo structure (when approved)
4. **Housekeeping:** Implement `init-agency` tool
5. **Pre-publication:** Verification pass on all URLs and pricing

---

_Working note for project: the-agency-book_
_Extracted from housekeeping review 2026-01-06_
