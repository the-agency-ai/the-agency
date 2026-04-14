---
type: plan
agent: the-agency/jordan/captain
workstream: agency
date: 2026-04-09
trigger: agency-health findings 2026-04-09 13:46
status: draft-for-mar
---

# Fleet Health Cleanup Plan

Source: `agency-health` run 2026-04-09 13:46 — 8 warnings, 0 critical.

Captain fixes everything, then dispatches each affected agent with a learning-loop review-response.

## Current state summary

| Dimension | Healthy | Attention | Warning | Critical |
|-----------|---------|-----------|---------|----------|
| Workstreams (7) | 2 | 5 | 0 | 0 |
| Agents (8) | 0 | 3 | 5 | 0 |
| Worktrees (4) | 0 | 1 | 3 | 0 |

## Findings grouped by fix class

### Class A — Mechanical, low-risk (captain applies immediately)

1. **`.claude/settings.json` drift — all 4 non-main worktrees**  
   Fix: `cp` from main checkout to each worktree. No merge conflicts possible; mechanical copy. Hookify hooks already enforce this on next merge anyway.  
   Affected: devex, iscp, mdpal-app, mdpal-cli

2. **Missing `.agency-agent` identity file — mdpal-cli**  
   Fix: create `.agency-agent` file at worktree root with correct agent slug (`mdpal-cli`).  
   Affected: mdpal-cli

3. **Missing `CLAUDE-{WORKSTREAM}.md` scoping files** (5 workstreams)  
   Fix: scaffold stub files using the convention from CLAUDE-THEAGENCY.md. Each file imports framework + workstream context.  
   Affected: agency, gtm, housekeeping, mdpal, mock-and-mark

### Class B — Investigation + directed fix (captain investigates, then fixes)

4. **mdpal-app: 1449 modified files**  
   Almost certainly build artifacts polluting git status (likely `apps/mdpal/.build/` or similar from a Swift build). Fix: investigate the pattern, add to `.gitignore` at workstream or repo level, `git rm --cached` the tracked build output, commit.  
   Affected: mdpal-app worktree

5. **Worktree sync gap — all 4 worktrees 12–133 commits behind main**  
   Fix: run `worktree-sync --auto` in each (now that #65 is fixed and main/master detection works). Resolve any conflicts by accepting main where safe, dispatching the agent where judgment is needed.  
   Affected: devex, iscp, mdpal-app, mdpal-cli  
   Risk: medium — mdpal-app has 1449 modified files which may cause stash conflicts on sync. Do mdpal-app LAST, after the gitignore fix in #4.

### Class C — Agent handoffs / long-idle agents (captain notes, dispatches)

6. **mdpal-app and mdpal-cli: no handoff found**  
   Fix: cannot manufacture a handoff without knowing the agent's state. Scaffold empty stubs at the canonical paths so future session-resume finds them, dispatch each agent asking for a proper handoff on their next session.  
   Affected: mdpal-app, mdpal-cli

7. **mock-and-mark: handoff 9d old, no worktree**  
   mock-and-mark may be a dormant agent from earlier work. Fix: confirm status, either reactivate or formally mark as dormant. Dispatch for clarification from principal.  
   Affected: mock-and-mark

8. **tech-lead, testname: no worktree, no handoff**  
   Same pattern — dormant or abandoned agents. Fix: confirm status, either scaffold or formally archive.  
   Affected: tech-lead, testname

### Class D — Historical, not fixable without history rewrite

9. **Test User commits in agent histories** (captain: 1, devex: 3, iscp: 8, mdpal-app: 19, mdpal-cli: 18)  
   All of these are on branches that may already be merged or are in-progress. Filter-branch on in-progress branches is risky (breaks refs, requires force-push); filter-branch on merged main is forbidden by discipline.  
   **Fix: leave as-is.** Gate 0 in commit-precheck (shipped 34.2) prevents new occurrences. Accept the historical pollution as permanent evidence of the bug we fixed. Dispatch each agent with the learning note: "your branch has N Test User commits — these are historical, do not rewrite, going forward Gate 0 prevents recurrence."

## Execution order

1. Class A first (mechanical, low-risk, no conflicts possible)
   a. Settings drift copies
   b. mdpal-cli `.agency-agent`
   c. CLAUDE-{ws}.md scaffolds
2. Class B next (investigation + directed)
   d. mdpal-app gitignore investigation + fix
   e. Worktree syncs (mdpal-app last, after 2d)
3. Class C scaffolding + dispatches
4. Class D dispatches only (no mechanical fix)

## Risks + mitigations

- **R1: Settings copy overwrites legitimate local sandbox changes.**  
  Mitigation: diff before copy, prompt if diff is non-trivial. Captain runs with a dry-run pass first.
- **R2: mdpal-app gitignore fix accidentally removes tracked source code.**  
  Mitigation: read the 1449-file list first, classify as build-artifact vs source, only `git rm --cached` the clearly-build entries. Commit per class.
- **R3: Worktree-sync conflicts cascade into the wrong resolution.**  
  Mitigation: run `--auto` which stashes + aborts on conflict (already proven in #57 fix). If conflict, STOP, do not freelance, dispatch the affected agent.
- **R4: Dispatching 5+ agents with learning-loop messages is noisy.**  
  Mitigation: one dispatch per agent, subject clearly "fleet health cleanup — changes to your worktree + learning note."

## Learning dispatches (Class D for all, Class B/C for owners)

For each affected agent, captain will send a review-response dispatch with:

- What captain found (specific to the agent)
- What captain fixed (specific to the agent)
- How the agent avoids the problem next time (process change, tool usage, hookify rule reference)
- Pointer to the captain's log entry documenting the fix

## Success criteria

- `agency-health` exit code on second run: 0 (all healthy) OR 1 (warnings only, no new criticals). 0 is the target.
- All Class A and B findings resolved.
- Class C scaffolds in place (handoff stubs exist even if empty).
- Class D dispatches sent to all affected agents.
- Captain's log has one `build` entry summarizing the cleanup.
- One PR shipped with the fixes (D34-R5).

## What this plan does NOT do

- Does not rewrite git history (no filter-branch).
- Does not force-push anything.
- Does not delete any agents (tech-lead, testname may need archival but not deletion — separate decision).
- Does not touch the-agency-starter history (the pre-history per flag #76 is separate work).
