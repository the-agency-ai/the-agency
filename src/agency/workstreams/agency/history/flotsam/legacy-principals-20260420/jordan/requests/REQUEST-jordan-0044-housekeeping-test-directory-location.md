# REQUEST-jordan-0044: Fix Test Directory Location

**Principal:** Jordan
**Workstream:** housekeeping
**Agent:** housekeeping
**Status:** Complete
**Created:** 2026-01-13
**Priority:** Medium

---

## Summary

Fix the test directory location bug where test tools create directories inside the-agency repository instead of in a sibling directory.

---

## Problem

Test tools are creating test directories in the wrong location:

**Current (WRONG):**
```
the-agency/
├── tools/
├── claude/
└── test/                    # Tests running INSIDE the repo
    └── starter-test-run/
```

**Expected (CORRECT):**
```
parent-directory/
├── the-agency/
│   ├── tools/
│   └── claude/
├── the-agency-starter/
└── test/                    # Tests running as SIBLING to repos
    └── starter-test-run/
```

## Root Cause

The `PROJECT_ROOT` variable points to the-agency directory, and test directories are created relative to it:

```bash
# Current (wrong)
TEST_DIR="$PROJECT_ROOT/test/starter-test-run"

# Correct
TEST_DIR="$(dirname "$PROJECT_ROOT")/test/starter-test-run"
```

---

## Files to Fix

| File | Line | Change |
|------|------|--------|
| `tools/starter-test` | 34 | `$PROJECT_ROOT/test/` → `$(dirname "$PROJECT_ROOT")/test/` |
| `tools/starter-test-cleanup` | 14 | `$PROJECT_ROOT/test/` → `$(dirname "$PROJECT_ROOT")/test/` |
| `tools/verify-starter` | 30 | `$PROJECT_ROOT/test/` → `$(dirname "$PROJECT_ROOT")/test/` |

---

## Implementation

### Fix Pattern

Replace:
```bash
TEST_DIR="$PROJECT_ROOT/test/starter-test-run"
```

With:
```bash
TEST_DIR="$(dirname "$PROJECT_ROOT")/test/starter-test-run"
```

### Verification

After fix:
```bash
# Run tests with --keep to preserve artifacts
./tools/starter-test --local --keep

# Verify test directory is in sibling location
ls -la ../test/starter-test-run/
```

---

## Related Work

- **REQUEST-jordan-0041** - Public release preparation (where this was discovered)
- `tools/starter-test` - Main test runner (45 tests)
- `tools/starter-test-cleanup` - Cleanup utility
- `tools/verify-starter` - Verification tool

---

## Work Log

### 2026-01-13

**Initial Creation:**
- Created REQUEST document
- Identified 3 files with the bug
- Documented fix pattern

**Fix Applied:**
- Fixed `tools/starter-test` line 34
- Fixed `tools/starter-test-cleanup` line 14
- Fixed `tools/verify-starter` line 30

All three files now use `$(dirname "$PROJECT_ROOT")/test/` instead of `$PROJECT_ROOT/test/`.

---

**Status:** Complete - all 3 files fixed.
