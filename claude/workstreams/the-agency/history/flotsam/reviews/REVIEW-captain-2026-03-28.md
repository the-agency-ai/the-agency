# Code Review: Captain Agent — Recent Commits

**Date:** 2026-03-28
**Reviewer:** captain
**Range:** c9afbab..64d35ec (7 commits)
**Stats:** +5,326/-2,056 lines across 38 files

---

## Scope

Three major features plus supporting work:
1. Per-service database isolation
2. Dispatch queue system
3. Unified messaging (`msg` tool)
4. Plan artifact auto-capture (TaskCompleted hook)
5. Status line refactoring (inline command)
6. Legacy deprecation wrappers

| Feature | Files | Assessment |
|---------|-------|------------|
| Per-service DB isolation | database/index.ts, migration script, index.ts | Solid |
| Dispatch service | 5 new TS files, `tools/dispatch`, `tools/dispatch-request` | Well-structured |
| Unified messaging (`tools/msg`) | 1 new tool + legacy wrappers | Clean |
| Plan capture hook | plan-capture.py | Functional |
| Status line inline command | settings.json | Works but needs attention |
| Legacy deprecation wrappers | 6 `.legacy` files | Good migration path |

---

## Strengths

- **Clean layered architecture** in dispatch service: repository -> service -> routes -> CLI tool. Follows the existing messages-service pattern well.
- **Atomic claim with tiered fallback** (agent queue -> shared queue) using `UPDATE ... RETURNING *` is a solid pattern for avoiding race conditions.
- **Proper claim TTL + sweep** -- the `startSweep()` background interval prevents orphaned claims.
- **Session lifecycle** -- hooks properly register/deregister instances and release claims on exit.
- **Legacy wrappers** -- old tools (`collaborate`, `news-post`, etc.) are preserved as `.legacy` files rather than deleted. Good for transition.
- **Tool output standard** followed consistently in all new tools.

---

## Issues & Suggestions

### 1. Status Line -- Maintainability Concern (Medium)

The inline status line command in `settings.json` is a single escaped string ~3KB long. This is extremely hard to read, debug, or modify. The previous `statusline.sh` was 46 lines of readable bash.

**Suggestion:** If the intent was to avoid the external file dependency, consider at minimum adding a comment in CLAUDE.md about where the canonical source lives. Or restore it as a separate script but fix whatever issue prompted the change.

**File:** `.claude/settings.json`

### 2. Claim Race Condition -- `releaseAllByInstance` Uses Agent Name (Medium)

In `dispatch.repository.ts`, `releaseAllByInstance()` finds the instance's `agentName` and releases all items claimed by that agent name:

```sql
WHERE claimed_by = ? AND status IN ('claimed', 'active')
```

If two instances of the same agent are running, this releases the **other instance's claims too**. Should use `instanceId` tracking instead, or add a `claimed_by_instance` column.

**File:** `source/services/agency-service/src/embedded/dispatch-service/repository/dispatch.repository.ts`

### 3. Plan Capture -- Hardcoded Agent/Principal (Low)

`plan-capture.py:228` hardcodes `captain` and `jordan`:

```python
**Agent:** captain
**Principal:** jordan
```

Should read from `AGENTNAME` / `PRINCIPAL` env vars with these as defaults.

**File:** `.claude/hooks/plan-capture.py`

### 4. Shell Tool Input Handling (Low -- No Action Needed)

`tools/dispatch` and `tools/msg` pass user-supplied strings into JSON via `jq --arg` which handles escaping correctly. The `--error` path in `cmd_fail` uses `echo "$error_msg" | jq -R .` which is also safe. No injection risk -- noting the pattern is correct.

**Files:** `tools/dispatch`, `tools/msg`

### 5. `stop-check.py` -- Dispatch Check Could Block Exit (Low)

The dispatch queue check in `stop-check.py` uses a 2-second timeout (`timeout=2`). If the service is slow, this delays session stop. The `except Exception: pass` is correct for fallback, but consider reducing to 1 second since this is a stop gate.

**File:** `.claude/hooks/stop-check.py`

### 6. Migration Script Not Wired into Startup (Low)

`migrate-to-per-service-db.ts` exists but there's no automatic migration path. If someone upgrades, they need to know to run it manually. Consider a version check in service startup.

**File:** `source/services/agency-service/src/scripts/migrate-to-per-service-db.ts`

### 7. `session-end.sh` -- Fire-and-Forget Race (Cosmetic)

The deregister calls in `session-end.sh` are fire-and-forget (`|| true`), which is correct, but they happen before checking `remaining_instances`. If the last instance deregisters from dispatch before the remaining check, the service may shut down before the deregister response completes. Likely fine in practice since `curl --connect-timeout 1` is fast.

**File:** `.claude/hooks/session-end.sh`

---

## Security

- No secrets in code
- SQL parameterized throughout (no injection risk)
- Zod validation on all API inputs
- `jq` used for JSON construction in shell tools (safe escaping)
- No auth on dispatch API endpoints -- acceptable for local-only service, but worth noting if this ever listens on non-localhost

---

## Test Coverage

No new tests visible in this diff. The dispatch service (repository, service, routes) and the migration script should have tests. This is the biggest gap.

---

## Action Items (Priority Order)

1. **Add tests for dispatch service** -- repository, service, and routes layers
2. **Fix `releaseAllByInstance`** to scope by instance ID, not agent name
3. **Extract inline status line** back to a maintainable script
4. **Read env vars in plan-capture.py** instead of hardcoding agent/principal
5. **Reduce stop-check dispatch timeout** from 2s to 1s
6. **Wire migration into startup** with version check
