---
type: dispatch
from: the-agency/jordan/devex
to: the-agency-ai/jordan/captain
date: 2026-08-08T04:06
status: created
priority: high
subject: "READ BEFORE LANDING devex: branch bundles your red test-monitor WIP with my worktree-create fix"
in_reply_to: null
---

# READ BEFORE LANDING devex: branch bundles your red test-monitor WIP with my worktree-create fix

I just sent a /pr-submit for branch devex (HEAD 3f5f42dd). Before you run
/pr-captain-land, please decide how you want this split — I do not think devex
is landable as-is, and I did not want to restructure branches in your lane.

THE PROBLEM
devex..origin/main contains more than my work. It also carries f204bd2e,
'rebuild on main: preserve test-monitor WIP (Iter 1 ~95%, BATS red — tool +
suite + design docs)' — your deliberate preservation commit. That is ~2000
lines: agency/tools/test-monitor, src/tests/tools/test-monitor.bats (red by
its own commit message), fixtures, and three design docs (pvr/ad/plan).
Landing devex ships known-red tests to main.

MY WORK IS EXACTLY THREE COMMITS
  b9a4f89b  fix(worktree-create): resolve origin-only branches
  521a0f01  fix(worktree-create): QG hardening from review
  d9c00a39  qgr: pr-prep receipt + findings and triage
  (3f5f42dd is just draining commit-announce dispatch artifacts)
They touch only: agency/tools/worktree-create, src/agency/tools/worktree-create,
src/tests/tools/worktree-create.bats, and agency/workstreams/devex/qgr/.

WHAT I RECOMMEND
Cherry-pick those three onto a clean branch off origin/main and land that;
leave test-monitor WIP on devex to finish. I could not do this myself —
neither git-safe nor git-captain exposes cherry-pick, and branch surgery is
captain lane. If you would rather I carry it, give me a target branch name and
a sanctioned way to move the commits and I will.

ALSO WORTH KNOWING
- devex is behind origin/main (branch merged local main 7536d0b; origin/main is
  at 8a7b9f6d). The QGR diff-base is origin/main, so the receipt's 42-file diff
  reflects that skew as well as the WIP.
- Full BATS suite is 1179 pass / 326 FAIL, all pre-existing — I verified my
  change adds zero new failures by stash-comparing the affected files
  (identical failure set). agency/tools/tool-create appears to have been
  deleted without removing tool-new-provider.bats, which fails at exit 127
  wholesale. Quantified in flag #224; a red-to-green project is needed before
  'suite green' can function as a PR gate.
- Separate latent bug, flag #225: agency/tools/lib/_path-resolve clobbers a
  caller-supplied AGENCY_PROJECT_ROOT on source, making that documented
  override dead code in any tool that sources it. It put three real worktrees
  in the live devex checkout during my testing before I caught it. I fixed it
  narrowly inside worktree-create only — the shared lib needs a fleet-wide
  audit that I did not want to do unilaterally.
