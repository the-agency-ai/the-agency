# Issues Triage — 2026-04-21
## Summary
- Total open: 167
- Bucket counts: already-fixed 1, duplicate 0, subsumed 8, fix-now 44 (10 themes), defer 114

## SUBSUMED-BY-PHASE-4+ (8 issues)

All 8 Plan v5 Phase 4+ gates are filed as issues for tracking. These will be subsumed by their respective phases and need no independent triage action.

- **#381** — Phase 8 (Plan v5): post-refactor full verification sweep
  *Subsumed by Phase 8 (gate work)*

- **#380** — Phase 6 (Plan v5): first build + commit dual-tracked output
  *Subsumed by Phase 6 (gate work)*

- **#379** — Phase 5 (Plan v5): Python build tool at src/tools/build
  *Subsumed by Phase 5 (gate work)*

- **#378** — Phase 4 (Plan v5): src/agency/ + src/claude/ source-tree establishment
  *Subsumed by Phase 4 (gate work)*

- **#377** — Phase 4d: drift detection — agency update --check + session-resume banner
  *Subsumed by Phase 4d (gate work)*

- **#376** — Phase 4c: refactor agency update to consume install-surface manifest (delta apply)
  *Subsumed by Phase 4c (gate work)*

- **#375** — Phase 4b: refactor agency init to consume install-surface manifest
  *Subsumed by Phase 4b (gate work)*

- **#374** — Phase 4a: install-surface manifest schema + populate (decoupled from src/ split)
  *Subsumed by Phase 4a (gate work)*

## ALREADY-FIXED (1 issue)

- **#341** — Tracked __pycache__/dispatch-monitorcpython-313.pyc in git — gitignore + remove
  *.pyc file already scheduled for gitignore + removal*

## FIX-NOW (44 issues, grouped by theme)

These are independent, actionable bugs and friction items required outside Phase 4+ work.

### Adopter-experience
- `#392` — agency update chicken-egg: adopters on stale update tool can't sync agency/ tree (claude/ → claude/ rsync to non-existent source)
- `#287` — The 'real installer' gap — `agency init` copies `claude/` wholesale with no install-surface manifest
- `#272` — Fresh `agency init` does not wire `claude/tools/statusline.sh` into settings.json — status line shows Claude Code default instead of framework format

### Ci-cd
- `#372` — Release automation gap: pr-captain-post-merge + release-tag-check CI didn't fire for 8 merges today
- `#363` — ci-monitor lacks state-transition dedup — re-emits persistent failures every poll

### Dispatch
- `#297` — Framework bug cluster: 6 bugs surfaced in monofolk (agency update data loss, collaboration tooling, dispatch reply silent drop, vocabulary, monitor stale-read)
- `#210` — Infinite dispatch artifact loop: every commit creates a dispatch, which needs committing
- `#181` — Cross-worktree dispatch delivery corrupts 'from' field — attributes to receiving agent

### Git-safe family
- `#395` — git-safe-commit: add --coord convenience flag (alias for coord-commit happy path)
- `#389` — git-safe unstage refuses paths with shell-meta characters — cleanup gap
- `#339` — `git-captain push` fails under bash 3.2 + set -u with 'push_args[@]: unbound variable'
- `#212` — git-captain push with no args: line 252 unbound variable (push_args[@])
- `#211` — of-mobile agent tried raw git-safe commit, --force flag, HEREDOC message — 3 failures before success
- `#204` — git-safe-commit: silent exit 128 when git user identity is not configured
- `#171` — git-captain: add merge-from-origin (captain sync gap)

### Hookify
- `#350` — Hookify canary coverage gap (6 rules) + canary-runner improvements

### Misc
- `#396` — contributor-PR tooling gap: pr-create assumes internal-captain posture, blocks external contributors via version-bump + receipt-hash lockstep chicken-and-egg
- `#316` — Operations surface audit — gaps + upgrade opportunities across TheAgency / Valueflow / workflow operations (context for #298, #314, #315)
- `#296` — PR lifecycle ownership: distributed between worktree agents and captain — needs captain-owned model
- `#292` — worktree-sync merges whatever branch the main checkout has checked out — can cascade feature branches into every worktree
- `#236` — commit-precheck: emit end event on all failure paths (telemetry gap)
- `#206` — No tool to merge origin/master into local master (post-merge sync gap)
- `#205` — QG Hash E captured before version bump — receipt always mismatches on pr-create
- `#196` — REPORTS-INDEX.md produces merge conflict every time two agents file agency issues on the same day
- `#195` — worktree-sync pops wrong stash after merge conflict, polluting worktree with other worktrees' state

### Python/shebang
- `#394` — Python tools fail on Apple-stock + brew-only python@3.13 host (no unversioned python3 link)
- `#178` — dispatch-monitor Python rewrite fails catastrophically when invoked via bash

### Session-lifecycle
- `#393` — session-end skill writes handoff but never commits it — leaves tree dirty, blocks next session-resume
- `#291` — handoff archiver produces duplicate snapshots on session-compact
- `#201` — session-preflight Check 5 (dispatch monitor) always warns, never verifies
- `#200` — SessionStart emits 'needs merge' for nonexistent dispatch path
- `#199` — session-preflight fails on framework-managed dirty state (handoff, logs, archived handoffs)
- `#198` — /session-resume Step 4 uses raw git commands blocked by hookify

### Skills-meta
- `#347` — v2 migration trap: paths scope filter silently breaks skill discoverability when body claims multi-context support
- `#315` — V1 → V2 skill migration — fleet-scale coordinated refactor (all ~59 V1 framework skills)
- `#314` — Review, rework, and integrate monofolk's v2 skill methodology (3 REFERENCE docs + 5 case-study skills + 8 upstream PRs)
- `#298` — Skills review + refactor: align all skills with Claude Code's current skill-bundle structure and richer frontmatter fields (case study + recommendation)
- `#252` — Skill-vs-tool enforcement gap — agents bypass skills by shelling direct
- `#207` — skill-verify reports 59 false positives for intentionally removed allowed-tools
- `#197` — skill-verify fails all skills for missing allowed-tools — but that field was deliberately removed (Flag #62/#63)
- `#167` — sync-all skill doc says main-updated but tool accepts master-updated
- `#161` — Skills reference raw git commands blocked by hookify block-raw-tools

### Test-isolation
- `#385` — commit-precheck: scoped bats hangs on large PRs (43 files × 630s timeout)
- `#384` — test isolation: BATS tests must run in Docker (NOT on host) — real-tree pollution root-caused

## DEFER (114 issues)

Real issues but lower-priority or part of larger initiatives. Safe to defer until after stabilization push + Phase 4+ completion.

**Breakdown**: 13 HIP, 12 seed, 3 doc, 1 feature, 85 other

### HIP (Hardening + Improvement) Proposals
- `#228` — HIP: session-preflight adds gh issue list + Dependabot check
- `#227` — HIP: Receipt chain-verify — five-hash recomputation
- `#226` — HIP: Security skill — validate or remove
- `#225` — HIP: Provenance header audit across claude/tools/
- `#224` — HIP: designex Phase 1.5 housekeeping (31 findings)
- `#223` — HIP: Audit bash tools for Python 3.13 rewrite candidates
- `#222` — HIP: git-safe-commit receipt glob — recognize new five-hash receipts (LEAD)
- `#221` — HIP: hookify dispatch integration harness
- `#220` — HIP: skill-validation.bats #10 allowlist — inline-code spans + list contexts
- `#219` — HIP: git-captain sibling coverage (merge-to-master, switch-branch, fetch, push, tag, branch-delete)
- `#218` — HIP: designsystem-build BATS tests
- `#217` — HIP: designsystem-add BATS tests
- `#216` — HIP: figma-extract BATS tests

### Seed Captures
- `#343` — Skills defaulting project=captain on master must use repo-basename resolver (partial #334 follow-up)
- `#337` — Build a true installer — bare-repo → fully-installed + bootstrap paradox (SEED)
- `#334` — Repo-level workstream created as `claude/workstreams/captain/` + `claude/workstreams/$PROJECT_NAME/` — should be `claude/workstreams/$REPO_NAME/`
- `#330` — Improved session management — compact-prepare + compact-resume + v2 upgrade of session-end/session-resume + shared primitive investigation (seed)
- `#278` — Repo-level workstream miscreated as `claude/workstreams/captain/` instead of `claude/workstreams/{repo-name}/`
- `#270` — The Great Rename — claude/ → agency/ + install-vs-repo boundary
- `#269` — /feedback-submit skill — frictionless feedback capture (sibling to /seed)
- `#265` — Pass 2 research: articles seed — cross-repo framework evolution
- `#263` — Pass 2 discuss: Adopter permission scoping — Bash(*) + Read/Edit/Write(**) too broad
- `#259` — Pass 2 discuss: agency-gtm vouch model + X/Twitter monitoring + open source launch
- `#235` — CLAUDE-THEAGENCY.md + README-THEAGENCY.md: incorporate Telemetry-Driven Tool Discovery
- `#170` — Add /seed command and skill for frictionless Valueflow seed capture

### Documentation / Clarification
- `#354` — Document tool-tier carve-out for direct git calls vs git-safe
- `#336` — Hooks + hookify location clarification: `claude/hooks/` + `claude/hookify/` are the correct locations (no fix needed — document)
- `#286` — Documentation trap: `agency init` `--help` examples use real-looking usernames ("alex") — copy-paste produces rogue principals

### Feature Requests & Enhancements
- `#388` — git-safe add rejects directory-level paths — DX pain for bulk sweeps
- `#383` — status-line: presence-detect does not display the-agency version (monofolk does)
- `#359` — CI: rework tests to shell out to framework self-verify instead of hardcoded file lists
- `#357` — Enforce noun-verb naming convention for skills/tools/commands (+ rename update-config → config-update)
- `#353` — Extract session-primitive shared lib (lock, emit, identity) to claude/tools/lib/_session-primitive
- `#349` — Implement t-shirt sizing and complexity sizing skill
- `#348` — Skills should be composable — or framework should document that they aren't
- `#345` — test-monitor: mid-run critical-failure abort (v2 follow-on from PVR #180 Q5)
- `#342` — D45-R3 / PR #294 QGR deferred findings (6 items)
- `#340` — dispatch-monitor should filter commit-type dispatches by default (or make them opt-in)
- `#338` — Framework skill override path — adopter customization without forking
- `#335` — `docs/plans/` scaffolded by `agency init` — deprecated per D42-R3 Workstream Content Split
- `#333` — `claude/workstreams/housekeeping/` created by killed `/agency-bug` command — stale directory ships/persists
- `#332` — `usr/{$USER}/` created when principal ≠ $USER — Jordan's dir shows up in Andrew's repo
- `#329` — Framework version stale from install day — no drift nudge
- `#328` — Plan mode writes stray `~/.claude/plans/<name>.md` outside the repo
- `#327` — QG at `--no-work-item` commit path silently skips QGR receipt + Reference doc
- `#326` — `agency.yaml` principal mapping keyed on `$USER` with `.name` display — root cause of #273/#274
- `#325` — `agency init` does not rewrite `CLAUDE.md` — adopter left with placeholder stub
- `#324` — `.claude/agents/` missing after `agency init` — subagent classes not registered
- `#307` — SessionStart dependency-install mechanism — framework-level deps manifest + installer (uv, skills-cli, jq, gh)
- `#306` — Have Claude Code file feedback + GitHub issue for @path import support in SKILL.md (action: the-agency/captain + Principal Jordan)
- `#290` — `.claude/commands/` cleanup — dupes, stale refs, migrate remaining to skills
- `#289` — Skills review + dramatic improvement — audit all 59 SKILL.md files against Anthropic's skills spec
- `#288` — `claude/agents/` install-surface rule: class-only, agent.md-only
- `#285` — `git-safe add <directory>` blocks directory staging — forces per-file list
- `#284` — `git-safe add -u` treats `-u` as a filename — 'Staged: -u' instead of staging updated files
- `#283` — `git-safe-commit --force` flag not recognized — docs say `--force`, tool says `--no-work-item`
- `#282` — `agency init --project <name>` auto-creates a workstream — premature or intentional?
- `#280` — `handoff read` silently returns 'No handoff found' without scaffolding hint on first invocation

*... and 56 more feature requests and follow-up items*

## Observations & Patterns

### Finding 1: High noise ratio validates refactor-sprint hypothesis
- 114 of 167 issues (68%) are deferred: 13 HIP proposals, 5 seeds, 90+ feature requests
- 44 issues (26%) are actionable FIX-NOW bugs/friction (independent of Phase 4+)
- 8 issues (5%) are subsumed by Phase 4+ gates
- 1 issue (0.6%) already fixed

This suggests the refactor sprint surfaced real work but mostly deferred improvements, not blocking regressions.

### Finding 2: FIX-NOW work clusters around session lifecycle & adopter bootstrap
- **session-lifecycle (6)**: handoff commit, dispatch loop, preflight guards
- **skills-meta (9)**: V1→V2 migration debt + discoverability trap (large: 59 skills)
- **git-safe family (7)**: argument handling, DX gaps, bash 3.2 compat
- **adopter-experience (3)**: update chicken-egg, init gaps, statusline
- **test-isolation (2)**: BATS timeout formula, Docker enforcement
- **dispatch (3)**: cross-worktree corruption, infinite loops
- **python/shebang (2)**: macOS runtime discovery, bash rewrite failures
- **ci-cd (2)**: release automation gap, monitor noise
- **hookify (1)**: 6/42 canaries unsynthesizable
- **misc (9)**: PR tooling friction, worktree merge issues, telemetry, etc.

### Finding 3: No duplicates despite rapid-fire filing
Despite 166 issues in 5 days, no obvious duplicates detected. Suggests either:
- Good discipline (each issue captures unique concern)
- Low topic overlap (each is orthogonal)
- Or: high thematic overlap but not at issue-identity level (dupes obscured by different titles)

Recommend light duplicate audit before stabilization push, especially on skills-meta and session-lifecycle themes.

### Finding 4: HIP proposals are actionable, not aspirational
All 13 HIP items are well-formed improvement proposals with context, precedent, and scope. Safe to defer but high-quality roadmap material.

## Recommendations for the Captain

### 1. Use this triage to scope stabilization work
- **44 FIX-NOW issues**: These are your stabilization push scope. Independent of Phase 4+.
- **114 DEFER issues**: Safe to explicitly defer. Can re-triage after Phase 4+ completion.
- **8 SUBSUMED issues**: Part of Phase 4+ gates — no separate action needed.

### 2. Prioritize FIX-NOW by impact
**Highest impact** (blocks workflows):
- Session-lifecycle bugs (#393, #291, #199, #200, #198): blocking agent session pipelines
- Test isolation (#384): blocking CI/local PR workflow
- Adopter-experience (#392, #287, #272): pre-Phase4 bootstrap blockers

**Medium impact** (DX regression):
- git-safe argument handling (#388, #389, #339, #212): refactor regressions
- Skills verification (#347, #207, #197): V1→V2 migration traps

**Lower impact** (isolation, tooling):
- Dispatch corruption (#297, #210, #181): manifest in multi-worktree use
- Release automation (#372, #363): release cadence, not blocking dev

### 3. Flag #315 (V1→V2 skill migration) as separate major initiative
59 V1 skills need rewrite. This dwarfs other deferred work. Treat as a distinct project, not part of stabilization push.

### 4. Re-triage after Phase 4+ lands
Many DEFER items may naturally resolve or clarify in the context of the refactored src/ tree. Plan a post-Phase4+ triage sweep.

---

*Triage completed 2026-04-21 by automated review of 167 GitHub issues.*
