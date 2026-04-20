---
type: seed
workstream: agency
date: 2026-04-08
captured_by: the-agency/jordan/captain
principal: jordan
status: seed
---

# Seed: `release-plan` tool

## What it is

A tool that answers the question **"what should be in today's PR?"** automatically. Instead of captain manually grouping uncommitted changes + local-ahead commits + untracked files into logical commits, the tool analyzes the current state and produces a proposed release plan.

Captured during Day 33 R1 work when principal observed me manually walking through the staging area and grouping changes — *"That should be a tool!"*

## What it does

Given the current branch state, produces:

1. **Inventory** of everything that could land in the release:
   - Local commits ahead of origin
   - Modified files (staged + unstaged)
   - Untracked files (excluding gitignored)
2. **Logical grouping** by directory / file pattern / commit hint:
   - Methodology / docs (`claude/CLAUDE-*.md`, `usr/*/CLAUDE-*.md`, `claude/templates/*`)
   - Tool changes (`claude/tools/*`)
   - Skill changes (`.claude/skills/*`)
   - Hook changes (`claude/hooks/*`, `.claude/settings.json`, `claude/config/settings-template.json`)
   - Workstream artifacts (seeds, dispatches, plans, transcripts)
   - Coordination artifacts (`usr/*/dispatches/`, `usr/*/history/`, `usr/*/reports/`)
   - Tests (`tests/`)
3. **Suggested commit boundaries** — N proposed commits with:
   - File list
   - Suggested message (drawn from file paths + agent identity)
   - Whether it needs QG (`/git-safe-commit`) or coordination (`/coord-commit`)
4. **Things to exclude from R1** — files that look like they were left over from prior work, untouched in the current session, or are tmp/scratch
5. **PR shape** — branch name, base branch, draft status, suggested title and summary

## Why it matters

Captain does this analysis manually every release. Today's analysis took ~5 minutes of careful reading and produced a 5-commit grouping. With multiple releases per day, that's pure overhead — and prone to drift between releases (different captains might group differently). A tool gives consistent, fast, reviewable output.

It also unblocks **agents** doing their own releases (devex, iscp, etc.) — they'd run `release-plan` in their worktree to get the same analysis without needing captain.

## Sketch of usage

```bash
./claude/tools/release-plan
# → produces a markdown plan to stdout, or writes to .claude/.tmp/release-plan-{YYYYMMDD-HHMM}.md

./claude/tools/release-plan --apply
# → actually creates the branch, stages and commits per the plan, and opens a draft PR

./claude/tools/release-plan --since {ref}
# → consider only changes since {ref} (default: origin/main)
```

## Design questions for /define

1. **Heuristics vs machine-learned grouping.** Heuristics from file paths are simple and explainable. ML grouping is fancier but harder to debug. v1 should be heuristic-only.
2. **How does it know what's "current session" vs leftover from prior work?** Use `git stash` timestamps? Modification time vs session start? Commit-hint-from-message? Hard problem.
3. **Does it auto-write commit messages?** Or just propose? I'd say propose and let captain edit before applying.
4. **Integration with `/git-safe-commit`**. Each proposed commit should be runnable through `/git-safe-commit` so QG attribution stays consistent.
5. **Integration with `/sync-all`** and the Day-PR Release Pattern. Release plan is the *input* to building the day-N-release-M branch.
6. **Should it be invokable by any agent or captain-only?** Probably any agent for their own worktree's release.

## Related work

- **Day-PR Release Pattern** (shipped Day 32) — `day{N}-release-{M}` branches as drafts. release-plan would automate the branch construction.
- **`/pr-prep` skill** — runs the QG before creating a PR. release-plan would run *before* `/pr-prep` to determine WHAT goes in the PR.
- **`/coord-commit` skill** — for committing coordination artifacts without QG. release-plan would emit `coord-commit` calls for the artifact group.
- **`/git-safe-commit` tool** — release-plan emits `git-safe-commit` calls for content groups.
- **`stage-hash` tool** — release-plan can use stage-hash to verify each proposed commit.

## Slot

This is **the natural follow-on to `agency-issue`** — both are "captain manually does X, that should be a tool" patterns. Build when there's a quiet moment in the R1/R2 cycle. Not blocking anything.

## Conversation source

Captured during Day 33 R1 work, after captain produced a manual 5-commit grouping for the day's release. Principal: *"That should be a tool!"*
