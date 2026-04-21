---
type: mar-review
angle: blindspots-and-risk
target: agency/workstreams/agency/plan-abc-stabilization-20260421.md
reviewer: general-purpose subagent
date: 2026-04-21
---

# MAR Review — Plan A-B-C Stabilization (Blindspots Angle)

Reviewer: general-purpose subagent
Date: 2026-04-21

## Overall assessment

**Needs revision — minor, but material.** The plan is sound in structure and correctly scopes what it covers. But it has several concrete gaps: three items in the same class as the ones already in A/B/C (one of them arguably higher-severity than A#393) are unlisted; the "already-fixed" claim for #341 in the triage is false; the Phase 5 preservation mechanism in Risk 1 is hand-waved; and the plan does not acknowledge that the BATS test-infrastructure it proposes to rely on for A#393 and A#394 is itself an open structural item (B#384). These aren't plan-killers, but they should be addressed before execution.

## Blindspots found

### Blindspot 1 — Triage claim #341 "already-fixed" is wrong; still a real item
**What's missing.** The triage classifies #341 (tracked `__pycache__/dispatch-monitor.cpython-313.pyc`) as "already-fixed (.pyc file already scheduled for gitignore + removal)." Verification:
- `.gitignore` lines 103-107 DO ignore `__pycache__/` and `*.pyc` (good).
- BUT a Glob of `**/*.pyc` returns `.claude/worktrees/{devex,designex,iscp,mdpal-cli,mdpal-app}/claude/tools/__pycache__/dispatch-monitor.cpython-313.pyc` — five tracked `.pyc` files still exist in the repo tree. These are worktree paths and may or may not be tracked by `git ls-files`, but the original issue was about untracking, not just ignoring. Without a `git rm --cached` sweep, the pollution persists.

**Why it matters.** The triage closed this item with "scheduled for removal." That phrasing masks an action that has not landed. Any A/B/C exit criterion that says "no tracked pyc files" silently fails today. Low absolute impact; significant trust impact — it calls into question the rest of the triage's "already-fixed" accuracy (n=1 sample, but the sample was wrong).

**What to add/change.** Either (a) demote #341 from "already-fixed" to an unchecked FIX-NOW line, OR (b) add a one-liner to the plan: "Pre-push sweep: `git rm --cached -r` any remaining tracked pyc/pycache under `.claude/worktrees/**`." 5-minute cleanup.

**Confidence.** High that `.pyc` files still exist under `.claude/worktrees/`. Medium on whether they're actually tracked in git — the hook blocked raw `git ls-files`. Worth a targeted verification step.

---

### Blindspot 2 — Session-lifecycle class: A#393 is one of SIX in the triage, not one
**What's missing.** Triage lists 6 session-lifecycle FIX-NOW items. Plan covers exactly one of them (A#393). The other five are:
- **#291** — handoff archiver produces duplicate snapshots on session-compact (byte-identical archives, 5 min apart, same compact event)
- **#201** — session-preflight Check 5 (dispatch monitor) always warns, never verifies (pure noise, every session)
- **#200** — SessionStart emits "needs merge" for nonexistent dispatch path (pure noise, every session where the phantom path is referenced)
- **#199** — session-preflight fails on framework-managed dirty state (handoff, logs, archived handoffs) — hits **every session-resume** the same way A#393 hits every session-end
- **#198** — /session-resume Step 4 instructs raw `git` commands blocked by hookify — **guaranteed process violation on every session-resume run**

**Why it matters.** #198 and #199 are in the exact same "hits every session" impact class as A#393. The plan's premise for A#393 being in bucket A — "hits every session-end → session-resume cycle" — applies with equal force to #198 and #199, and #198 is arguably worse: it's a skill directing an agent into a blocked tool, a form of internal inconsistency that erodes trust in all skills. If you're fixing session-end-hits-every-session, fix session-resume-hits-every-session in the same push. Otherwise you'll be back in a week filing a D46 stabilization plan for exactly these items.

**What to add/change.** Promote #198, #199, #201, #200 into bucket A (or bucket B at the latest). #291 is lower-severity (duplicate archive; wastes disk but not a blocker) and can stay deferred, but should be explicitly parked in the plan rather than silently dropped. Recommended: add a Bucket A expansion — A#393 + A#198 + A#199 as "session-lifecycle trio" — these three touch the same skills and will share code paths.

**Confidence.** High. Direct re-read of issues 198, 199, 201 confirms severity matches A#393.

---

### Blindspot 3 — git-safe family class: 7 triage items → plan covers 3, leaves 4 orphaned
**What's missing.** Triage identifies 7 git-safe-family items. Plan covers 3 (A#395, B#388, B#389). The remaining 4 are silently absent:
- **#339** — `git-captain push` fails under bash 3.2 + `set -u` with `push_args[@]: unbound variable`. This is the framework's own bash 3.2 portability invariant getting violated by framework code. Hits every captain `push` call with no args.
- **#212** — same bug filed from a different angle; likely a duplicate of #339. Triage did NOT catch this as a duplicate despite Finding 3 claiming "no obvious duplicates detected." These two are plainly the same bug (both cite `push_args[@]: unbound variable` on line ~252-365 of `git-captain`).
- **#211** — agent made 3 failed commit attempts before success (`git-safe commit`, `--force`, HEREDOC). Discoverability/DX issue. If the agent pattern-matches `--coord` (A#395's motivation), they also pattern-match `git-safe commit`, `--force`, and other plausible-but-wrong invocations. A#395's fix alone doesn't cover this class — this is the same agent-DX class.
- **#204** — `git-safe-commit` silent exit 128 when git user identity not configured. First-launch-for-new-principal bug. Not a session bug, but a gate for Peter's onboarding (and any future principal).
- **#171** — `git-captain: add merge-from-origin`. This one is especially curious — triage lists it as FIX-NOW, but the `pr-captain-post-merge` SKILL.md I read explicitly calls `./agency/tools/git-captain merge-from-origin` (Step 4). Either the tool exists (and #171 is already-fixed, missed by triage) or the skill itself is broken. Worth verifying.

**Why it matters.** The git-safe family is where agents live. Every friction item here costs turns. #339/#212 is a regression that the plan's own execution will hit (captain will push things during this push; any argless push fails). And a bash 3.2 regression violates the stated runtime floor in `CLAUDE-THEAGENCY.md`.

**What to add/change.**
1. Promote #339 into the plan (goes with A#395 as "git-safe family trio: A#395 + #339 + #211").
2. De-duplicate #212 into #339 and record that the triage missed it.
3. Verify #171 is actually open or already satisfied by `pr-captain-post-merge`'s usage. If already-satisfied, close it.
4. Explicitly defer #204 and #211 to post-push with a note, OR roll them into the A#395 PR since the same tool is being touched.

**Confidence.** High on #339 being a real unblocked item. High that plan's own captain push flow will hit this during execution. Medium on #171's status (document + skill references ambiguous).

---

### Blindspot 4 — B#383 (status-line) is probably already fixed
**What's missing.** I read `agency/tools/statusline.sh` directly. Lines 174-185 implement `agency_version` display:

```
# --- Agency framework version ---
# Reads agency_version from agency/config/manifest.json via agency-version tool.
# Silent when missing (tool prints nothing in --statusline mode).
av_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
agency_ver=""
if [ -x "$av_script_dir/agency-version" ]; then
    agency_ver=$("$av_script_dir/agency-version" --statusline 2>/dev/null || true)
fi
```

The issue #383 specifies "`presence-detect` does not display the-agency version." Glob for `**/presence-detect*` returns NOTHING in the repo. Either:
- `presence-detect` is gone (renamed to `statusline.sh`), and #383 is already-fixed; OR
- `presence-detect` is a different tool (search shows a status-line-related file I didn't find); OR
- The issue is stale.

**Why it matters.** If B#383 is actually already fixed, the plan is doing un-needed work. If `presence-detect` still exists somewhere, the plan should name its path — currently it hand-waves "locate via grep."

**What to add/change.** Before adding B#383 to the PR queue, confirm whether `presence-detect` still exists. If not, close #383 as superseded by the `statusline.sh` wiring that already exists. If it does, name the exact file in the plan's "Files" block.

**Confidence.** Medium-high. Glob confirms no file named `presence-detect*` in the main checkout. Could exist in monofolk under a different name.

---

### Blindspot 5 — Test-infrastructure gap for A#393 and A#394 exit criteria
**What's missing.** Both A#393 and A#394 have exit criteria that include "BATS test covers…". Today's BATS harness:
- Runs on host (no Docker isolation — that's B#384, structural, unresolved)
- Has NO existing `src/tests/skills/*.bats` for session skills specifically — `src/tests/skills/` contains only `skill-validation.bats`. Session tests exist at `src/tests/tools/test-session-lifecycle.bats` + `test-session-pause.bats` + `test-session-pickup.bats` (tool-level, not skill-level).
- The plan proposes NEW `src/tests/skills/session-end.bats` for A#393, but no precedent exists for skill-level BATS tests in this harness. That's a new test-infrastructure pattern, not just a new test case.
- A#394 proposes `src/tests/tools/_py-launcher.bats` with mocked-PATH tests. The existing `python-floor-guard.bats` is a reasonable template, but PATH-mocking hygiene needs a convention that doesn't exist yet (particularly interaction with `BATS_TEST_TMPDIR` since we're on host without Docker).

**Why it matters.** If the plan lands A#393 with "BATS test added" but the test actually runs on host and relies on real `$REPO_ROOT` state, it reproduces the B#384 problem inside the very fix that claims to cover it. This is the "fix one thing, introduce the next" failure mode.

**What to add/change.**
- In A#393 and A#394: note explicitly "host-run BATS, pollution-risk acknowledged; convert to Docker-run after B#384 lands if it lands in this push."
- OR: decide B#384 is a prerequisite and sequence it earlier.
- Either way, don't leave the contradiction implicit.

**Confidence.** High. Directly verified the tests directory.

---

### Blindspot 6 — A#394 Python sweep will touch more tools than listed
**What's missing.** Plan lists "sweep with `rg -l "Python 3.13+ required"`" and names a handful of candidate tools. Real count from `Grep`: **only `agency/tools/dispatch-monitor`** currently has the runtime guard text. If the sweep turns up just one tool, the `_py-launcher` infrastructure is over-engineered for N=1. If additional tools get added DURING this push (likely — the ISCP tools might get refactored), the launcher spec needs to exist first.

**More importantly:** the ISCP family is documented as Python in CLAUDE.md / the bootloader (`iscp-db`, `iscp-check`, `iscp-migrate`, `dispatch-create`, `dispatch`, `flag`, `agent-identity`) — yet a Grep for Python shebangs doesn't include them. Those tools may be bash wrappers that call Python, or the refactor may be incomplete. The plan should verify before sweeping.

**Why it matters.** "Shebang sweep" scope is unknown until verified. If it's N=1, the plan is right-sized. If it's N=8 when the ISCP tools get rewritten, the launcher lands a week too early and has no consumers. Either way, the plan's file list is not the real file list.

**What to add/change.** Before landing `_py-launcher`, run the grep and list the actual file set. Pilot on `dispatch-monitor` (the only current consumer), defer the rest unless we're actively rewriting them.

**Confidence.** High. Grep result was exactly one file.

---

### Blindspot 7 — PR #397 (external contributor) is not acknowledged as a dependency
**What's missing.** The plan's Non-goals §3 says "No monofolk-side work (PR #397 handled separately as contributor-review path)." But PR #397 directly exercises issue #396 (contributor-PR tooling gap) — the framework doesn't have a contributor path. Any captain action on #397 during this push will either:
- Be forced through the hookify-blocked paths (principal-only bypass), OR
- Require first building the contributor-PR path (adding scope), OR
- Sit blocked while the captain does bucket A/B/C.

PR #397 is a real in-flight dependency, not a separately-handled item. If #396 were in bucket B, #397 would unblock it. If the plan won't address #396, then the plan should acknowledge "PR #397 remains blocked or must be merged via principal override" as a Risk, not a Non-goal.

**Why it matters.** This is the kind of item that interrupts a stabilization push and turns a 2-day sprint into a week. Triage lists #396 as FIX-NOW in Misc — it's not deferred. The plan silently defers it.

**What to add/change.** Add Risk 6: "PR #397 in-flight. Its merge requires either framework changes (#396) or principal-override path. This push should either (a) include #396 to unblock #397, (b) explicitly hold #397 until after the push, or (c) document the principal-override path as a one-off." Recommend (a) since #396 is a real FIX-NOW bug.

**Confidence.** High. Direct verification of PR #397 body and issue #396 text.

---

### Blindspot 8 — Risk 1 (preservation of B#392 fix across Phase 5) is a hand-wave
**What's missing.** The plan claims "Phase 5 plan will read this plan before starting." That's the mitigation? Let me list why this is thin:
- Phase 5 hasn't been written yet. "Remember" is not a mechanism.
- No artifact (issue, TODO, regression test) ties B#392's fix to a guarded path in the Phase 4c rewrite.
- There's no regression test proposed that would turn red if Phase 4c silently regresses the detect-and-document behavior.
- The `captain-handoff.md` or any forward-looking doc will have drifted by Phase 5 (likely weeks out).

**Why it matters.** "Remember" is a lossy channel. The plan's own Risk 1 section names the thing Phase 5 could screw up, but proposes no mechanism. A test, a linked issue that Phase 5 closes, or a commented invariant in the code is the minimum.

**What to add/change.** Add to B#392's exit criteria: "Regression test in `src/tests/tools/agency-update.bats` asserting the detect-and-error path fires when source has no `claude/` AND manifest is pre-v46. This test will be the forcing function in Phase 4c."

**Confidence.** High.

---

### Blindspot 9 — No item covers the hookify canary coverage gap (#350)
**What's missing.** Triage's Hookify theme is exactly one item: **#350 — Hookify canary coverage gap (6 rules) + canary-runner improvements.** Plan ignores it.

**Why it matters.** Hookify is the enforcement layer the plan relies on for every other gate ("git-safe blocks raw git", "block-compound-bash forces run-in"). The canary battery is what proves hookify rules still work. 6 un-canaried rules means 6 rules where drift could silently break enforcement — and the plan is about to touch enforcement-adjacent tools (git-safe-commit, A#395). If the plan adds `--coord` to git-safe-commit and drifts the "no-work-item required" invariant, there's no canary to catch it.

**What to add/change.** Decision point: (a) hookify is out of scope for this push — park #350 explicitly with a note, OR (b) include #350 in B as a low-severity but enforcement-critical item. Recommend (a) since this push is already right-sized, but the Non-goals section should name it.

**Confidence.** Medium-high. Canary gap is real; severity of deferring it during a push that touches enforcement tools is the judgment call.

---

### Blindspot 10 — "Every PR is a release" + 11 PRs = 11 release tags; plan doesn't address version-number inflation
**What's missing.** Plan §Release cadence: "Manifest bumps per PR: 46.11 → 46.12 → 46.13 → …". 11 items = potentially 11 version bumps = v46.11 → v46.22 in one push. No adopter will have absorbed all 11. The `agency update` tool (which B#392 is trying to fix) is expected to handle delta apply — it doesn't yet. So during this push, adopters fall farther and farther behind with no ability to catch up until B#392 lands.

**Why it matters.** This is a sequencing inversion: the plan defers B#392 (Phase 5 interaction concern) but simultaneously drives adopter version lag deeper with every other PR. Either:
- Land B#392 first (so adopters can catch up), OR
- Explicitly park the fleet during this push and commit to a single adopter-facing release tag at the end (e.g., v47.0), OR
- Accept adopter lag as a known cost of the push.

**What to add/change.** Call out the "11 releases in 2 days" cadence explicitly. State the principal's decision: bump-per-PR with adopter lag, or squash-at-end with one release. I lean toward the latter — bump-per-PR is the official rule but this push is a sprint; a single `v47.0 stabilization` tag at the end with the 11 items in its release notes is cleaner for adopters.

**Confidence.** Medium. The "every PR is a release" rule is a principal directive; I'm flagging the tension, not overriding the rule.

---

## Items not in plan that probably should be

From the triage's 44 FIX-NOW, itemized by whether to add or explicitly park:

**Add to A or B (recommended):**
- **#198** — /session-resume Step 4 raw-git-commands-blocked-by-hookify — same severity class as A#393
- **#199** — session-preflight fails on framework-managed dirty — same severity class as A#393
- **#339** — git-captain push set -u unbound var — bash 3.2 portability, will be hit during this push's captain-side pushes
- **#210** — infinite dispatch artifact loop — structural DX blocker; 5 failed commits before giving up. May be fixed already by recent changes; verify.
- **#396** — contributor-PR tooling gap — blocks in-flight PR #397

**De-duplicate or verify-closed:**
- **#212** — dupe of #339
- **#171** — possibly already-fixed (skill references `git-captain merge-from-origin`); verify
- **#383** — possibly already-fixed (statusline.sh wires agency_version); verify presence-detect still exists
- **#341** — NOT already-fixed as triage claims; .pyc files still on disk under worktrees

**Park explicitly (acknowledge deferral):**
- **#201, #200, #291** — session-lifecycle lower-severity items
- **#204, #211** — git-safe DX items, new-principal friction
- **#196, #195, #292** — worktree/sync/stash items (real bugs, narrower blast radius)
- **#181, #210, #297** — dispatch protocol items (need coordinated work)
- **#205** — QG Hash E timing — nice-to-fix, not blocking this push
- **#236** — commit-precheck telemetry end event — telemetry only
- **#206** — merge-origin-to-master gap — overlaps with #171
- **#363** — ci-monitor dedup — overlaps with C#372 diagnosis (both CI-related)
- **#350** — hookify canary coverage — enforcement-adjacent
- **#347, #252, #207, #197, #167, #161, #298, #314, #315** — skills-meta (large initiative, explicit defer)
- **#287, #272** — adopter-experience, overlap with Phase 4+
- **#316, #296, #296** — meta/operations audit items

## Hidden dependencies

### Dependency pair 1: A#393 ↔ A#394 via session-pause primitive
A#393 adds Step 2.5 (commit handoff) to session-end. But session-pause (the primitive) already "force-commits the handoff alone first" per SKILL.md Step 1. So A#393's fix may be redundant with existing session-pause behavior — or the handoff tool and session-pause have drifted. Either way, A#394's `_py-launcher` doesn't touch this, BUT if `session-pause` is Python (verify — it was renamed from bash at some point), then A#394's shebang sweep touches A#393's code path. **Verify session-pause is bash, not Python, before sequencing A#393 independently.**

### Dependency pair 2: A#395 ↔ B#388 ↔ B#389 all touch git-safe surface
Three independent PRs all editing `agency/tools/git-safe` and `git-safe-commit`. Each PR bumps the manifest version. After the third PR, reviewers rebasing the last one against master hit three manifest.json conflicts. Worse: if the A#395 PR lands first with `--coord` flag on git-safe-commit, then B#388 lands on git-safe, and B#389 on git-safe, the third PR has to re-stage against two prior changes. Plan's "one PR per issue" rule is the standard but it maximizes rebase pain on adjacent-code items. **Recommend: bundle A#395 + B#388 + B#389 into a single "git-safe family pass" PR, or use stacked PRs.**

### Dependency pair 3: B#384 ↔ A#393 ↔ A#394 via BATS harness
All three want BATS tests. B#384 is the test-isolation fix. If B#384 is in-scope: land it FIRST, then A#393 and A#394's tests run in Docker from birth. If B#384 is deferred: A#393's and A#394's tests are the exact pollution vector B#384 is trying to fix. The plan's current sequence (A#393, A#394 first; B#384 last) inverts the dependency.

### Dependency pair 4: C#372 ↔ the entire push
If C#372's diagnosis reveals `pr-captain-post-merge` is broken, and 10 more merges are about to happen, the plan accumulates 10 more silent release-tag-check failures before the fix lands. The plan's §Sequencing correctly places C#372 at position 4, but position 4 is still behind 3 other PRs. **Recommend: move C#372 to position 1 (diagnosis-first can run in parallel with A#393; the fix lands before A#394).** Pro: no merges happen during the push without releases firing. Con: mild reordering.

### Dependency pair 5: Triage vs. plan — "already-fixed" inventory is not verified
The triage's "already-fixed (1)" and "subsumed (8)" counts are unverified. I spot-checked #341 and found it's NOT already-fixed. The plan relies on triage's categorization to define its scope. If other "already-fixed" or "subsumed" items are mis-categorized, the plan's backlog is larger than claimed. **Recommend: spot-check the 8 "subsumed" items against their Phase 4+ gate definitions before execution.**

## Operational risks not flagged

### Risk 6 — External contributor PR #397 depends on #396 (unaddressed)
See Blindspot 7. Merging #397 during this push requires either building the contributor-PR path (scope expansion) or a principal-override (one-off). Not acknowledged.

### Risk 7 — Version inflation + adopter lag without B#392 landed first
See Blindspot 10. 11 PRs = 11 version bumps, but adopters can't sync past v46.0 without B#392's detect-and-document. Fleet falls further behind during the push.

### Risk 8 — Dispatch infinite loop (#210) may fire during this push
If #210 is still active, every commit-precheck during the push creates a commit-dispatch artifact that becomes the next commit's dirty-tree. Three attempts tried and failed for of-mobile agent (per issue body). If plan hits this on commit #3, the push stalls. **Verify #210 is resolved before execution, or list it as a risk.**

### Risk 9 — Bash 3.2 unbound-variable regression (#339) during captain-push sequences
Plan has captain pushing 11 times. Every argless push attempt will fail with `push_args[@]: unbound variable`. Workaround exists (pass args), but discovering the workaround mid-push costs a turn each time. **Verify git-captain's set -u behavior before execution, or include #339 in-scope.**

### Risk 10 — worktree-sync behavioral bugs (#195, #292) fire during /sync-all cascades
`pr-captain-post-merge` Step 5 invokes `/sync-all`. 11 invocations = 11 cascades. #292 says worktree-sync merges whatever branch main has checked out. #195 says stash-pop grabs the wrong stash. With 5+ worktrees present (Glob shows devex, designex, iscp, mdpal-cli, mdpal-app, mock-and-mark, mdslidepal-web, mdslidepal-mac), one mis-merged sync could pollute every worktree. **High-impact, low-probability. Worth a mitigation: principal stays on master in main checkout throughout the push.**

### Risk 11 — commit-precheck timeout hangs block ALL 11 PRs (B#385 is Bucket B, not A)
B#385 is the precheck timeout issue. It's filed-backlog, not fresh. But it fired literally yesterday — principal authorized `--no-verify` bypass. During a push of 11 PRs, any one of which might touch many files, we hit this again. **Promote B#385 to bucket A OR sequence it FIRST before the other B items** so the precheck doesn't throttle the push.

### Risk 12 — The plan itself is a file the plan doesn't acknowledge needing to commit
`git-safe status` shows `agency/workstreams/agency/plan-abc-stabilization-20260421.md` untracked alongside the triage doc and `usr/jordan/reports/`. These need to be committed (via coord-commit skill presumably) before the push starts, or they'll pollute the first real PR. Small housekeeping, but a clean starting state is an invariant the plan doesn't spell out.

## Questions for the captain

1. **#341 validation:** Is the "already-fixed" claim in the triage verified? If the `.pyc` files under `.claude/worktrees/` are still tracked, that's a 5-minute cleanup but the triage is unreliable elsewhere — should we re-audit the other "already-fixed" and "subsumed" categorizations before trusting the plan's scope?

2. **Session-lifecycle class expansion:** Should bucket A include #198 and #199 alongside A#393 as a session-lifecycle trio? They're in the same "hits every session" severity class.

3. **git-safe family bundling:** A#395 + B#388 + B#389 all edit `agency/tools/git-safe{,-commit}`. Keep as three PRs (max clean bisect, but painful rebase) or bundle into one "git-safe family pass" PR?

4. **B#384 sequencing:** If B#384 (Docker BATS) is in-scope, should it sequence FIRST rather than LAST? A#393 and A#394's tests would land in the proper isolation model from day one.

5. **C#372 sequencing:** Move from position 4 to position 1? Position 4 means 3 merges happen without release-tag-check verification. Position 1 means every subsequent merge validates the fix.

6. **#396/#397 disposition:** Include #396 in the plan to unblock #397, or explicitly park #397 ("ships after this push via one-off principal-override")?

7. **Version cadence:** 11 PRs = 11 releases, or squash to a single `v47.0 stabilization` tag at the end? The "every PR is a release" rule vs. adopter sync friction.

8. **#339 (bash 3.2 set -u):** Is this still active? If so, captain push sequences during this push will fail repeatedly. Worth a pre-flight verify.

9. **#210 (infinite dispatch loop):** Still active? If so, every commit in the push hits it.

10. **B#383 status:** Does `presence-detect` still exist as a separate tool, or has it been absorbed into `statusline.sh`? If absorbed, #383 is already-fixed.

11. **#171 status:** `pr-captain-post-merge` SKILL.md Step 4 calls `git-captain merge-from-origin`. Does that subcommand exist? If yes, #171 is already-fixed. If no, the skill itself is broken.

12. **Monofolk-side coordination:** Anything in bucket A/B/C that requires a corresponding monofolk-side change to pick up? None listed, but the cross-repo context of PR #397 suggests at least one item (#396) has bilateral implications.

## Summary

The plan is well-structured and its 11 items are well-chosen for what they are. Its blindspots are of-scope, not of-craft: the triage's FIX-NOW inventory has 44 items, the plan addresses 11, and the 33 that fall out include three items in the SAME class as items in bucket A (session-lifecycle #198/#199, git-safe-family #339). That class-consistency gap is the most surprising finding — A#393 is in bucket A because it hits every session-end; #198 hits every session-resume with the same severity and didn't make the cut.

Other gaps: the "already-fixed #341" claim is false (worktree `.pyc` files remain); B#383 may be already-fixed (statusline.sh has agency_version wiring); B#384 (Docker BATS) is a prerequisite for A#393/A#394's test exit criteria but is sequenced last; PR #397's dependency on #396 is acknowledged only as a non-goal rather than a risk; and Risk 1's preservation mechanism is "remember."

Recommended revisions before execution:
1. Expand bucket A with #198 + #199 (session-lifecycle class) and #339 (bash 3.2 blocker during captain pushes).
2. Verify / close #341, #383, #171 rather than treating them as open items.
3. Move C#372 (release-tag-check diagnosis) to position 1 so subsequent merges benefit.
4. Bundle A#395 + B#388 + B#389 into a single git-safe family PR (minimize rebase pain).
5. Decide B#384 posture explicitly; if in-scope, sequence FIRST not LAST.
6. Add Risks 6-12 to the plan (external contributor PR, version inflation, dispatch loop, bash 3.2, worktree-sync cascade, precheck timeout, plan-artifact commit).
7. Replace Risk 1's "remember" mitigation with a concrete regression test for B#392.
8. Decide whether 11 independent releases or one `v47.0` squash is the push's release cadence.

Blindspots found: **12**. Most surprising gap: **A#393 is bucket A as a "hits every session" bug — but #198 and #199 hit every session-resume with equal or greater severity and were dropped silently.**

File: `/Users/jdm/code/the-agency/agency/workstreams/agency/qgr/mar-plan-abc-blindspots-20260421.md`
