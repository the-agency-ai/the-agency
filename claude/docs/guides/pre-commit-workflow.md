# Pre-Commit Workflow

**Quick Reference:** 5-step quality gate runs automatically. Use `--no-verify` only when absolutely necessary.

## Overview

All commits (Claude and manual) go through comprehensive pre-commit checks enforced by both Claude hooks and Husky.

## 5-Step Quality Gate

1. **Format code** (auto-fix) - Prettier on all staged files
2. **Lint code** (auto-fix) - ESLint with auto-fix enabled
3. **Type check** (blocking) - TypeScript compilation check
4. **Unit tests** (blocking) - Fast unit tests only (~3-5s)
5. **Code review** (blocking) - Pattern-based security and quality checks

## Performance

- **Target:** 18-31 seconds total
- **Optimization:** Integration tests skipped (run in CI only)
- **Parallel execution:** Tests run across all packages simultaneously

## What Gets Blocked

### Security (blocking)

- Hardcoded secrets (API keys, passwords, tokens)
- SQL injection patterns (template literals in queries)

### Quality (warnings)

- `console.log`/`console.debug` in production code
- TypeScript `any` usage
- TODO comments without issue references (#123, PRJ-456)

## Tools

- `./tools/commit-precheck` - Orchestrator (runs all 5 steps)
- `./tools/test-run` - Unit-only test runner
- `./tools/code-review` - Pattern-based code review

## Bypassing Checks

**Only use when absolutely necessary:**

```bash
git commit --no-verify -m "WIP: legitimate reason"
```

**Note:** CI still enforces all checks, so bypass only delays failure detection.

## Implementation

- **Claude hooks:** PreToolUse hook intercepts `git commit` commands
- **Husky:** Git pre-commit hook runs for all commits (fallback for manual commits)
- **CI:** GitHub Actions enforces same checks (safety net)

---

*Part of The Agency framework*
