---
type: tracking
date: 2026-04-05
status: active
scope: agent permission friction, Claude Code UX issues, tooling gaps
---

# Friction Points

Running log of friction, pain points, and UX issues discovered during agent operations. Sourced from flags, handoffs, transcripts, and direct observation.

Intent: graduate this into a proper tracking system (REQUEST + dispatch) once patterns stabilize.

---

## Permission Friction

These are all cases where Claude Code's permission model creates unnecessary prompts for safe operations.

### P1: Basic read operations prompt on agent files

**Observed:** ISCP agent hit permission prompts for `ls`, `git show`, `sqlite3` on framework paths.
**Impact:** Every prompt breaks agent flow and requires principal intervention.
**Root cause:** settings.json didn't pre-approve read-only operations on `usr/`, `claude/`, `~/.agency/`.
**Status:** Partially fixed — permissions added to settings.json in session 19. Agents need restart to pick up.
**Source:** Flag #1 (2026-04-05)

### P2: `~/.agency/` path access blocked

**Observed:** ISCP agent blocked on reading `~/.agency/` (SQLite DB location for ISCP).
**Impact:** ISCP tools can't function without DB access.
**Root cause:** `~/.agency/` not in pre-approved paths.
**Status:** Fixed in settings.json. Needs restart to verify.
**Source:** Flag #2 (2026-04-05)

### P3: Compound `cd && git` commands blocked as bare repo attack

**Observed:** ISCP agent ran `cd /path/to/worktree && git show master:file` and Claude Code blocked it as a bare repository attack vector.
**Impact:** Agents can't access dispatch payloads from worktrees using raw git commands.
**Workaround:** Use `git -C <path>` instead of `cd && git`. Better: use `dispatch read` tool which handles this internally.
**Root cause:** Claude Code security heuristic — compound commands with `cd` + `git` are flagged.
**Status:** Workaround documented. Agents should use `dispatch read`, not raw git.
**Source:** Flag #3 (2026-04-05)

### P4: Brace expansion in bash triggers prompts

**Observed:** `agency-init` uses brace expansion (`{a,b,c}`) which Claude Code treats as multiple commands.
**Impact:** Init flow broken by permission prompts.
**Root cause:** Claude Code bash parser interprets braces as compound.
**Status:** Open. Needs rewrite to avoid brace expansion.
**Source:** next-release-items #1

### P5: settings-template.json doesn't ship enough permissions

**Observed:** `agency-init` produces settings.json that lacks permissions for flag, handoff, dispatch read/list, ls on usr/, and other safe read operations.
**Impact:** Every new project starts with a broken permission model — agents prompt for everything.
**Root cause:** settings-template.json is too conservative.
**Status:** Open. Need to audit all non-destructive operations and pre-approve them.
**Source:** next-release-items #3

### P6: macOS permissions break on every Claude Code update

**Observed:** macOS accessibility/automation permissions are pinned to the binary path, which includes the Claude Code version number.
**Impact:** Every Claude Code update requires re-granting permissions in System Settings.
**Root cause:** macOS permission model + Claude Code's versioned binary path.
**Status:** Open. Anthropic issue — not something we can fix in the framework.
**Source:** Memory (feedback_computer_use_permissions.md)

---

## Tooling Gaps

### T1: No dispatch fetch/reply subcommands

**Observed:** Agents need to fetch dispatch payloads from master and send replies, but these operations are manual.
**Impact:** Dispatch lifecycle is incomplete — agents can't self-serve.
**Dispatch:** #5 to ISCP agent (HIGH priority) — build these.
**Status:** Dispatched, awaiting ISCP agent implementation.
**Source:** Handoff, dispatch #5

### T2: Worktree agents can't access dispatch payloads without merging master

**Observed:** Dispatch payloads live as git files on master. Worktree agents on feature branches can't read them without `git merge master`.
**Impact:** Adds a merge step to every dispatch read — friction and potential conflicts.
**Workaround:** `dispatch read` uses `git show main:path` fallback.
**Status:** Workaround in place. `dispatch read` handles it. But agents running raw git commands still hit this.
**Source:** Session 19 observations

### T3: commit-precheck runs full BATS suite, times out

**Observed:** Pre-commit hook runs the entire BATS test suite, which takes too long and times out.
**Impact:** Forces `--no-verify` usage, which defeats the purpose.
**Root cause:** commit-precheck doesn't scope tests to changed files.
**Status:** Open. Needs devex workstream.
**Source:** Handoff bugs section

### T4: Ephemeral worktree agents have no lifecycle

**Observed:** When captain delegates to a worktree agent, there's no permissions model, dispatch visibility, or teardown lifecycle.
**Impact:** Worktree agents are second-class citizens.
**Status:** Open. Identified in PVR MAR.
**Source:** captain-pvr-mar-20260405.md

### T5: BATS test isolation leaks

**Observed:** `AGENCY_PRINCIPAL=testuser` leaks into the shell environment. Tests write to live INDEX.md and releases.md instead of fixtures.
**Impact:** Tests pollute real state. Flaky test results.
**Status:** Open. Needs devex workstream (Docker isolation).
**Source:** next-release-items #6

---

## Agent Startup / Bootstrap

### B1: agency-init broken on multiple fronts

**Observed:** Flat principals format, blocks on branchless repos, missing permissions, doesn't ship flag+handoff tools, brace expansion triggers prompts.
**Impact:** Can't bootstrap a new project cleanly.
**Status:** Open. Tier 1 priority.
**Source:** next-release-items #1

### B2: agent-create missing essentials

**Observed:** No bootstrap handoff, no tech-lead template, placeholder text, doesn't register in settings.json, creates extra unspecified files.
**Impact:** New agents start broken.
**Status:** Open. Tier 1 priority.
**Source:** next-release-items #2

### B3: No automated permission prompt counter

**Observed:** PVR success criterion "zero permission prompts for pre-approved operations" can't be measured automatically.
**Impact:** Can't verify the permission model works without manual observation.
**Status:** Open. Identified in PVR MAR.
**Source:** captain-pvr-mar-20260405.md

---

## Claude Code Behavioral Issues

### C1: Agent permission scope undefined

**Observed:** No model for what agents CAN'T do. Only what they're approved to do.
**Impact:** Security model is additive-only — no deny lists.
**Status:** Open. Design question.
**Source:** captain-pvr-mar-20260405.md

### C2: `~/.agency/` directory security on multi-principal machines

**Observed:** File permissions on the shared ISCP database are not hardened for multi-user scenarios.
**Impact:** One principal could read another's dispatches.
**Status:** Open. Low priority (single-user machines for now).
**Source:** captain-pvr-mar-20260405.md
