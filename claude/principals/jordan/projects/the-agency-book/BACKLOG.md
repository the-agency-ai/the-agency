# The Agency — Complete Backlog

**Updated:** 2026-01-06
**Principal:** jordan

---

## Summary

| Category | Count | Status |
|----------|-------|--------|
| Workshop Critical | 6 | 🔴 In Progress |
| Book Critical | 8 | 🔴 Pending |
| Framework Props | 17 | Draft |
| Book Polish | 4 | 🟡 Reviewed |
| Philosophy | 1 | ✅ Accepted |

---

## Tier 1: Workshop Critical (Fri Jan 9 14:00)

| ID | Item | Owner | Status |
|----|------|-------|--------|
| W-1 | Verify install.sh end-to-end | housekeeping | 🟡 |
| W-2 | Test /welcome flow | housekeeping | 🔴 |
| W-3 | Verify AGENCY_TOKEN clone | housekeeping | 🔴 |
| W-4 | Create slides (~8-10) | jordan+opus | 🔴 |
| W-5 | Finalize pre-work email | jordan | 🟡 |
| W-6 | Dry run workshop flow | housekeeping | 🔴 |

---

## Tier 2: Book Critical (Before Publish)

| ID | Item | Owner | Status | Source |
|----|------|-------|--------|--------|
| B-1 | init-agency tool | housekeeping | 🔴 | Ch4 review |
| B-2 | Starter repo accessible | jordan | 🔴 | WORKING-NOTE-0018 |
| B-3 | Real Yak Shaving example | jordan | 🔴 | Ch1 placeholder |
| B-4 | Real Broken Windows example | jordan | 🔴 | Ch1 placeholder |
| B-5 | Verify install URLs | housekeeping | 🔴 | Ch4 review |
| B-6 | Verify pricing | housekeeping | 🔴 | Ch4 review |
| B-7 | GitHub Discussions | jordan | 🔴 | Appendix C |
| B-8 | Community infrastructure | jordan | 🔴 | Outline |

---

## Tier 3: Framework Proposals (PROP-XXXX)

### Philosophy (Accepted)

| ID | Title | Status | Impact |
|----|-------|--------|--------|
| PROP-0016 | Right Way = Fast Way | ✅ Accepted | Foundational |

### High Priority (Should Build)

| ID | Title | Status | Impact |
|----|-------|--------|--------|
| PROP-0015 | Capture Web Content (CDP) | Draft | Unlocks modern web |
| PROP-0017 | Narrowcast Messages | Draft | Token efficiency |
| PROP-0014 | Knowledge Indexer | Draft | Compounding knowledge |
| PROP-0006 | Distribution Structure | Draft | Starter architecture |
| PROP-0001 | Tool Ecosystem (dist/local) | Draft | Tool organization |

### Medium Priority (Nice to Have)

| ID | Title | Status | Impact |
|----|-------|--------|--------|
| PROP-0011 | Workbench | Draft | Internal tooling |
| PROP-0010 | Pricing Model | Draft | Business model |
| PROP-0012 | Open Feedback Service | Draft | User feedback |
| PROP-0002 | Work Lifecycle Tools | Draft | Sprint management |
| PROP-0003 | Context Stack | Draft | Context management |

### Lower Priority (Future)

| ID | Title | Status | Impact |
|----|-------|--------|--------|
| PROP-0004 | Hello World Project | Draft | Example project |
| PROP-0005 | Path Resolution | Draft | Tool utility |
| PROP-0007 | Session Capture Book | Draft | Documentation |
| PROP-0008 | Markdown Manager | Draft | Content tooling |
| PROP-0009 | Proposal System | Draft | Meta/process |
| PROP-0013 | Open Webpage Tool | Draft | Superseded by 0015? |

---

## Tier 4: Book Polish

| ID | Item | Owner | Status | Source |
|----|------|-------|--------|--------|
| P-1 | Chapter 4 revisions | housekeeping | 🟡 | Review feedback |
| P-2 | Chapter 1 revisions | housekeeping | 🟡 | Review feedback |
| P-3 | Outline updates | housekeeping | 🟡 | Review feedback |
| P-4 | Chapter 10 Workbench scope | jordan | 🔴 | Review feedback |

---

## Review Feedback Summary

### Outline (v4)
- Clarify Christmas = Claude Desktop, not Code
- Chapter 10 Workbench scope unclear
- Missing PROP-0015 in requirements
- Boris Cherny validation for Ch12

### Chapter 1 (v3)
- ✅ Opening hook approved
- Consider "becoming the practitioner" wording
- Verify pricing before publish
- 🔴 Yak Shaving example is PLACEHOLDER
- 🔴 Broken Windows example is PLACEHOLDER
- Add Boris parallel validation
- Emphasize session persistence differentiator

### Chapter 4 (v1)
- Verify pricing
- Verify "Claude Console" product name
- ✅ Terminal requirement well-explained
- Verify install URLs
- 🔴 Starter repo must exist
- 🔴 init-agency must exist
- Specify timezone config location
- Verify sync --dry-run flag
- GitHub Discussions must exist

---

## Dependencies Graph

```
Workshop (Fri 14:00)
├── W-1: install.sh works
├── W-2: /welcome works
├── W-3: Token works
├── W-4: Slides exist
└── W-5: Pre-work sent

Book Launch
├── B-2: Repo accessible
│   └── W-3: Token works (or public)
├── B-1: init-agency
├── B-5, B-6: URLs/pricing verified
├── B-3, B-4: Real examples
└── B-7, B-8: Community

Framework Evolution
├── PROP-0016: Philosophy (✅)
├── PROP-0015: CDP capture
├── PROP-0017: Narrowcast
├── PROP-0014: Knowledge indexer
└── PROP-0006: Distribution
```

---

## Prioritized Execution Order

### This Week (Before Workshop)
1. W-1 through W-6 (workshop critical)
2. B-1 init-agency (if time)

### Next Week (Book Polish)
1. B-3, B-4 (real examples from Jordan)
2. B-5, B-6 (URL/pricing verification)
3. P-1, P-2 (chapter revisions)

### Following Weeks (Framework)
1. PROP-0015 (CDP capture)
2. PROP-0014 (Knowledge indexer)
3. PROP-0017 (Narrowcast)
4. B-7, B-8 (Community)

---

_Complete backlog for The Agency project_
_Updated 2026-01-06_
