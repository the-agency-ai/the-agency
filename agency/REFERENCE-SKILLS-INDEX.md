# Skills Index — the-agency framework registry

Authoritative registry of skills in this the-agency install. Captures which skills exist, which `agency-skill-version` they conform to (v1 legacy vs v2), their scope, status, and key framework reference dependencies.

**Kept in sync with reality via `skill-audit` (captain tool).** Drift between this document and the on-disk state of `.claude/skills/*/SKILL.md` is an error — audit reports it, author fixes it.

**This is the definition source:** row here is what the framework considers the skill's canonical state. SKILL.md frontmatter ultimately provides the values, but the registry is the curated + audited view.

## Reading this document

- **Agency-Skill-Version** — `1` (legacy, pre-2026-04-19) or `2` (current methodology per `REFERENCE-SKILL-AUTHORING.md`).
- **Scope** — `agent` (worktree-side), `captain` (main-checkout/master), `both` (invoked from either), `subagent` (only invoked by another skill via Agent/Skill delegation).
- **Status** — `active` (shipped, in use), `pilot` (new, dogfooding), `experimental` (unstable), `deprecated` (use-but-will-retire), `retired` (do-not-use).
- **Required Reading** — basenames of `claude/REFERENCE-*.md` the skill depends on (empty if none).

Framework-level skills discovered by Claude Code live at `.claude/skills/<name>/`. Plugin-supplied skills (e.g., `hookify:*`, `feature-dev:*`) aren't tracked here unless adopted into the-agency framework.

## Version overview

| Version | Count | Meaning |
|---|---|---|
| `2` | 9 | Full v2 methodology — shipped as case studies 2026-04-19 |
| `1` | ~54 | Legacy skills awaiting v2 upgrade |

**Retrofit progress:** `9 / 63 ≈ 14.3%` at v2. Target: all framework-level active skills at v2 before end of the-agency#298 rollout.

## Skills table

Organized alphabetically by name.

| Name | Description | Agency-Skill-Version | Scope | Status | Required Reading |
|---|---|---|---|---|---|
| agency-health | Fleet health check across workstream / agent / worktree dimensions | 1 | both | active | |
| agency-issue | File, view, comment, close issues against the-agency framework on GitHub | 1 | both | active | FEEDBACK-FORMAT |
| captain-log | Append to / read captain's narrative log | 1 | captain | active | |
| captain-review | Review all draft PRs, generate dispatch reports for worktree agents | 1 | captain | active | CODE-REVIEW-LIFECYCLE |
| changelog-watch | Monitor Claude Code changelog for new releases + features | 1 | both | active | |
| code-review | Code-review current branch vs origin/master using 7 parallel review agents | 1 | both | active | QUALITY-GATE, CODE-REVIEW-LIFECYCLE |
| collaborate | Cross-repo dispatch lifecycle (check / read / resolve / reply / push) | 1 | captain | active | ISCP-PROTOCOL |
| coord-commit | Commit coordination artifacts (handoffs, dispatches, seeds, config) without QG | 1 | both | active | HANDOFF-SPEC, ISCP-PROTOCOL |
| crawl-sites | Crawl and extract content from configured sites via provider engine | 1 | both | active | |
| define | Drive toward complete PVR using 1B1 protocol with completeness checklist | 1 | agent | active | DEVELOPMENT-METHODOLOGY |
| deploy | Deploy project via configured platform provider | 1 | both | active | |
| design | Drive toward complete A&D using 1B1 protocol with completeness checklist | 1 | agent | active | DEVELOPMENT-METHODOLOGY |
| diff-summary | Classify git diffs as formatting-only vs substantive | 1 | both | active | |
| dispatch | Manage dispatches — list, read, fetch, reply, create, resolve | 1 | both | active | ISCP-PROTOCOL |
| dispatch-read | Read a dispatch and mark it read — works from any branch or worktree | 1 | both | active | ISCP-PROTOCOL |
| flag | Quick-capture observations to queue for later follow-up or 1B1 | 1 | both | active | ISCP-PROTOCOL |
| flag-triage | Structured flag review — categorize, approve, dispose (3-bucket triage) | 1 | both | active | ISCP-PROTOCOL |
| git-safe-commit | QG-aware commit wrapper — never raw `git commit` | 1 | both | active | SAFE-TOOLS, QUALITY-GATE |
| handoff | Write session handoff using handoff tool — archive, write, verify | 1 | both | active | HANDOFF-SPEC |
| iteration-complete | Run QG after completing an iteration — review, fix, test, report, auto-commit | 2 | agent | active | QUALITY-GATE, RECEIPT-INFRASTRUCTURE |
| monitor-ci | Monitor GitHub Actions CI status via background streaming | 1 | both | active | |
| monitor-dispatches | Event-driven dispatch monitoring via Monitor tool | 1 | both | active | ISCP-PROTOCOL |
| phase-complete | Run full QG after completing a phase — review, fix, test, report, commit | 2 | agent | active | QUALITY-GATE, RECEIPT-INFRASTRUCTURE |
| plan-complete | Complete a plan — final deep QG, finalize artifacts, produce reference doc | 1 | agent | active | QUALITY-GATE, DEVELOPMENT-METHODOLOGY |
| pr-captain-post-merge | Captain-only. Post-PR-merge flow — verify merge, sync master, /sync-all, cut release, cleanup branch | 2 | captain | active | GIT-MERGE-NOT-REBASE, WORKTREE-DISCIPLINE, SAFE-TOOLS |
| pr-captain-land | Captain lands agent's prepared branch — PR + CI + merge + release + notify | 2 | captain | pilot | QUALITY-GATE, WORKTREE-DISCIPLINE |
| pr-captain-merge | Captain-only. Merge PR safely — true merge commit (never squash/rebase), --principal-approved gate | 2 | captain | active | GIT-MERGE-NOT-REBASE, SAFE-TOOLS, CODE-REVIEW-LIFECYCLE |
| pr-prep | Run QG before creating PR — review, fix, test, report, produce QGR receipt | 1 | agent | active | QUALITY-GATE, CODE-REVIEW-LIFECYCLE |
| pr-respond | Fetch PR review comments, compose threaded replies, resolve threads | 1 | agent | active | CODE-REVIEW-LIFECYCLE |
| pr-submit | Agent signals captain that branch is ready for PR landing (Phase 1 pilot) | 2 | agent | pilot | WORKTREE-DISCIPLINE |
| pre-phase-review | Review PVR, A&D, Plan before starting a new phase | 1 | agent | active | DEVELOPMENT-METHODOLOGY |
| preview | Preview project via configured infrastructure provider | 1 | both | active | |
| principal-create | Onboard a new principal — scaffold sandbox, register agent, write CLAUDE-PRINCIPAL.md, mutate agency.yaml | 1 | captain | active | AGENT-ADDRESSING, CONTRIBUTION-MODEL |
| quality-gate | Run the QG — parallel agent review, fix cycle, test, report (composable) | 1 | both | active | QUALITY-GATE, RECEIPT-INFRASTRUCTURE |
| rebase | DEPRECATED — use `git merge <target>` or `/sync` instead | 1 | both | deprecated | GIT-MERGE-NOT-REBASE |
| captain-release | Captain-only. Quality-check, commit, push, create PR, cut release in one flow | 2 | captain | active | QUALITY-GATE, CODE-REVIEW-LIFECYCLE, GIT-MERGE-NOT-REBASE |
| review-pr | Review a PR and post comments after approval (does NOT make code changes) | 1 | agent | active | CODE-REVIEW-LIFECYCLE |
| run-in | Run command in target directory without touching parent shell CWD | 1 | both | active | SAFE-TOOLS |
| sandbox-activate | Activate a sandbox item by symlinking to Claude Code discovery location | 1 | both | active | |
| sandbox-adopt | Graduate sandbox experiment to shared team-wide tooling | 1 | both | active | |
| sandbox-create | Create new experimental command, hook, rule, tool, or script in sandbox | 1 | both | active | |
| sandbox-deactivate | Remove sandbox symlink to deactivate experimental item | 1 | both | active | |
| sandbox-init | Set up a new engineer's sandbox workspace under usr/ | 1 | both | active | |
| sandbox-list | Show all sandbox items across engineers with activation status | 1 | both | active | |
| sandbox-status | Show all active sandbox symlinks and their health | 1 | both | active | |
| sandbox-try | Try another engineer's sandbox experiment by symlinking locally | 1 | both | active | |
| secret | Secret management — set, get, list, delete, rotate, scan via provider | 1 | both | active | |
| service-add | Add a backend service (NestJS) to existing workstream via SPEC-PROVIDER starter pack | 1 | agent | active | |
| session-compact | Mid-session context refresh — commit, write handoff, then compact | 1 | both | active | HANDOFF-SPEC |
| session-end | End session cleanly — commit, write handoff, report readiness | 1 | both | active | HANDOFF-SPEC |
| session-list | List past Claude Code sessions with metadata | 1 | both | active | |
| session-read | Read a past session and produce a structured summary | 1 | both | active | |
| session-resume | Full worktree session startup — sync, handoff, dispatches, report | 1 | both | active | HANDOFF-SPEC, ISCP-PROTOCOL |
| sync | Merge target into current branch + push to origin (the ONLY command that pushes) | 2 | both | active | GIT-MERGE-NOT-REBASE, SAFE-TOOLS |
| captain-sync-all | Captain-only. Fetch, merge origin into master, merge worktree work, sync all worktrees. NEVER pushes. | 2 | captain | active | GIT-MERGE-NOT-REBASE, WORKTREE-DISCIPLINE, SAFE-TOOLS |
| transcript | Real-time conversation capture — records dialogue + decisions as they happen | 1 | both | active | |
| ui-add | Add frontend app (Next.js) to existing workstream via SPEC-PROVIDER starter pack | 1 | agent | active | |
| upstream-port | Port files from source repo to the-agency — auto path mapping, PR creation | 1 | captain | active | |
| workstream-create | Create new workstream with scaffolded artifacts, agent registrations, optional worktree | 1 | captain | active | REPO-STRUCTURE |
| worktree-create | Create new git worktree with dedicated branch + bootstrapped dev env | 1 | both | active | WORKTREE-DISCIPLINE |
| worktree-delete | Remove a git worktree and optionally delete its branch | 1 | captain | active | WORKTREE-DISCIPLINE |
| worktree-list | List all git worktrees with status info (branch, clean/dirty, deps) | 1 | both | active | WORKTREE-DISCIPLINE |
| worktree-sync | Sync worktree with master — merge, copy settings, run sandbox-sync | 1 | agent | active | WORKTREE-DISCIPLINE |

## Retrofit priorities

### Tier 1 — destructive / captain-only

These are the highest-priority refactors. Their behavior is destructive or captain-scoped, so the v2 discipline (disable-model-invocation, narrow allowed-tools, explicit captain-only scope) matters most.

- [x] `pr-merge` → **`pr-captain-merge`** (Case study #3 — **LANDED 2026-04-19**)
- [ ] `pr-create` → **`pr-captain-create`**
- [x] `post-merge` → **`pr-captain-post-merge`** (Case study #4 — **LANDED 2026-04-19**)
- [ ] `release` → **`captain-release`** (unclear if PR-specific or broader)
- [ ] `sync-all` → **`captain-sync-all`**
- [ ] `sync` → keep as-is (push-authorized discipline is in the skill body; name already conveys)
- [ ] `workstream-create` → captain-scope review
- [ ] `worktree-delete` → captain-scope review

### Tier 2 — path-scoped agent skills

Add `paths:` scoping to worktree-only skills.

- [ ] `session-resume` (worktree-only)
- [ ] `handoff` (worktree-authored)
- [ ] `coord-commit` (worktree-authored)
- [ ] `flag` (both but more commonly agent)
- [ ] `dispatch-read` (both)
- [ ] `pr-prep` (agent)
- [ ] `pr-respond` (agent)
- [ ] `pre-phase-review` (agent)
- [ ] `plan-complete` (agent)

### Tier 3 — protocol-heavy skills

Benefit most from full `reference.md` extraction.

- [ ] `quality-gate` (5-hash receipt protocol — huge extraction opportunity)
- [ ] `dispatch` (ISCP protocol)
- [ ] `collaborate` (cross-repo protocol)
- [ ] `captain-review` (review flow)
- [ ] `code-review` (7-reviewer protocol)

### Tier 4 — rest

Low-priority v2 upgrades. Frontmatter additions, body restructuring, registry row sync.

- All remaining v1 skills from the table above.

## Plugin-supplied skills (not tracked here)

These are installed via Claude Code plugins, not authored by the-agency. We do not track them in this registry but list for awareness:

- `hookify:*` (5 skills) — the hookify plugin
- `feature-dev:*` (1 skill) — feature-dev plugin
- Webflow skills (15 skills) — Webflow Claude.ai integration
- Miscellaneous (update-config, simplify, fewer-permission-prompts, loop, schedule, claude-api, init, review, security-review, etc.) — Claude Code native or generic plugins

If we ever absorb one of these into the-agency framework, it gets a row.

## How to maintain this document

**When creating a new skill:** `skill-create` tool adds the row automatically (once built). Until then, add manually.

**When refactoring a skill v1 → v2:** update the `Agency-Skill-Version` column from `1` to `2`. Update `Required Reading` if frontmatter changed. Note in `Status` if pilot/experimental/active shifted.

**When deprecating a skill:** set `Status` to `deprecated`. Retain row; do not delete. Add a note in the skill's `SKILL.md` pointing to the replacement.

**When retiring a skill:** set `Status` to `retired`. Keep row for historical reference.

**Automated verification:** `skill-audit` scans `.claude/skills/*/SKILL.md`, compares against this registry, reports drift. Run before commit if you touched any skill frontmatter.

---

*Initial bootstrap: 2026-04-19 (monofolk). Upstreamed to the-agency same day. Kept current as skills evolve.*
