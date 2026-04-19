# WORKNOTE: Principal Management Tooling

**Date:** 2026-01-20
**REQUEST:** REQUEST-jordan-0024 (+ context from REQUEST-jordan-0030)
**Status:** Complete (all stages)
**Tags:** REQUEST-jordan-0024-impl, REQUEST-jordan-0024-review, REQUEST-jordan-0024-tests, REQUEST-jordan-0024-complete

---

## Executive Summary

Built the principal management tooling that enables human identity management in The Agency. This includes tools for first-time setup, joining existing projects, creating principals programmatically, and detecting the current principal. Integrated with myclaude for seamless onboarding.

**Key Outcome:** New users can set up their principal identity with zero friction, and the system correctly routes first-time setup vs. joining existing projects.

---

## The Problem

Before this work:
- No standardized way to create a principal identity
- "jordan" was hardcoded throughout the starter
- No environment variable for principal identity
- No distinction between first-time setup and joining existing project
- myclaude couldn't detect or route principal-related setup

After:
```
First Run (New Project)
    └─→ myclaude detects .agency-setup-complete missing
    └─→ Triggers setup-agency
    └─→ Interactive prompts (outside Claude Code)
    └─→ Creates first principal
    └─→ Sets AGENCY_PRINCIPAL in shell profile
    └─→ Initializes vault
    └─→ Launches Claude

Join Project (Existing)
    └─→ myclaude detects AGENCY_PRINCIPAL not set
    └─→ Triggers add-principal
    └─→ Creates principal directory from template
    └─→ Sets AGENCY_PRINCIPAL
    └─→ Launches Claude

Programmatic
    └─→ principal-create <name>
    └─→ Creates directory structure
    └─→ Does NOT modify shell (for automation)
```

---

## Implementation

### Tools Created

| Tool | Purpose | Use Case |
|------|---------|----------|
| `setup-agency` | First-time project setup | New project from starter |
| `add-principal` | Add yourself to project | Joining existing project |
| `principal-create` | Programmatic creation | Scripts, automation |
| `principal` | Get current principal | Scripts, other tools |

### myclaude Integration

Updated myclaude to detect and route principal setup:

```bash
# Decision tree in myclaude:
.agency-setup-complete exists?
├─ NO → setup-agency (new project)
└─ YES
    └─ AGENCY_PRINCIPAL set?
        ├─ NO → add-principal (joining project)
        └─ YES
            └─ principals/$AGENCY_PRINCIPAL/ exists?
                ├─ NO → add-principal (create directory)
                └─ YES → Launch Claude
```

### Directory Structure

```
claude/principals/{name}/
├── README.md           # Auto-generated overview
├── requests/           # Work requests (REQUEST-{name}-XXXX.md)
├── artifacts/          # Deliverables from agents
├── resources/          # Reference materials
│   ├── cloud/          # Symlink to iCloud (optional)
│   └── secrets/        # Credentials (gitignored)
└── config/             # App configurations
    └── iterm/          # iTerm2 profiles
```

### Environment Variable

```bash
# Set by setup-agency or add-principal in shell profile
export AGENCY_PRINCIPAL="alice"

# Used by tools via:
PRINCIPAL=$(./tools/principal)
# or
./tools/config get-principal
```

---

## Technical Highlights

### Input Validation

All tools validate principal names with consistent rules:

```bash
# Pattern: start with letter, alphanumeric/hyphens/underscores only
if [[ ! "$PRINCIPAL_NAME" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
    log_error "Invalid principal name: $PRINCIPAL_NAME"
    exit 1
fi

# Lowercase conversion
PRINCIPAL_NAME=$(echo "$PRINCIPAL_NAME" | tr '[:upper:]' '[:lower:]')
```

This validation also protects against:
- Path traversal (`../../../etc/passwd`)
- Command injection (`test; rm -rf /`)
- Sed metacharacters (`test&whoami`)

### Trap/RUN_ID Timing Fix

Fixed a subtle bug where trap was set before RUN_ID was initialized:

```bash
# Before (bug):
trap 'log_end "$RUN_ID" "failure" $? ...' EXIT
RUN_ID=$(log_start ...)  # RUN_ID undefined in trap!

# After (fixed):
RUN_ID=$(log_start ...)  # Initialize first
trap 'log_end "${RUN_ID:-}" "failure" $? ...' EXIT  # Safe reference
```

### Early Exit Handling

Fixed add-principal to properly handle early exits:

```bash
# When principal already exists and --no-set-current
if [[ "$SET_AS_CURRENT" != "true" ]]; then
    echo "No changes needed."
    trap - EXIT  # Clear trap before exit
    log_end "$RUN_ID" "success" 0 0 "Principal already exists, no changes"
    exit 0
fi
```

### myclaude Path Check Fix

Fixed a security issue where "none" literal was used in path check:

```bash
# Before (bug):
if [[ -z "${AGENCY_PRINCIPAL:-}" ]] || \
   [[ ! -d "$PROJECT_ROOT/claude/principals/${AGENCY_PRINCIPAL:-none}" ]]; then
# Would check /claude/principals/none if empty!

# After (fixed):
if [[ -z "${AGENCY_PRINCIPAL:-}" ]] || \
   [[ ! -d "$PROJECT_ROOT/claude/principals/$AGENCY_PRINCIPAL" ]]; then
# Short-circuit: if empty, first condition true, second not evaluated
```

---

## Testing

### Test Coverage

Created comprehensive bats tests (`tests/tools/principal.bats`):

| Category | Tests |
|----------|-------|
| Version/Help flags | 16 |
| Flag recognition | 8 |
| Input validation | 4 |
| Security (injection) | 15 |
| Log service integration | 12 |
| Functional (env var, directory creation) | 11 |
| **Total** | **66** |

### Security Tests

```bash
# Path traversal prevention
@test "principal-create: handles path traversal in name" {
    run_tool principal-create '../../../etc/passwd' || true
    [[ ! -f "etc/passwd" ]]
    [[ ! -d "../../../etc/passwd" ]]
}

# Command injection prevention
@test "principal-create: handles command injection in name" {
    run_tool principal-create 'test; rm -rf /' || true
    [[ ! "$output" =~ "syntax error" ]]
}

# Sed metacharacter handling
@test "principal-create: handles sed metacharacters safely" {
    run_tool principal-create "test&whoami" || true
    [[ "$output" =~ "Invalid principal name" ]] || [[ "$status" -ne 0 ]]
}
```

### iTerm Profile Cleanup

Tests that create principals also clean up iTerm profiles:

```bash
# Clean up (including iTerm profile)
rm -rf "claude/principals/$test_name"
rm -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles/agency-$test_name-profiles.json"
```

---

## Review Workflow

### Code Review (2 reviewers + 1 security)

**Code Review Findings:**
- Trap/RUN_ID timing issues (HIGH) - Fixed
- Missing input validation in principal-create (HIGH) - Fixed
- Missing --help flag in principal-create (MEDIUM) - Added
- Early exit without clearing trap (HIGH) - Fixed

**Security Review Findings:**
- Command injection via sed (CRITICAL) - Mitigated by input validation
- Shell profile injection (HIGH) - Mitigated by input validation
- "none" literal in myclaude path check (HIGH) - Fixed

### Test Review (2 reviewers)

**Key Gaps Identified:**
- No functional tests for directory creation
- No env var precedence tests
- Incomplete security test coverage

**Tests Added:**
- PRINCIPAL env var takes precedence
- Directory structure creation verification
- README.md creation verification
- Uppercase to lowercase conversion
- Additional injection/metacharacter tests

---

## Metrics

| Metric | Value |
|--------|-------|
| Tools created | 4 (setup-agency, add-principal, principal-create, principal) |
| Tools modified | 1 (myclaude) |
| Documentation | 1 file (PRINCIPALS.md) |
| Tests | 66 (bats) |
| Security fixes | 5 |
| Code review findings fixed | 8 |

---

## For the Book

### Key Themes

1. **Interactive Setup Outside Claude Code**
   - stdin doesn't work inside Claude Code
   - Principal setup happens in normal terminal
   - myclaude triggers setup before launching Claude

2. **Three-Tier Identity System**
   - **First-time setup** (new project) → setup-agency
   - **Joining project** (existing) → add-principal
   - **Programmatic** (scripts) → principal-create

3. **Environment Variable Pattern**
   - AGENCY_PRINCIPAL persists across sessions
   - Set in shell profile, exported for current session
   - Tools can query via `./tools/principal`

4. **Defense in Depth**
   - Input validation prevents injection
   - Consistent validation across all tools
   - Tests verify security properties

### Quotable Patterns

**"Interactive Before Claude"** - Anything requiring user input (name, passphrase) must happen outside Claude Code, in a normal terminal where stdin works.

**"Detect and Route"** - myclaude detects the setup state and routes to the appropriate tool automatically. Users don't need to know which tool to run.

**"Environment Variables for Identity"** - Principal identity stored in AGENCY_PRINCIPAL, persists in shell profile, available to all tools.

### Case Study Angle

This work demonstrates:
- How to handle interactive setup in a CLI-first environment
- Multi-principal support in a collaborative tool
- Security hardening for user-provided input
- Integration between shell profile, environment variables, and tools

---

## Files Changed

### New Files
| File | Purpose |
|------|---------|
| `tools/setup-agency` | First-time project setup |
| `tools/add-principal` | Join existing project |
| `tools/principal-create` | Programmatic principal creation |
| `tools/principal` | Get current principal |
| `claude/docs/PRINCIPALS.md` | User documentation |
| `tests/tools/principal.bats` | 66 bats tests |

### Modified Files
| File | Changes |
|------|---------|
| `tools/myclaude` | Principal detection and routing |

---

## References

- REQUEST-jordan-0024: Create Principal Tool
- REQUEST-jordan-0030: Starter Onboarding Fixes (issues #2, #3, #10, #11)
- claude/docs/PRINCIPALS.md: User documentation
- Tags: REQUEST-jordan-0024-impl, REQUEST-jordan-0024-review, REQUEST-jordan-0024-tests, REQUEST-jordan-0024-complete
