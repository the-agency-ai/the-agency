---
type: release-notes
from: the-agency/jordan/captain
audience: any adopter or captain of the-agency framework
date: 2026-04-23
window:
  start_version: v46.13
  end_version: v46.22
  wall_clock_start: 2026-04-21T11:02:29Z
  wall_clock_end: 2026-04-22T06:13:37Z
prs_landed_count: 9
generated_by: agency-captain-release-notes v1.0.0
---

# Release Notes — the-agency v46.13 through v46.22

**From:** jordan-captain (the-agency/jordan/captain)
**Audience:** any adopter or captain of the-agency framework
**Window:** 2026-04-21T11:02:29Z through 2026-04-22T06:13:37Z (9 PRs)

---

## TL;DR

Nine PRs landed on the-agency main between 2026-04-21 and 2026-04-22, advancing the framework from **v46.13 → v46.22**. Headline themes: **V5 plan rollout begins** (src/ split, Python build tool, plan captured to repo), **release-automation hardening** (C#372 A+B+C+D stack fixes), **great-rename-migrate fleet tool** (unblocks adopters pulling new monofolk-style rename into their forks), **README + legal framing** (Quick Start, Stay-Current rationale, joint copyright, trademark footer), plus **housekeeping QG** on PR #362 follow-up.

New upstream tool + skill landing this note: **`agency-captain-release-notes`** (this file's generator) — see #426 on branch `feat/agency-captain-release-notes`.

---

## PRs landed

| PR  | Merged (UTC)         | Author         | Title                                                  |
| --- | -------------------- | -------------- | ------------------------------------------------------ |
| #406 | 2026-04-21T12:45:31Z | jordandm | fix(c372): release-automation gap — A+B+C+D 4-fix stack → v46.14 |
| #410 | 2026-04-21T14:31:57Z | jordandm | fix(bucket-g1): great-rename-migrate tool — fleet unblock v46.15 |
| #397 | 2026-04-21T14:45:53Z | jordan-of | fix(housekeeping): QG findings on PR #362 follow-up — cp-safe C-1/S-2, skill-audit C-3, captain-* DMI body sweep S-4, test coverage T-1 |
| #411 | 2026-04-21T14:59:48Z | jordandm | fix(v5-phase-3): prune cruft + restore agency-whoami stub + audit report — v46.17 |
| #416 | 2026-04-22T01:34:19Z | jordandm | fix(housekeeping): cross-repo migration + iteration archive delete + msg-ref sweep — v46.18 |
| #418 | 2026-04-22T02:15:29Z | jordandm | fix(v5): Phase 4a src/ split + Phase 5a Python build tool + 18 BATS + diff-hash fix — v46.19 |
| #421 | 2026-04-22T03:45:49Z | jordandm | docs: README Quick Start + What you Get + agency update + This Repo Structure (v46.20) |
| #422 | 2026-04-22T04:18:03Z | jordandm | docs + legal: stay-current README framing + joint copyright + trademark footer (v46.21) |
| #423 | 2026-04-22T06:13:28Z | jordandm | docs: capture V5 plan into repo (agency/workstreams/agency/) + manifest 46.22 |

---

## Cross-repo / shared-package changes

### V5 Phase 4a — `src/` split (#418)

The framework internals moved under `src/` — a staged structural move toward the V5 layout. Adopters pulling via `agency update` will see:
- Tests relocated under `src/tests/tools/`
- Internal modules relocated under `src/lib/` (from `agency/tools/lib/`)
- `diff-hash` + other tools updated to respect the new paths
- 18 new BATS tests cover the transition

### V5 Phase 5a — Python build tool (#418)

New Python-based build surface introduced, starting the shift off pure-bash for framework-internal composition work. Adopters: no action until Phase 5b binds user-facing commands to it.

### `great-rename-migrate` tool (#410)

New bucket-g1 tool at `agency/tools/great-rename-migrate` — unblocks adopters who want to pull a `claude/` → `agency/` rename convention into their forks without manually walking every hookify symlink + REFERENCE path. Fleet-wide unblock for the Great Rename convention adoption.

### Release automation (C#372 A+B+C+D stack — #406)

Four-fix stack addressing the release-automation gap that blocked previous v46.13 retry:
- Fix A: post-merge-state detector
- Fix B: captain-release refuses when prior release is in pending-post-merge
- Fix C: captain-release-post-merge always cuts the release after merge
- Fix D: coverage tests hold the invariants

Adopters running `/captain-release` will now see a precondition check ("prior release is pending post-merge — run `/pr-captain-post-merge <PR>` first"). This is intentional — a safety gate you can't skip.

### Housekeeping QG follow-up (#397)

PR #362's QG findings absorbed:
- **cp-safe C-1/S-2**: additional path-traversal + symlink-escape guards
- **skill-audit C-3**: widened to catch skills missing `captain-` prefix on captain-only operations
- **captain-* DMI body sweep S-4**: removed `disable-model-invocation: true` from captain skills (see `REFERENCE-SKILL-CONVENTIONS.md` §1 — DMI blocked captain from invoking captain-scoped skills in their own session)
- **test coverage T-1**: filled gaps

### README + legal framing (#421, #422)

- Quick Start section with curl-bash one-liner + minimal-setup + first-session walkthrough
- "What you get" feature bullets
- Stay-Current rationale for pulling `main` vs pinning a tag
- Joint copyright with community contributor attribution
- Trademark footer

---

## Master behavioral changes

- **V5 plan** captured to repo (#423) at `agency/workstreams/agency/` — adopters can now see the full V5 roadmap (src/ split complete, Python build tool started, reamining phases enumerated). Useful context for captains deciding when to pull mid-rollout vs wait.
- **DMI removed from all captain skills** (#397 S-4): `disable-model-invocation: true` no longer appears in captain skill frontmatter. If your captain skill had it copied from a pre-v46.15 template, update on next skill edit. Behavior unchanged for end-users.
- **Captain-release precondition tightened** (#406 Fix B): `/captain-release` refuses if the prior release is in pending-post-merge state. Expected next action is `/pr-captain-post-merge <pending-pr>` first.
- **Release notes convention introduced** — in-flight on `feat/agency-captain-release-notes` (#426), not yet merged. Adopters: once merged, any captain can run `/agency-captain-release-notes` to broadcast what landed.

---

## Open items / flags

- **#425 open:** `agency-bootstrap.sh` has no first-class `--initial-push` escape hatch for fresh repos. Adopters bootstrapping a brand-new private repo hit the git-captain "Push to main is blocked" block. Workaround: `AGENCY_ALLOW_RAW=1 git push -u origin main` once. Suggested fix: dedicated `git-captain initial-push` subcommand that only succeeds when `origin/main` does not yet exist. Filed from monofolk captain during `ordinaryfolk/of-legacy` bootstrap on 2026-04-23.
- **#426 open (this upstream):** `agency-captain-release-notes` tool + skill — awaits review + merge.
- **V5 Phase 5b+ pending**: Python build tool bound to user-facing commands. Status in `agency/workstreams/agency/` plan.
- **Great Rename fleet roll:** `great-rename-migrate` (#410) is available; adopters ready to adopt the convention can run it. Not forced.

---

## In-flight (not yet PR'd)

- **`agency-captain-release-notes`** on `feat/agency-captain-release-notes` (#426) — this tool + skill. 8/8 bats tests pass.
- **V5 Phase 5b+** — Python build tool bound to user-facing commands. Plan captured at `agency/workstreams/agency/`.

Other work not visible from this captain's window — other captains' work on their own branches may be accumulating separately.

---

## Coordination requests

1. **Review + merge #426** (`agency-captain-release-notes`) — first real-world use (monofolk v3.3-v3.31, 28-PR window) validated the shape. Feedback welcome on default audience copy, frontmatter fields, placeholder sections.
2. **Review + merge #425 (once someone picks it up)** — `git-captain initial-push` would make fresh-repo bootstrap adopter-friendly.
3. If other captains are already writing release notes in their forks (monofolk or otherwise), please share the shape you've converged on — this is a new convention and input helps us calibrate before hardening.

---

— jordan-captain
_generated by `agency-captain-release-notes` v1.0.0_

