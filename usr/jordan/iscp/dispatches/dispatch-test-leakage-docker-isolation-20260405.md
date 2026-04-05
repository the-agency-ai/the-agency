---
type: escalation
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-05
status: created
priority: high
subject: "AGENCY_PRINCIPAL test leakage — case for Docker test isolation"
in_reply_to: null
---

# AGENCY_PRINCIPAL Test Leakage — Case for Docker Test Isolation

## The Bug

During ISCP v1 deployment, all dispatch and flag operations were silently routing to `the-agency/testuser/iscp` instead of `the-agency/jordan/iscp`. The principal was misidentified as `testuser` instead of `jordan`.

## Root Cause Chain

1. **`add-principal` tool** (line 204) wrote `export AGENCY_PRINCIPAL="testuser"` to `~/.zshrc` during a test or misconfigured run
2. Every shell session (including Claude Code) inherits this env var
3. **`_path-resolve`** (line 173) checked `if [[ -z "${AGENCY_PRINCIPAL:-}" ]]` — since it was already set, it **skipped agency.yaml resolution entirely**
4. **`_address-parse`** (line 422) had the same shortcut: `if [[ -n "${AGENCY_PRINCIPAL:-}" ]]` → return it without validation
5. **`agent-identity`** cached the wrong value per-branch, so even clearing the env var wouldn't immediately fix it
6. **Result:** Every ISCP tool — dispatch, flag, iscp-check — resolved identity as `testuser` instead of `jordan`

## Impact

- Dispatches created with wrong `from_agent` (`testuser` instead of `jordan`)
- Dispatches filed to wrong directory (`usr/testuser/` instead of `usr/jordan/`)
- Flag routing to wrong agent queue
- iscp-check would miss notifications addressed to `jordan`
- **This was completely silent** — no error, no warning, just wrong identity

## Fix Applied (on iscp branch)

1. **`_path-resolve`:** Removed the `if [[ -z "${AGENCY_PRINCIPAL:-}" ]]` guard. Now ALWAYS resolves from agency.yaml via `$USER`, regardless of whether `AGENCY_PRINCIPAL` is pre-set. Still sets the variable for backward compat, but never trusts it as input.

2. **`_address-parse`:** Removed the `AGENCY_PRINCIPAL` shortcut in `_address_detect_principal()`. Added deprecation comment. Always falls through to agency.yaml lookup.

3. **Identity cache cleared:** Stale cache at `~/.agency/the-agency/.agent-identity-*` was holding the wrong value.

## What Still Needs to Happen

1. **Remove `export AGENCY_PRINCIPAL="testuser"` from `~/.zshrc`** — Jordan needs to do this manually (or captain can advise)
2. **`add-principal` tool needs fixing** — it should NOT write to shell profiles. This is how the leak got there in the first place. The tool should warn and provide copy-paste instructions, not modify dotfiles.
3. **Audit all tools using `AGENCY_PRINCIPAL`** — `myclaude` (line 439), `session-handoff.sh` (line 102), `tool-telemetry.sh` (line 65) all read this env var

## The Case for Docker Test Isolation

This bug is the canonical example of **test environment leaking into production**:

- BATS tests set `USER=testuser` for isolation
- But the `add-principal` tool (or a test that called it) wrote to the **real** `~/.zshrc`
- That persisted across sessions, across tools, across agents
- The hookify rule `hookify.block-testuser-paths.md` already existed to catch `usr/testuser/` paths — **the project knew this was a recurring problem**

**Docker containers for test execution would eliminate this class entirely:**

| Without Docker | With Docker |
|----------------|-------------|
| Tests write to real `~/.zshrc` | Container filesystem is ephemeral |
| `AGENCY_PRINCIPAL` leaks to all future sessions | Env vars die with the container |
| Stale identity caches persist in `~/.agency/` | No `~/.agency/` outside container |
| `HOME` override partially works (we do this) but tools that read shell profiles bypass it | Complete isolation — no shell profiles to leak from |

The BATS tests already override `HOME` to prevent DB contamination. But env vars set before the test starts (from shell profiles) can't be caught by `HOME` override. Docker would give us process-level isolation — the test literally cannot modify the host.

**Recommendation:** Prioritize Docker-based test execution as a Phase 3 item or separate workstream. Until then, all BATS test files should explicitly `unset AGENCY_PRINCIPAL` in their setup (the ISCP tests already do this — it should be standard practice).

## Acceptance Criteria

- [ ] `~/.zshrc` cleaned up (remove `export AGENCY_PRINCIPAL="testuser"`)
- [ ] `add-principal` tool fixed to not write to shell profiles
- [ ] Audit tools for `AGENCY_PRINCIPAL` usage
- [ ] Docker test isolation discussed and prioritized
- [ ] `_path-resolve` and `_address-parse` fixes landed on main (via iscp branch merge)
