# Monofolk Skills Manifest

Skills ported from monofolk for incorporation into the-agency framework. Each skill is categorized as **framework** (generic, install as-is), **reference** (project-specific pattern worth generalizing), or **monofolk-only** (stays in monofolk).

## Framework — Install as-is or with minimal changes

These are Agency methodology skills. They belong in the-agency and get installed by `agency-init`.

| Skill | Purpose | Notes |
|-------|---------|-------|
| `quality-gate.md` | 8-stage QG protocol | Updated: Step 10 writes QGR receipt file |
| `iteration-complete.md` | Iteration boundary | Updated: passes boundary context |
| `phase-complete.md` | Phase boundary | Updated: passes boundary context |
| `plan-complete.md` | Plan boundary | Updated: passes boundary context |
| `pr-prep.md` | Pre-PR QG | **NEW** |
| `pre-phase-review.md` | Pre-phase artifact review | Unchanged |
| `git-commit.md` | QG-aware commit | **REWRITTEN** — stage hash receipt check |
| `discuss.md` | 1B1 discussion protocol | Updated: added `Skill` to allowed-tools |
| `transcript.md` | Dialogue capture | Unchanged |
| `define.md` | Drive PVR to completeness | Unchanged |
| `design.md` | Drive A&D to completeness | Unchanged |
| `captain-review.md` | Captain code review dispatch | Unchanged |
| `code-review.md` | 7-agent code review | Unchanged |
| `review-pr.md` | Ad-hoc PR review | Unchanged |
| `pr-respond.md` | PR review comment responder | Unchanged |
| `diff-summary.md` | Classify diffs as formatting vs substantive | Unchanged |
| `post-merge.md` | Post-merge sync | Unchanged |
| `rebase.md` | Local rebase | Unchanged |
| `sync-all.md` | Local sync (never pushes) | Unchanged |
| `sync.md` | Push to origin (explicit) | Unchanged |
| `ship.md` | QG + commit + push + PR flow | Unchanged |
| `sandbox-activate.md` | Symlink sandbox item | Unchanged |
| `sandbox-adopt.md` | Graduate to shared | Unchanged |
| `sandbox-create.md` | Create sandbox experiment | Unchanged |
| `sandbox-deactivate.md` | Remove sandbox symlink | Unchanged |
| `sandbox-init.md` | Set up engineer sandbox | Unchanged |
| `sandbox-list.md` | List sandbox items | Unchanged |
| `sandbox-status.md` | Show sandbox health | Unchanged |
| `sandbox-try.md` | Try another engineer's experiment | Unchanged |
| `secret.md` | Secret management | Unchanged |
| `session-list.md` | List past sessions | Unchanged |
| `session-read.md` | Read past session transcript | Unchanged |
| `worktree-create.md` | Create git worktree + dev env | Unchanged |
| `worktree-delete.md` | Remove worktree | Unchanged |
| `worktree-list.md` | List worktrees | Unchanged |

## Reference — Make pluggable and configurable

These are monofolk-specific implementations of patterns that should become framework-level. The skill structure (subcommands, arguments, flow) is the standard; the infrastructure details need to be configurable per project. **This is the path to replacing starter packs** — instead of starter packs that install project-specific tooling, the framework provides configurable skills.

| Skill | Pattern | What to make configurable |
|-------|---------|--------------------------|
| `preview.md` | Preview environments: local/dev/pr/down/list/status/logs | Infrastructure backend (Docker Compose, Fly.io, Vercel), port allocation, service definitions |
| `deploy.md` | Deploy to staging/production: status/rollback/logs/history | Platform (Fly.io, AWS, Vercel, etc.), environments, approval gates |
| `crawl-sites.md` | Batch web crawling | Target URLs, extraction rules, output format |

## Monofolk-only — Stay in monofolk

These are monofolk prototype system skills. They use monofolk-specific infrastructure (NestJS scaffold, Prisma, Docker dev stack, prototype registry).

| Skill | Purpose |
|-------|---------|
| `prototype.md` | Router for prototype subcommands |
| `prototype-archive.md` | Archive a prototype |
| `prototype-create.md` | Scaffold new prototype |
| `prototype-down.md` | Stop prototype Docker stack |
| `prototype-health.md` | Health check prototype |
| `prototype-help.md` | Show prototype commands |
| `prototype-list.md` | List prototypes |
| `prototype-logs.md` | Tail prototype logs |
| `prototype-merge.md` | Merge prototypes |
| `prototype-preview.md` | Push prototype for preview |
| `prototype-promote.md` | Promote prototype to production |
| `prototype-reset.md` | Reset prototype |
| `prototype-up.md` | Start prototype Docker stack |

## Agent Definitions

| File | Notes |
|------|-------|
| `project-manager-agent.md` | Updated: added "do not touch git directly" clause |

## Tests

| File | Notes |
|------|-------|
| `stage-hash.test.ts` | 9 tests for stage-hash utility (TypeScript/vitest) |

## Key Changes Summary

1. **QGR receipt files** — new convention: `claude/usr/{principal}/{project}/qgr-{boundary}-{phase-iter}-{stage-hash}-YYYYMMDD-HHMM.md`
2. **Stage hash** — deterministic 7-char hash of staged changes, used for QGR naming and `/git-commit` verification
3. **`/git-commit` is QG-aware** — checks for matching QGR receipt before committing, `--force` to skip
4. **`/pr-prep` is new** — QG before PR creation, produces receipt
5. **Boundary commands pass context** — `/iteration-complete`, `/phase-complete`, `/plan-complete` tell `/quality-gate` the boundary type for receipt naming
6. **`/discuss` invokes `/transcript`** — `Skill` added to allowed-tools
7. **PM agent doesn't touch git** — explicit clause added
