# REQUEST-jordan-0027: Code Review Tooling

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Complete

**Priority:** Medium

**Created:** 2026-01-10 17:45 SST

## Summary

Tooling to support the code review convention (already documented in CLAUDE.md). Captures findings, supports parallel reviews, and consolidates into actionable list.

## Requirements

### Phase 1: Capture Tool
- [ ] `./tools/code-review` triggers review
- [ ] Captures findings in structured format
- [ ] Links to REQUEST being reviewed

### Phase 2: Parallel Reviews
- [ ] Support multiple reviewers (agents)
- [ ] Track review status per reviewer
- [ ] Merge findings

### Phase 3: Consolidation
- [ ] Deduplicate findings
- [ ] Prioritize issues
- [ ] Generate action list
- [ ] Track resolution

### Phase 4: Service Integration
- [ ] Store reviews in agency-service
- [ ] API for retrieval
- [ ] AgencyBench UI

## Current State

Convention exists in CLAUDE.md (impl → review → tests → complete).
Code review happens via subagent but findings not persisted.

## Activity Log

### 2026-01-20 - Closed
- Verified existing tooling addresses core workflow:
  - `./tools/review-spawn REQUEST code` - triggers code + security reviews
  - `agency/templates/prompts/code-review.md` - reviewer prompt
  - `agency/templates/prompts/security-review.md` - security prompt
  - `agency/templates/prompts/consolidation.md` - merge findings
  - CLAUDE.md documents the full process
- Persistence/tracking deferred to REQUEST-jordan-0066 (Findings Consolidation)

### 2026-01-10 17:45 SST - Created
- Stub created as part of omnibus breakdown
- Enhances existing workflow with tooling
