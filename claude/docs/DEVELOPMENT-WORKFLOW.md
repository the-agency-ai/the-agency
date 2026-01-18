# Development Workflow Guide

This guide provides a complete example of the Red-Green development cycle with actual commands.

## Overview

Every work item (REQUEST, Phase, Task, Iteration, Sprint) follows the same cycle:

```
Implementation → Code Review + Security Review → Test Review → Complete
     ↓                    ↓                           ↓            ↓
   GREEN               GREEN                       GREEN        TAG
   COMMIT              COMMIT                      COMMIT
   TAG                 TAG                         TAG
```

## Example: REQUEST-jordan-0065

### Phase 1: Implementation

```bash
# 1. Write code and tests
# ... make changes ...

# 2. Run tests - must be GREEN
./tools/test-run
# Output: All tests passed

# 3. Commit using the commit tool
./tools/commit "add Red-Green development cycle docs" \
  --work-item REQUEST-jordan-0065 \
  --stage impl \
  --body "Updated CLAUDE.md with explicit workflow documentation including:
- Multi-agent review process (2+ code, 1+ security, 2+ test)
- Commit/tag table for all work item types
- Code review process clarification"

# 4. Tag implementation complete
./tools/tag REQUEST-jordan-0065 impl
```

### Phase 2: Code Review + Security Review

```bash
# 1. Spawn code review subagents (2+ parallel)
# In Claude Code, use Task tool with subagent_type="general-purpose"

# Subagent 1 prompt:
"Review the code changes in REQUEST-jordan-0065. Focus on:
- Code quality and maintainability
- Error handling
- API design patterns
- Performance considerations
Return a numbered list of issues with file:line references."

# Subagent 2 prompt:
"Review the code changes in REQUEST-jordan-0065. Focus on:
- Architecture and design patterns
- Code organization
- Documentation completeness
- Edge cases
Return a numbered list of issues with file:line references."

# 2. Spawn security review subagent (1+)

# Security subagent prompt:
"Security review of REQUEST-jordan-0065 changes. Check for:
- Input validation vulnerabilities
- Injection risks (SQL, command, XSS)
- Authentication/authorization issues
- Secrets handling
- Path traversal risks
Return findings with severity (Critical/High/Medium/Low) and CWE IDs."

# 3. Wait for all subagents to complete

# 4. Consolidate findings into single list
# - Deduplicate similar findings
# - Prioritize by severity
# - Create modification plan

# 5. Apply all changes (do NOT apply piecemeal)
# ... make changes ...

# 6. Run tests - must be GREEN
./tools/test-run

# 7. Commit using the commit tool
./tools/commit "apply code review findings" \
  --work-item REQUEST-jordan-0065 \
  --stage review \
  --body "Applied consolidated review findings:
- Fixed issue 1: description
- Fixed issue 2: description
- Security fix: description"

# 8. Tag review complete
./tools/tag REQUEST-jordan-0065 review
```

### Phase 3: Test Review

```bash
# 1. Spawn test review subagents (2+ parallel)

# Test review subagent 1 prompt:
"Review tests for REQUEST-jordan-0065. Identify:
- Missing test cases for new functionality
- Edge cases not covered
- Error scenarios not tested
- Integration test gaps
Return a list of tests to add with descriptions."

# Test review subagent 2 prompt:
"Review tests for REQUEST-jordan-0065. Focus on:
- Security test coverage (injection, auth, validation)
- Boundary condition tests
- Negative test cases
- Test quality and assertions
Return a list of test improvements needed."

# 2. Wait for all subagents to complete

# 3. Consolidate findings
# - Merge test recommendations
# - Prioritize critical coverage gaps
# - Include all security tests identified

# 4. Apply test changes
# ... add/modify tests ...

# 5. Run tests - must be GREEN
./tools/test-run

# 6. Commit using the commit tool
./tools/commit "add tests from review findings" \
  --work-item REQUEST-jordan-0065 \
  --stage tests \
  --body "Added tests from consolidated test review:
- Test 1: description
- Test 2: security test for X
- Test 3: edge case coverage"

# 7. Tag tests complete
./tools/tag REQUEST-jordan-0065 tests
```

### Phase 4: Complete

```bash
# Tag work item complete (no commit needed)
./tools/tag REQUEST-jordan-0065 complete

# If this is a release point:
./tools/release 1.3.0 --push --github
```

## Commit Message Format

**With Work Item (preferred):**
```
{WORK-ITEM} - {WORKSTREAM}/{AGENT} for {PRINCIPAL}: {SHORT SUMMARY}

{body}

Stage: {impl | review | tests}
Generated-With: Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

**Without Work Item (simple commits):**
```
{WORKSTREAM}/{AGENT}: {SHORT SUMMARY}

{body}

Generated-With: Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

**Examples:**
```
REQUEST-jordan-0065 - housekeeping/captain for jordan: add Red-Green workflow docs
SPRINT-web-2026w03 - web/frontend for jordan: complete sprint deliverables
housekeeping/captain: update README formatting
```

**Using ./tools/commit:**
```bash
# With work item
./tools/commit "add Red-Green workflow docs" --work-item REQUEST-jordan-0065 --stage impl

# With body
./tools/commit "fix path traversal" --work-item BUG-0042 --stage review \
  --body "Sanitized user input before file operations"

# Simple commit (no work item)
./tools/commit "update README formatting"
```

## Key Rules

1. **Never commit on RED** - Tests must pass before every commit
2. **Never apply piecemeal** - Consolidate all findings before making changes
3. **Always tag after commit** - Tags mark milestones in the workflow
4. **Document in work item** - Update the REQUEST file after each phase
5. **Security in every phase** - Security review in code phase, security tests in test phase

## Subagent Minimums

| Phase | Subagent Type | Minimum Count |
|-------|---------------|---------------|
| Code Review | Code reviewer | 2 |
| Code Review | Security reviewer | 1 |
| Test Review | Test reviewer | 2 |

## See Also

- `CLAUDE.md` - Development Cycle section
- `claude/templates/REQUEST.md` - REQUEST template with workflow checklist
