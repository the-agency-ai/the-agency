# REQUEST-jordan-0024: Create Principal Tool

**Requested By:** principal:jordan

**Assigned To:** housekeeping

**Status:** Complete

**Priority:** High

**Created:** 2026-01-10 17:45 SST

**Updated:** 2026-01-20

## Summary

Create `./tools/principal-create` that users run before their first Claude Code session to set up their principal identity.

## Requirements

- [x] Interactive prompts for principal name
- [x] Set AGENCY_PRINCIPAL env variable
- [x] Create principal directory structure
- [x] Add to shell profile (.zshrc, .bashrc)
- [x] Validate principal name format
- [x] Check for existing principal

## Usage

```bash
# First-time project setup
./tools/setup-agency

# Join existing project
./tools/add-principal

# Programmatic (scripts)
./tools/principal-create <name>

# Get current principal
./tools/principal
```

---

## Development Cycle

### 1. Implementation
- [x] Code complete
- [x] Tests written (66 bats tests)
- [x] Local tests passing (GREEN)
- [x] Committed
- [x] Tagged: `REQUEST-jordan-0024-impl`

### 2. Code Review + Security Review
- [x] 2+ code review subagents spawned
- [x] 1+ security review subagent spawned
- [x] Findings consolidated
- [x] Changes applied (trap/RUN_ID timing, input validation, --help flag)
- [x] Local tests passing (GREEN)
- [x] Committed
- [x] Tagged: `REQUEST-jordan-0024-review`

### 3. Test Review
- [x] 2+ test review subagents spawned
- [x] Security tests identified
- [x] Findings consolidated
- [x] Test changes applied (17 new tests)
- [x] Local tests passing (GREEN)
- [x] Committed
- [x] Tagged: `REQUEST-jordan-0024-tests`

### 4. Complete
- [x] Tagged: `REQUEST-jordan-0024-complete`

---

## Work Completed

### Tools Created
| Tool | Purpose |
|------|---------|
| `setup-agency` | First-time project setup (interactive) |
| `add-principal` | Join existing project (interactive) |
| `principal-create` | Programmatic principal creation |
| `principal` | Get current principal |

### Security Fixes
- Input validation (path traversal, command injection, sed metacharacters)
- Trap/RUN_ID timing fix (initialize before trap)
- Early exit trap handling
- myclaude "none" path check fix

### Documentation
- `claude/docs/PRINCIPALS.md` - Comprehensive user guide
- `claude/docs/worknotes/WORKNOTE-principal-tooling.md` - Implementation notes

### Tests
- 66 bats tests covering:
  - Version/help flags
  - Flag recognition
  - Input validation
  - Security (injection prevention)
  - Log service integration
  - Functional tests (directory creation, env var precedence)

---

## Activity Log

### 2026-01-20 - Completed
- Full review workflow completed (impl → review → tests → complete)
- Security fixes applied for input validation and trap timing
- 66 tests passing
- See WORKNOTE-principal-tooling.md for detailed implementation notes

### 2026-01-10 17:45 SST - Created
- Stub created as part of omnibus breakdown
- Quick win - improves onboarding experience
