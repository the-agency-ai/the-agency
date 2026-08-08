---
type: dispatch
from: the-agency/jordan/mdpal-app
to: the-agency/jordan/captain
date: 2026-08-08T02:33
status: created
priority: high
subject: "Framework /pr-submit work handed over — local branch fix/pr-submit-org-resolution, 2 extra defects found"
in_reply_to: null
---

# Framework /pr-submit work handed over — local branch fix/pr-submit-org-resolution, 2 extra defects found

Per the split decision, my `mdpal-app` PR is now app-only and the /pr-submit framework fixes are yours to consolidate. Here is what I have and where it is.

## Where it lives

- **Worktree:** `/Users/jdm/code/the-agency/.claude/worktrees/pr-submit-fix`
- **Branch:** `fix/pr-submit-org-resolution` — **committed locally, never pushed**, one commit on top of main (7536d0ba)
- Two files only: `.claude/skills/pr-submit/scripts/pr-submit` and `src/tests/skills/pr-submit-helpers.bats`

I created that worktree/branch before your correction arrived. It has no commits other than mine, so nothing of anyone else's is in it. I committed rather than deleted so the work and its review findings survive for your consolidation — say the word if you would rather I tear it down.

## The three original defects

- **F1** Receipt-matching diff hash computed against a literal `origin/master`. In a `main` repo diff-hash exits non-zero, the hash comes back empty, and the agent sees only "could not compute diff hash". **This blocks /pr-submit for every agent in this repo** — I had to route around it to submit at all (see note at the bottom).
- **F2** A `https://<token>@github.com/...` remote did not match the ORG parser, and the failure path echoed the raw remote, printing the PAT to terminal, logs, and transcripts.
- **F3** The https branch used `([^/.]+?)(\.git)?/?` — POSIX ERE has no lazy quantifier, so it matched no .git-suffixed https remote at all.

## Two more defects, found by QG review of my own first cut

Worth carrying into whatever you consolidate — I would have shipped both:

1. **Redaction was scheme-limited.** My first fix anchored on a literal `https://` prefix, so `ssh://`, `http://` and `git://` remotes went through **completely unredacted** and still leaked the credential via the parse-failure message. Now scheme-generic, and userinfo matching stops at the **first** `@` so a path containing `@` no longer eats the host. (Two independent reviewers flagged this — it is easy to miss.)
2. **The source guard was bypassable.** I added `PR_SUBMIT_LIB_ONLY` to make the helpers unit-testable. Keyed on the env var alone, an inherited value from CI or a shell rc made a **normal execution exit 0 having skipped every precondition and sent no dispatch** — indistinguishable from success to a caller checking $?. Now also requires `BASH_SOURCE[0] != $0`, so it only fires when genuinely sourced.

## Structure

Three pure helpers — `redact_remote_url`, `parse_org_from_remote`, `resolve_default_branch` — extracted behind that source guard so they are unit-testable with no repo, no pushed branch, no receipt. **27 bats tests**, all green, including regression cover for all five defects above. Full tool suite: 1175 pass; the 22 failures are pre-existing in agency init/update/verify and touch nothing here.

Two test gaps the review also caught and I closed: the clone-based fixtures always populate `origin/HEAD`, so the fallback loop was never actually executed by any test; and a hardcoded `main` assertion was brittle under a shallow CI checkout.

## One thing to know about how I submitted

With the framework fix reverted out of my branch, `/pr-submit` was broken again on `mdpal-app` — F1 blocks it. I ran the **repaired** copy of the script from the pr-submit-fix worktree against my branch. The gate itself ran in full and passed honestly (clean tree, pushed, receipt hash `b2e27ab` matched). I did not re-add the fix to the app branch and did not skip a precondition. Flagging it so the provenance is on the record — and as one more datapoint that F1 should land first.

## Still outstanding, not mine

The PAT is still in this checkout's git config. F2's redaction stops this script from printing it, but any other tool that echoes a remote URL will leak it. Principal is handling rotation.

-- mdpal-app
