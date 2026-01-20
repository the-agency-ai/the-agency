# CI Troubleshooting Guide

Guide for investigating and fixing CI failures in The Agency.

## Quick Reference

```bash
# Check recent CI runs
GH_TOKEN=$(./tools/secret get github-admin-token) gh run list --limit 10

# View specific run logs
GH_TOKEN=$(./tools/secret get github-admin-token) gh run view RUN_ID --log

# View just the failures
GH_TOKEN=$(./tools/secret get github-admin-token) gh run view RUN_ID --log 2>&1 | grep -A 20 "fail)"
```

## Investigation Workflow

### 1. Identify the Failure

```bash
# List recent runs with status
GH_TOKEN=$(./tools/secret get github-admin-token) gh run list --limit 5

# Get detailed failure output
GH_TOKEN=$(./tools/secret get github-admin-token) gh run view RUN_ID --log 2>&1 | tail -150
```

### 2. Reproduce Locally

```bash
# Run the specific failing test
bun test path/to/failing.test.ts

# Run all tests
bun test
```

**If local passes but CI fails:** The issue is environment differences (see below).

### 3. Fix and Verify

1. Make the fix locally
2. Run affected tests: `bun test path/to/test.ts`
3. Commit and push
4. Monitor CI: `GH_TOKEN=$(./tools/secret get github-admin-token) gh run list --limit 1`
5. If still failing, get logs and iterate

## Common macOS vs Linux Issues

Our CI runs on Ubuntu Linux. Local development is typically on macOS. These platforms have subtle differences.

### File Modification Time

| Platform | Command | Notes |
|----------|---------|-------|
| macOS | `date -r FILE "+%Y-%m-%d"` | `-r` takes a file path |
| Linux | `stat -c %y FILE \| cut -d' ' -f1` | `-r` expects a timestamp |

**Cross-platform fix:**
```bash
if [[ "$(uname)" == "Darwin" ]]; then
    mod_date=$(date -r "$file" "+%Y-%m-%d")
else
    mod_date=$(stat -c %y "$file" | cut -d' ' -f1)
fi
```

### sed In-Place Editing

| Platform | Command | Notes |
|----------|---------|-------|
| macOS | `sed -i '' 's/a/b/' file` | Requires empty string for backup |
| Linux | `sed -i 's/a/b/' file` | No empty string needed |

**Cross-platform fix:** Use temp file pattern instead:
```bash
grep -v 'pattern' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
```

### Bash Arithmetic with `set -e`

With `set -e` (exit on error), arithmetic expressions that evaluate to 0 cause exit.

```bash
# FAILS when count=0 (evaluates to 0, which is "false")
((count++))

# WORKS (prefix increment evaluates to 1)
((++count))

# Also works
count=$((count + 1))
```

### GNU vs BSD Tools

Many command-line tools have different flags between GNU (Linux) and BSD (macOS):

| Tool | Difference |
|------|------------|
| `grep` | GNU has `--include`, BSD doesn't |
| `find` | Result ordering varies |
| `readlink` | `-f` behavior differs |
| `mktemp` | Template syntax varies |

**Best practice:** Always pipe `find` through `sort` for consistent ordering.

## CI Workflows

The Agency has two CI workflows:

### test.yml (Tests)
- Runs on: push/PR to main
- Purpose: Run the full test suite
- Working directory: `source/services/agency-service`

### starter-verify.yml (Verify)
- Runs on: push/PR to main
- Purpose: Verify starter template integrity
- Checks: Required files, tool permissions, agency-service tests

## Debugging Tips

### Get Full Error Context

```bash
# Search for expect failures
GH_TOKEN=$(./tools/secret get github-admin-token) gh run view RUN_ID --log 2>&1 | grep -B 5 -A 10 "Expected:"

# Search for specific test
GH_TOKEN=$(./tools/secret get github-admin-token) gh run view RUN_ID --log 2>&1 | grep -A 20 "test name here"
```

### Check Environment Differences

```bash
# What shell is CI using?
# Check the workflow file: .github/workflows/test.yml

# What's the working directory?
# Look for 'working-directory:' in the workflow
```

### Test Isolation Issues

If tests pass individually but fail together:
- Check for shared state (temp files, databases)
- Check for port conflicts
- Ensure proper cleanup in `afterEach`

## Adding New CI Workflows

When adding workflows that run shell scripts:

1. **Test on Linux first** if possible (Docker, VM, or CI itself)
2. **Avoid platform-specific commands** or use detection
3. **Use `set -euo pipefail`** but be aware of arithmetic gotchas
4. **Pin tool versions** (e.g., `bun-version: "1.1"`)

## See Also

- `.github/workflows/test.yml` - Main test workflow
- `.github/workflows/starter-verify.yml` - Starter verification
- `CLAUDE.md` - Development workflow and conventions
