# CLAUDE-HOUSEKEEPING.md — housekeeping workstream

The **housekeeping** workstream is the framework's janitorial and plumbing service: the small, never-quite-done work of keeping TheAgency's tooling sharp, its permissions clean, its telemetry honest, and its ground floors swept.

## Purpose

Everything that isn't a feature and isn't a methodology but is the difference between a framework that works and one that nearly works. Includes tool bugs, tool polish, telemetry holes, hookify rule audits, settings drift, commit-precheck gates, CI reliability, and the slow-burn items that surface during real usage.

## Scope

- **In scope:** tool bug fixes (anything under `claude/tools/`), hookify rule additions and audits, telemetry plumbing (log_start/log_end, tool-runs.jsonl, identity resolution), commit-precheck gates, settings template management, cleanup of orphaned files and directories, fleet health cleanup sweeps (e.g., the 2026-04-09 agency-health cleanup).
- **Out of scope:** new tool capabilities that introduce new functionality (those go to `agency` if framework-level or to a product workstream if feature-level). Housekeeping is about keeping what exists working, not building what doesn't yet.

## Conventions

- **One finding, one fix, one commit** — housekeeping work is small by nature. Keep commits atomic so they can be reverted independently.
- **Bug-exposing test + fix in the same turn** (the principal's rule) — never land a fix without the test that would have caught it.
- **Flag → plan → MAR → do → inform** (captain's convention) — when housekeeping touches multiple agents' state, follow the dispatch-back learning loop from the PR workflow.
- **Captain is the primary maintainer** — most housekeeping happens on main or via captain cutting fixes onto agent branches. Worktree agents may also contribute housekeeping within their own scope.

## Related

- `claude/tools/agency-health` — the primary surface for identifying housekeeping work
- `claude/tools/agency-verify` — structural validation (complements agency-health's behavioral checks)
- Flag queue items tagged `BUG`, `friction`, `AUDIT`, or `DISCIPLINE`
- `claude/workstreams/agency/` — when housekeeping reveals a methodology gap, the insight graduates there

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
