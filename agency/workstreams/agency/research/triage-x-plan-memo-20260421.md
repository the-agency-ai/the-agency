---
type: research-memo
workstream: agency
date: 2026-04-21
anchors:
  - plan-abc-stabilization-20260421.md
  - issues-triage-20260421.md
status: interim
---

# Triage × Plan Cross-reference Memo

Interim notes captured while MAR agents review the A-B-C plan. This memo surfaces interactions between the plan draft (11 items) and the triage output (44 FIX-NOW items in 10 themes).

## Plan coverage vs FIX-NOW inventory

The plan covers **11 of the 44 FIX-NOW items** (25%). The remaining 33 are Step-3 decision material for the principal.

| Theme | FIX-NOW count | In plan | Not in plan |
|-------|---------------|---------|-------------|
| session-lifecycle | 6 | 1 (#393) | #291, #201, #200, #199, #198 |
| git-safe family | 7 | 2 (#395, #389) | #339, #212, #211, #204, #171 |
| adopter-experience | 3 | 1 (#392) | #287, #272 |
| test-isolation | 2 | 2 (#384, #385) | — |
| ci-cd | 2 | 1 (#372) | #363 |
| python/shebang | 2 | 1 (#394) | #178 |
| skills-meta | 9 | 0 | all (incl. #315 macro-initiative) |
| dispatch | 3 | 0 | #297, #210, #181 |
| hookify | 1 | 0 | #350 |
| misc | 9 | 0 | all |
| **total** | **44** | **11** | **33** |

## Triage classification concerns

### #341 — triage classified "ALREADY-FIXED" but issue is still OPEN with no closing activity
- Body says "Should be gitignored and removed from tracking" — this describes pending work, not completed work.
- `.gitignore` does have `__pycache__/` at line 104, so the pattern is set.
- But `git rm --cached` hasn't been done; the specific file (`usr/jordan/captain/__pycache__/dispatch-monitorcpython-313.pyc` at commit 9867be4c) is likely still tracked.
- **Recommend:** re-classify as FIX-NOW (misc), close with a "git rm --cached" commit.

### "No duplicates found" — needs spot verification
- 167 issues in 5 days with no duplicates is statistically surprising.
- Triage note itself flagged this: "Recommend light duplicate audit before stabilization push, especially on skills-meta and session-lifecycle themes."
- Likely dup candidates worth spot-checking:
  - #393 (session-end handoff) vs #291 (handoff archiver duplicate snapshots) — different symptoms, possibly same root cause in handoff machinery.
  - #388 (`git-safe add` directory rejection) vs #285 (same topic, earlier filing).
  - #389 (`git-safe unstage` shell-meta) vs #284 (`git-safe add -u` filename treatment) — both argument-handling bugs, possibly same fix.
  - #207 + #197 — both about skill-verify false positives on removed allowed-tools.

## Theme-level interactions

### Session-lifecycle is a cluster
A#393 in the plan is one of six session-lifecycle items. Fixing #393 alone may leave #198, #199, #200, #201 as remaining potholes. If we're touching session machinery, a bundled "session-lifecycle-stabilization" PR covering 2–4 of these may be more efficient.

**Candidates for bundling with A#393:**
- #291 (handoff archiver duplicate snapshots) — touches same handoff code.
- #199 (preflight fails on framework dirty state) — directly interacts with #393's clean-tree fix.
- #201 (preflight dispatch monitor always warns) — sibling preflight issue.

**Split out:**
- #198 (session-resume Step 4 raw git) — skill body fix, unrelated files.
- #200 (SessionStart emits 'needs merge' for nonexistent path) — hook issue, different surface.

### git-safe family has known-regression bugs not in plan
Plan covers #395 (flag add), #389 (unstage shell-meta) — both surface issues. Triage surfaces regressions:
- **#339 + #212**: `git-captain push` fails under bash 3.2 + `set -u` with `push_args[@]: unbound variable`. Two issue numbers, probably same bug, **regression** (was working). Critical — it's the captain's push path.
- **#204**: `git-safe-commit` silent exit 128 when git user identity not configured. Silent failure is the worst kind.
- **#171**: `git-captain` missing `merge-from-origin` — captain sync gap.

**Recommend:** B bucket should probably include #339/#212 (dedup first) and #204 — both real regressions.

### Adopter-experience cluster
Plan covers #392 (update chicken-egg). Triage adds:
- **#287**: agency init copies `claude/` wholesale, no install-surface manifest. **Note:** This is literally a precursor to Phase 4a (#374 install-surface manifest schema). Could be the "in-scope test of #374 before committing to full Phase 4."
- **#272**: agency init doesn't wire status line into `settings.json`. Adopter fallback to Claude Code default.

Both are init-time issues. If we ship #392 + #272 in one adopter-experience PR, we help real users who are stuck. #287 is structural and better captured by Phase 4a.

### Skills-meta (9 items, including macro-initiative)
- **#315 is a macro-initiative:** "V1 → V2 skill migration — fleet-scale coordinated refactor (all ~59 V1 framework skills)." Triage agent correctly flagged: treat as separate project, not part of stabilization push.
- **#347 (v2 migration trap: paths scope breaks discoverability)** — actionable bug. Already referenced inline in existing skill docs ("flag #62/#63"). Worth including.
- **#207 + #197**: same underlying issue (skill-verify complains about removed allowed-tools). Likely dupes.

## Recommended plan revisions

Based on this cross-reference, before MAR findings land, candidate plan adjustments:

1. **Add a "D bucket — triage surfaced" section** for items that should come in Step 3 but are natural fits with A/B/C:
   - D#339/#212 (git-captain push regression) — trivially bundleable with B#388/#389
   - D#199 (preflight fails on framework dirty state) — bundles with A#393
   - D#204 (git-safe-commit silent 128) — bundles with B#388/#389
   - D#272 (agency init status line wiring) — bundles with B#392 (or B#383)

2. **Correct triage classification for #341** — move to FIX-NOW misc, include in B as trivial close.

3. **Flag duplicate candidates for review:**
   - #207 / #197 (skill-verify allowed-tools)
   - #388 / #285 (git-safe add directory)
   - #339 / #212 (git-captain push bash 3.2)

4. **Add "session-lifecycle bundle" option** to sequencing: A#393 + #291 + #199 as one PR if principal wants the cluster fixed together.

5. **Acknowledge #315 out-of-scope** explicitly in plan (plan should mention the 59-skill V1→V2 initiative exists and is intentionally deferred).

## Not changing yet

These observations wait for principal review before being folded into a revised plan. This memo is interim; the final revised plan will integrate these after MAR findings also land.

---

*Interim. Will be superseded by revised plan after MAR review and principal Q&A.*
