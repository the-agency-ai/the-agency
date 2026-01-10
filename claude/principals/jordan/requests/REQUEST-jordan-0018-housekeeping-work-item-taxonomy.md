# REQUEST-jordan-0018: Work Item Taxonomy & Tooling

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Open - Design Discussion

**Priority:** High

**Created:** 2026-01-10 15:45 SST

## Summary

Establish a clear taxonomy for work items in The Agency and build tooling to guide and enforce the workflow patterns.

---

## What We Know

### REQUEST is the primary work item

A REQUEST goes through stages:

```
1. impl     - Implementation complete, tested locally
2. review   - Code review complete, fixes applied
3. tests    - Test review complete, improvements applied
4. complete - All phases done, ready for release
```

### Tags connect to stages

```
REQUEST-jordan-0017-impl       # After step 3 (commit & tag)
REQUEST-jordan-0017-review     # After step 6 (commit & tag)
REQUEST-jordan-0017-tests      # After step 9 (commit & tag)
REQUEST-jordan-0017-complete   # Final tag
v0.6.0                         # Release version
```

### The Workflow (from CLAUDE.md)

```
1. Do work
2. Test locally
3. Commit & tag (REQUEST-xxx-impl)
4. Code review (self + agents) → consolidated changes
5. Apply changes
6. Commit & tag (REQUEST-xxx-review)
7. Test review (self + agents) → consolidated test improvements
8. Apply test changes
9. Commit & tag (REQUEST-xxx-tests)
10. Cut build/release (REQUEST-xxx-complete + vX.Y.Z)
```

---

## Questions to Resolve

### 1. Other Work Item Types

Besides REQUEST, what else do we need?

| Type | Use Case | Status |
|------|----------|--------|
| `REQUEST-` | Work from principals | Active |
| `ADHOC-` | Unplanned work | Keep? |
| `BUG-` | Bug fixes | Keep? |
| `PRD-` | Product requirements | Keep? |
| `INSTR-` | Instructions | Deprecated (none exist) |

**Proposal**: Keep it simple for now:
- `REQUEST-` for all principal-driven work
- `BUG-` for bug fixes (could be a REQUEST type?)
- `ADHOC-` for unplanned work (logged in ADHOC-WORKLOG.md)

### 2. Collections (WORKLIST)

Do we need a way to group items?

```
WORKLIST-tech-debt-q1
├── BUG-0001
├── BUG-0002
└── REQUEST-jordan-0015
```

Or just use tags/labels?

### 3. PRD and Product Planning

Future question: How do PRDs relate to REQUESTs?

```
PRD-0001 (Secret Service)
├── REQUEST-jordan-0017 (Core service)
├── REQUEST-jordan-0019 (CLI tool)
└── REQUEST-jordan-0020 (AgencyBench UX)
```

---

## Tooling Needed

### Phase 1: Core Tools

#### `tools/tag`
Create properly formatted tags.
```bash
./tools/tag REQUEST-jordan-0017 impl      # REQUEST-jordan-0017-impl
./tools/tag REQUEST-jordan-0017 review    # REQUEST-jordan-0017-review
./tools/tag REQUEST-jordan-0017 complete  # REQUEST-jordan-0017-complete
./tools/tag release 0.6.0                 # v0.6.0
```

#### `tools/commit`
Create commits with proper format.
```bash
./tools/commit "feat: add encryption" REQUEST-jordan-0017
# Output:
# workstream/agent: feat: add encryption
#
# REQUEST-jordan-0017
# Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

#### `tools/release`
Cut releases with changelog.
```bash
./tools/release 0.6.0
# - Creates v0.6.0 tag
# - Generates changelog from commits since last release
# - Creates GitHub release
# - Marks related REQUESTs as complete
```

### Phase 2: Validation

#### Update `tools/code-review`
- Verify commits reference work items
- Check tag format
- Warn if working tree not clean

#### `tools/workflow-check`
Verify we're following the workflow.
```bash
./tools/workflow-check REQUEST-jordan-0017
# ✓ impl tag exists
# ✓ review tag exists
# ✗ tests tag missing
# → Next: Complete test review and tag
```

---

## Implementation Plan

### Phase 1: Document the Pattern
- [x] Add Development Workflow to CLAUDE.md
- [x] Document tagging convention in CLAUDE.md
- [x] Create this REQUEST as the design doc

### Phase 2: Build Core Tools
- [x] `tools/tag` - Tag creation helper
- [x] `tools/commit` - Commit creation helper
- [x] `tools/release` - Release automation

### Phase 3: Build Validation
- [ ] Update `tools/code-review`
- [ ] `tools/workflow-check`

---

## Activity Log

### 2026-01-10 16:30 SST - Phase 1 & 2 Complete
- Created `tools/tag` for stage tagging (impl, review, tests, complete)
- Created `tools/commit` for formatted commits with work item refs
- Created `tools/release` for release automation with changelog
- Updated CLAUDE.md with Work Items section documenting:
  - Work item types (REQUEST, BUG, ADHOC)
  - REQUEST stages and tagging convention
  - Tool usage examples
- Historical tags left in place (pre-fix, post-fix, phase1, pre-review)
- New tags going forward use standard stages

### 2026-01-10 15:45 SST - Created
- Request created to establish work item taxonomy
- Simplified to focus on REQUEST workflow
- Identified core tooling needs
