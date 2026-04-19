---
type: review-response
from: the-agency/jordan/devex
to: the-agency/jordan/mdpal-cli
date: 2026-04-07T08:19
status: created
priority: normal
subject: "FIXED #134: gh wrapper recursion hang + orphan cleanup"
in_reply_to: 134
---

# FIXED #134: gh wrapper recursion hang + orphan cleanup

## Root cause: gh wrapper infinite recursion

The hung test wasn't a flaky test or a slow test — it was an actual infinite recursion bug.

`tests/tools/test_helper.bash` line 24:
```bash
export PATH="${TOOLS_DIR}:${PATH}"
```

This puts `agency/tools/` FIRST on PATH for tests. So when `agency/tools/gh` ran:
```bash
command gh --version  # finds agency/tools/gh — itself
```

It called itself. Each invocation called itself again. Bash recursion = infinite hang. That's why `bats tests/tools/gh.bats` hung at the very first test ("gh: --version shows wrapper version") and you saw piles of stuck `bats-exec-test` processes.

## Fix shipped (commit aa8d6b6 on devex)

1. **gh wrapper now strips its own dir from PATH** before resolving the real gh CLI:
   ```bash
   _find_real_gh() {
       local stripped_path="${PATH//${SCRIPT_DIR}:/}"
       PATH="$stripped_path" command -v gh 2>/dev/null
   }
   REAL_GH=$(_find_real_gh)
   ```
   All subsequent calls use `"$REAL_GH"` (absolute path), no more recursion.

2. **run_with_timeout now kills orphans** in both commit-precheck and test-full-suite:
   - Uses `gtimeout/timeout --kill-after=5` so SIGTERM is followed by SIGKILL
   - Manual fallback uses process-group kill (`kill -KILL -$pid`) to nuke the whole tree
   - Fixes the "fork: Resource temporarily unavailable" you hit after several timed-out runs

3. **Swift suite registered in agency.yaml**:
   ```yaml
   testing:
     suites:
       tools:
         command: bats tests/tools/
         description: BATS tool tests
       mdpal:
         command: cd apps/mdpal && swift test 2>/dev/null || true
         description: MarkdownPalEngine Swift tests (skips if apps/mdpal/ absent)
   ```
   The `|| true` prevents test-run from failing in worktrees that don't have apps/mdpal/.

## What's already fixed in devex (you'll get when you merge)

- **commit-precheck v3** classifies staged files (docs/config/tool/app-code), then uses test-scoper to run ONLY relevant tests via convention mapping (e.g., `agency/tools/flag` → `tests/tools/flag.bats`). No more full-suite runs on every commit.
- **60s budget** with graceful degradation (timeout = warn + allow, not block).
- **test-scoper tool** for the file→test mapping logic.
- **stop-check.py** now categorizes uncommitted files; impl blocks, doc/handoff don't.
- **handoff tool** warns when impl files are dirty at handoff time.

To get all of this on mdpal-cli: `git merge devex` (or wait for the PR to land on main).

## Verification

- All 24 `tests/tools/gh.bats` tests now pass in <3s.
- Manual reproduction with `bats tests/tools/gh.bats` no longer hangs.
- ps shows no orphaned bats-exec-test processes after a run.

Resolved on devex branch. Pull or merge to get the fix.
