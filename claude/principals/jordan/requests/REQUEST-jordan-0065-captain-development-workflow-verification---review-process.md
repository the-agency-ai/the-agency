# REQUEST-jordan-0065: Development Workflow Verification - Review Process Tooling and Documentation

**Status:** Complete
**Priority:** High
**Requested By:** jordan
**Assigned To:** captain
**Created:** 2026-01-18
**Updated:** 2026-01-18

## Summary

Verify that we have implemented appropriate tooling, CLAUDE.md guidance, and documentation for our Red-Green development workflow with multi-agent code review, security review, and test review.

## Details

### The Workflow

When completing a Phase, Task, Iteration, Sprint, or Request, we follow this process:

```
┌─────────────────────────────────────────────────────────────────┐
│  1. IMPLEMENTATION COMPLETE                                      │
│     - Code written                                               │
│     - Initial tests written                                      │
│     - Local test run: GREEN                                      │
│     - Commit + Tag: REQUEST-xxx-impl                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  2. CODE REVIEW + SECURITY REVIEW                                │
│     - Launch 2+ code review subagents (parallel)                 │
│     - Launch 1+ security review subagent                         │
│     - Parent agent consolidates findings into modification list  │
│     - Apply code modifications                                   │
│     - Local test run: GREEN                                      │
│     - Commit + Tag: REQUEST-xxx-review                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  3. TEST REVIEW                                                  │
│     - Launch 2+ test review subagents (parallel)                 │
│     - Identify tests to modify or add (including security tests) │
│     - Parent agent consolidates into modification list           │
│     - Apply test modifications                                   │
│     - Local test run: GREEN                                      │
│     - Commit + Tag: REQUEST-xxx-tests                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  4. COMPLETE                                                     │
│     - Tag: REQUEST-xxx-complete                                  │
│     - Release if final phase                                     │
└─────────────────────────────────────────────────────────────────┘
```

### Red-Green Model

- **RED**: Tests fail (expected when adding new tests before implementation)
- **GREEN**: All tests pass (required before any commit)
- We never commit on RED
- Each stage must achieve GREEN before proceeding

### Key Principles

1. **Parallel Subagents**: Use 2+ subagents for diverse perspectives
2. **Consolidation**: Parent agent consolidates findings before applying changes
3. **No Piecemeal Changes**: Gather all feedback, then apply systematically
4. **Security in Every Review**: Security is checked in both code and test reviews
5. **Clean Commits**: Each commit is a logical unit with passing tests
6. **Tags for Milestones**: Tag after each stage for traceability

### What Needs Verification

1. **CLAUDE.md** - Does it clearly document this workflow?
2. **Tools** - Do we have tools to support this workflow?
   - `./tools/code-review` - Does it spawn subagents correctly?
   - `./tools/test-run` - Does it run tests reliably?
   - `./tools/tag` - Does it support our tagging convention?
3. **Templates** - Do we have REQUEST templates that guide this workflow?
4. **Agent Knowledge** - Do agents know to follow this process?

## Acceptance Criteria

- [x] CLAUDE.md clearly documents the Red-Green workflow
- [x] CLAUDE.md specifies subagent counts (2+ code, 1+ security, 2+ test)
- [x] CLAUDE.md explains consolidation before applying changes
- [x] `./tools/code-review` documented as automated checker (not subagent orchestration)
- [x] Security review is explicitly part of the code review phase
- [x] Test review includes security test identification
- [x] Tagging convention documented with commit/tag table
- [x] REQUEST template includes workflow checklist
- [x] Example workflow documented with actual commands

## Deliverables

1. **CLAUDE.md Updates** - Clear workflow documentation if missing
2. **Tool Audit** - Verify tools support the workflow
3. **Gap Analysis** - Identify any missing tools or documentation
4. **Workflow Guide** - Create `claude/docs/DEVELOPMENT-WORKFLOW.md` if needed

## Verification Approach

1. Read current CLAUDE.md and identify gaps
2. Test each tool in the workflow
3. Create checklist of what exists vs. what's needed
4. Implement fixes or document gaps for follow-up

## Work Completed

### 2026-01-20 - Verification Complete

All acceptance criteria verified:
- CLAUDE.md fully documents the Red-Green workflow
- Tools exist and work: code-review, test-run, tag, review-spawn
- Templates exist: code-review.md, security-review.md, test-review.md, consolidation.md
- REQUEST template includes workflow checklist
- DEVELOPMENT-WORKFLOW.md guide exists with full examples

## Follow-Up Notes

**When implementing Iterations, Phases, Tasks, Sprints as formal work item types:**
- Each type will need to follow this same Red-Green workflow
- Templates will be needed for each type (similar to REQUEST.md)
- The `./tools/tag` tool already supports arbitrary prefixes
- Consider whether review stages should be mandatory or optional based on scope

---

## Activity Log

### 2026-01-20 - Complete
- All acceptance criteria verified
- Documentation, tools, and templates confirmed in place
- Added follow-up note for future work item type implementations

### 2026-01-18 - Created
- Request created by jordan
