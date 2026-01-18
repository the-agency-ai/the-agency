# REQUEST-jordan-0068: Full Codebase Review

**Status:** Ready
**Priority:** High
**Requested By:** jordan
**Assigned To:** captain
**Workstream:** housekeeping
**Created:** 2026-01-18
**Related:** REQUEST-jordan-0067 (Tool Run Telemetry - provides context for changes)

## Summary

Comprehensive implementation, security, and test review of the full codebase with particular focus on recent changes from REQUEST-0067 (Tool Run Telemetry).

## Goals

1. **Implementation Review** - Verify code quality, patterns, and correctness
2. **Security Review** - Identify vulnerabilities, injection risks, secret exposure
3. **Test Review** - Improve test coverage, quality, and reliability
4. **Red-Green Validation** - Ensure all tests pass after each change

## Scope

### Tools (`./tools/`)
- 93+ bash tools
- Focus areas: tools modified in REQUEST-0067 (`_log-helper`, `commit-precheck`, `tag`, `opportunities`, `log-tool-use`)
- High-risk tools: `secret`, `commit`, `sync`, `myclaude`, `project-new`

### Services (`source/services/agency-service/`)
- TypeScript agency-service
- Focus areas: log-service (modified in REQUEST-0067), API endpoints, database operations
- New endpoints: opportunity detection analytics

### Tests
- Existing vitest suite for services
- New bats-core suite for tools (`tests/tools/`)
- Integration tests

## Review Structure

### Phase 1: Implementation + Security Review

**Subagents 1-2: Tools Review**
- Review all 93+ tools in `./tools/`
- Focus on REQUEST-0067 changes: `_log-helper`, `commit-precheck`, `tag`, `opportunities`, `log-tool-use`
- High-risk tools: secret management, git operations, shell execution
- Check for: command injection, path traversal, improper quoting, race conditions

**Subagents 3-4: Services Review**
- Review `source/services/agency-service/`
- Focus on REQUEST-0067 changes: log-service types, repository, service, routes
- Check for: SQL injection, auth bypass, input validation, error handling

### Phase 2: Test Review

**Subagents 5-6: Tools Test Review**
- Review and expand `tests/tools/*.bats`
- Ensure coverage for all public tool functions
- Add edge case and error path tests
- Focus on testing REQUEST-0067 tool changes

**Subagents 7-8: Services Test Review**
- Review and expand vitest tests
- Add tests for new opportunity detection endpoints
- Ensure repository methods have coverage
- Test edge cases and error handling

## Acceptance Criteria

### Phase 1 Complete
- [ ] All tools reviewed (implementation + security)
- [ ] All services reviewed (implementation + security)
- [ ] Findings documented and consolidated
- [ ] Critical/High issues fixed
- [ ] Tests still GREEN
- [ ] Committed and tagged: `REQUEST-jordan-0068-phase1`

### Phase 2 Complete
- [ ] Tools test coverage expanded
- [ ] Services test coverage expanded
- [ ] Test quality improved
- [ ] All tests GREEN
- [ ] Committed and tagged: `REQUEST-jordan-0068-phase2`

### Complete
- [ ] Tagged: `REQUEST-jordan-0068-complete`
- [ ] Tool opportunity analysis reviewed (cross-ref REQUEST-0067 Phase C data)

## Methodology

### Red-Green Pattern
1. Run tests before any changes - must be GREEN
2. Make changes based on review findings
3. Run tests - must return to GREEN before commit
4. Never commit on RED

### Review Checklist - Tools

**Implementation:**
- [ ] Proper error handling (set -euo pipefail)
- [ ] Consistent argument parsing
- [ ] Help and version flags
- [ ] Clean exit codes
- [ ] Proper logging integration

**Security:**
- [ ] No command injection (proper quoting)
- [ ] No path traversal
- [ ] No hardcoded secrets
- [ ] Proper input validation
- [ ] Safe temp file handling

### Review Checklist - Services

**Implementation:**
- [ ] Type safety (no `any` types)
- [ ] Proper error handling
- [ ] Consistent API patterns (explicit operations)
- [ ] Database query efficiency
- [ ] Logging and observability

**Security:**
- [ ] Input validation (zod schemas)
- [ ] SQL injection prevention (parameterized queries)
- [ ] Authentication/authorization
- [ ] No secret leakage
- [ ] Safe file operations

## Files Changed in REQUEST-0067 (Priority Review)

### New Files
- `tools/opportunities` - CLI for opportunity analytics
- `tools/log-tool-use` - PostToolUse hook handler
- `tests/tools/test_helper.bash` - Test framework
- `tests/tools/log-helper.bats` - _log-helper tests
- `tests/tools/opportunities.bats` - opportunities tests

### Modified Files
- `tools/_log-helper` - Fixed args format, userType, added output capture
- `tools/commit-precheck` - Removed duplicate start_run
- `tools/tag` - Fixed log_start order
- `source/services/agency-service/src/embedded/log-service/types.ts`
- `source/services/agency-service/src/embedded/log-service/repository/log.repository.ts`
- `source/services/agency-service/src/embedded/log-service/service/log.service.ts`
- `source/services/agency-service/src/embedded/log-service/routes/log.routes.ts`
- `.claude/settings.json` - Added log-tool-use to PostToolUse hook

## Post-Review: Tool Opportunity Analysis

After collecting sufficient usage data (post-review), analyze:
- High output commands that waste context tokens
- Frequent patterns that could be wrapped
- Failure patterns that need auto-handling
- Large input commands that need optimization

This analysis may generate additional REQUESTs for new tool development.

---

## Activity Log

### 2026-01-18 - Phase 2: Test Review Complete

**Test Review Agents:**
- Agent a195d63: Tools tests (bats + TypeScript)
- Agent a06314a: agency-service tests

**Critical Findings:**
1. **log-service has ZERO tests** - New REQUEST-0067 service with FTS5, tool runs, analytics completely untested
2. **product-service has ZERO tests**
3. ~95 tools exist but only 5 have any tests (2 bats, 3 TypeScript)

**High Priority Findings:**
1. Hardcoded ports (3198, 3199) in mock server tests - can cause port conflicts
2. `opportunities.bats` uses weak assertions - checks absence of error text, not exit codes
3. `log-helper.bats` only tests disabled logging mode (LOG_SERVICE_URL="")
4. `requests.test.ts` ID normalization tests pass on either success or specific error messages

**Medium Priority Findings:**
1. No concurrent access tests for request sequence number generation
2. No boundary condition tests (long strings, large batches)
3. Test isolation could use unique paths with timestamps/UUIDs
4. requests-backfill.test.ts uses fixed 30s timeout that could be flaky in CI

**Fix Plan:**
1. Create log-service tests (repository, service, routes)
2. Strengthen opportunities.bats assertions
3. Add enabled-logging tests to log-helper.bats
4. Document as future work: port randomization, concurrent tests

### 2026-01-18 - Phase 1: Implementation + Security Review Complete

**Security Fixes Applied:**
1. `log-tool-use`: Fixed jq command injection (--argjson → --arg)
2. `log.repository.ts`: Fixed FTS5 MATCH injection with quote escaping
3. `log.routes.ts`: Added safeParseInt helper with bounds checking

**Findings Summary:**
- 1 Critical (JWT bypass - documented as intentional for local use)
- 0 High
- 11 Medium (3 fixed, 8 documented as acceptable or future work)
- 32 Low (documentation, minor improvements)

**Tagged:** `fbef274` (pre-tag commit)

### 2026-01-18 - Created
- Request created to formalize full codebase review
- Cross-references REQUEST-0067 for context on recent changes
- Test infrastructure verified working (25 bats tests passing)

