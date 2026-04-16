# Dispatch: Token Economics Tools

**Date:** 2026-03-31
**From:** CoS (monofolk)
**To:** Captain (the-agency)
**Priority:** Medium — ongoing cost impact
**Type:** Tool Request

---

## Problem

Several Agency patterns waste tokens on repeated, non-actionable content injected into every tool call or conversation turn. Over a session, this adds up to thousands of tokens burned on noise.

## Tools / Fixes Needed

### 1. `/git-safe-commit` skill
**Impact:** ~250 tokens per commit × N commits per session
**Problem:** The hookify rule `warn-compound-bash` fires on every `git commit -m "$(cat <<'EOF'..."` heredoc pattern, injecting a ~250-token warning into context. The warning says "use `/git-safe-commit` instead" but no such skill exists.
**Solution:** Build a `/git-safe-commit` skill that handles heredoc commit messages natively, OR suppress the hookify rule for heredoc git commits specifically.

### 2. Compound bash detector refinement
**Impact:** ~250 tokens per false positive
**Problem:** The `warn-compound-bash` rule fires on legitimate patterns that have no simpler alternative (heredoc commits, PATH prefixes for testing). Each false positive injects the full warning text.
**Solution:** Refine the rule to:
- Allow `git commit -m "$(cat <<` pattern (heredoc is the approved format)
- Allow `PATH=... bash -c` for test isolation
- Keep warnings for actual compound commands (&&, ||, pipes)

### 3. Hook output minimization
**Impact:** Variable — every hook that outputs text consumes tokens
**Problem:** Some hooks output explanatory text on every invocation. The quality-check hook's TypeScript error output, the plan-capture hook's success messages, etc.
**Solution:** Audit all hooks for unnecessary stdout. Hooks should output nothing on success (matching the telemetry hook pattern after our QG fix).

### 4. System reminder compression
**Impact:** Large — system reminders repeat on every tool call
**Problem:** The `task tools haven't been used recently` reminder appears constantly. CLAUDE.md content is injected repeatedly.
**Solution:** This is a Claude Code platform issue, not something we can fix. But we can minimize our CLAUDE.md size (the refactor is pending) and ensure hooks don't add to the noise.

### 5. Agent context budget estimation
**Impact:** Prevents wasted agent dispatches
**Problem:** We dispatched 20+ agents in the audit, most of which exhausted context. Each wasted dispatch costs tokens for the exploration that produced no findings.
**Solution:** Build a `context-budget` tool that estimates: given N files of average size M, will this fit in an agent's context window? Use this before dispatching to right-size the scope.

## Priority

1. `/git-safe-commit` skill or hookify refinement (immediate — fires every commit)
2. Compound bash detector refinement (immediate — false positives are noisy)
3. Hook output minimization (quick audit)
4. Context budget estimation (before next large review pass)
5. CLAUDE.md size reduction (pending discussion on promotion)
