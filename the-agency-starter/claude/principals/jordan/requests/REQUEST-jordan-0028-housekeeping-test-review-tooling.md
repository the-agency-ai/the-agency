# REQUEST-jordan-0028: Test Review Tooling

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Open

**Priority:** Medium

**Created:** 2026-01-10 17:45 SST

## Summary

Tooling to support the test review convention (already documented in CLAUDE.md). Similar to code review tooling but focused on test coverage and quality.

## Requirements

### Phase 1: Capture Tool
- [ ] `./tools/test-review` triggers review
- [ ] Captures test coverage gaps
- [ ] Identifies missing test cases
- [ ] Links to REQUEST being reviewed

### Phase 2: Parallel Reviews
- [ ] Support multiple reviewers (agents)
- [ ] Track review status per reviewer
- [ ] Merge findings

### Phase 3: Consolidation
- [ ] Deduplicate findings
- [ ] Prioritize test improvements
- [ ] Generate action list
- [ ] Track resolution

### Phase 4: Service Integration
- [ ] Store reviews in agency-service
- [ ] API for retrieval
- [ ] AgencyBench UI

## Current State

Convention exists in CLAUDE.md (impl → review → tests → complete).
Test review happens but findings not persisted.

## Activity Log

### 2026-01-10 17:45 SST - Created
- Stub created as part of omnibus breakdown
- Enhances existing workflow with tooling
