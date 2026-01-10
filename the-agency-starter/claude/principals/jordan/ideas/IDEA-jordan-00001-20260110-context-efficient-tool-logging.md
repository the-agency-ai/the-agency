# IDEA-jordan-00001-20260110-context-efficient-tool-logging

**From:** principal:jordan

**Status:** Captured

**Created:** 2026-01-10

**Tags:** tooling, context-management, log-service, token-efficiency

## The Idea

All Agency tools should log their runs to log-service and return minimal output. On success, return a single line confirmation. On failure, return a run-id that can be used to fetch detailed logs. This dramatically reduces context window consumption while maintaining full debuggability.

## Why It Matters

A single tool run (like `release-starter`) dumped 231 lines into the context window. 99% of that was noise (file create/rename messages). The agent only needed to know: "it worked" or "it failed, here's how to debug."

**Current state:** Tools dump everything to stdout → consumes tokens → bloats context
**Target state:** Tools log to service → return 1 line → query logs on failure

Benefits:
- Massive token savings (231 lines → 1 line)
- On-demand detail when debugging
- Queryable history ("what failed yesterday?")
- Same interface for agents and humans (API + CLI)

## Initial Thoughts

**Pattern:**
```
SUCCESS: "✓ release-starter v0.1.0 complete (run-id: abc123)"
FAILURE: "✗ release-starter failed (run-id: abc123)"
```

**On failure:**
```bash
./tools/agency-service log show abc123           # Full log
./tools/agency-service log show abc123 --errors  # Just errors
```

**Implementation considerations:**
- Tools get `--verbose` flag for debugging the tool itself
- Every run gets a unique `run-id`
- log-service provides `/api/log/run/:runId` endpoint
- Requires log-service to be running (or graceful fallback to stdout)

**Chicken-and-egg resolution:**
- Option A: Tools log to file, log-service indexes files (decoupled)
- Option B: Build log-service first, retrofit tools after

## Promoted To

To be implemented as part of REQUEST-jordan-0012 (log-service + LogBench)

---

*Captured via The Agency idea workflow*
