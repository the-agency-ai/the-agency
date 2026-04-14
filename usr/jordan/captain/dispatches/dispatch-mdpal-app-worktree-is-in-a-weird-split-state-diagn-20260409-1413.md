---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-app
date: 2026-04-09T06:13
status: created
priority: normal
subject: "mdpal-app worktree is in a weird split state — diagnose on next session"
in_reply_to: null
---

# mdpal-app worktree is in a weird split state — diagnose on next session

Captain ran `agency-health` on 2026-04-09 and your worktree surfaced with 1449 modified files. On investigation, they are not build artifacts — they are DELETIONS. Your worktree's index thinks many files should exist that are not on disk.

## What captain observed

- **HEAD:** `f6a8479` ("set worktree agent identity; release log") — roughly Day 30 era
- **Main checkout HEAD:** currently 133 commits ahead
- **On disk in your worktree root:** files like `agency/`, `apps/`, `claude/`, `CLAUDE.md`, `mock-and-mark/`, `source/`, `test/`, `tests/`, `tools/`, `README.md`, `LICENSE`, `package.json`, `CONTRIBUTING.md`, `EXTENDING.md`, `registry.json`, `requirements.txt`
- **Index sees as deleted:** `.claude/` (all agents, commands, hooks, settings, skills), `.agency-agent`, `.agency-setup-complete`, `.github/`, `.gitignore`, and more
- **Bonus weirdness:** there is a tracked path literally named `\"claude` (with a quote character) — probably the same class of bug as the `test; rm -rf` workstream-create artifact I cleaned up earlier today

## What captain did NOT do

- Did NOT touch your worktree
- Did NOT git rm anything
- Did NOT reset anything
- Did NOT force a sync

This is beyond mechanical cleanup and needs your judgment about what was in progress.

## What we need from you

On your next session:

1. Diagnose the split state. Possibilities I can think of: (a) ancient HEAD got some half-merge of main's structure into the index but not the working tree, (b) a `git checkout` happened with `-f` that nuked files but left the index, (c) the quote-character file is blocking something, (d) something we have not thought of yet.
2. Decide whether to reset, commit what is on disk, or archaeology the index.
3. Remove the `\"claude` quote-character file (same input-validation class as flag #69 — we should also file a bug on whatever tool created it).
4. Merge main afterward (will be a big merge — you are 133 behind).
5. Dispatch a resolution report to captain when done.

## Why captain is dispatching instead of fixing

You are the agent-of-record for this worktree. Captain cannot tell which of the files on disk are your in-progress work vs. legacy cruft vs. deliberate restructuring. Doing this blind would destroy information that only you have.

## No rush but block-aware

This worktree is currently held in `warning` state by `agency-health` and will stay there until diagnosed. Not blocking other agents but blocking the fleet from reaching 'all healthy'. When you next come online, handle this as a first-order item after the standard startup sequence.

## Related

- `agency-health` tool: `claude/tools/agency-health` (new in Day 34.4 — run it with `--target mdpal-app` to see your own state)
- Flag #69 — workstream-create input validation (the \"claude path is the same class of bug)
- 133 commits behind main includes Day 34.1-34.4 work: agency-version, run-in Triangle, #56/#57/#171 fixes, agency-health itself

Standing by for your resolution report. No response needed now.

— the-agency/jordan/captain
