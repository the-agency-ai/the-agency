# TheAgency — Bootloader

<!-- What Problem: The monolithic CLAUDE-THEAGENCY.md (~6600 words) was loaded into
every agent's context on every session, costing ~8K tokens even when agents needed
<20% of it. Most rules were already enforced by hookify (40 rules) and discoverable
via skills (57 skills).

How & Why: Refactored to a ~250-word bootloader that orients agents and points to
skills, hookify rules, and ref-injector-provided reference docs. The ref-injector
hook injects the right doc when the right skill runs — agents get full protocol
detail exactly when they need it, not at startup. All extracted content lives in
claude/ as standalone REFERENCE-*.md documents.

Written: 2026-04-12 during devex Day 35 — bootloader refactoring (seed approved
by captain, dispatch #201). -->

This is **TheAgency framework development repo** — open core (MIT framework, Reference Source License for app workstreams). All agents and principals follow the methodology below.

## Where Things Live

- `claude/` — framework: tools, agents, docs, hooks, hookify rules, config, skills, templates
- `usr/` — principal sandboxes (at **project root**, NOT under `claude/`)
- `.claude/skills/` — skill definitions (discover via `/` autocomplete)
- `claude/hookify/` — behavioral enforcement rules (40 rules — blocks, warns, informs)
- `claude/REFERENCE-*.md` — reference docs (injected on demand by `ref-injector.sh` when skills run)

## How You Work

1. **Skills are the interface.** Use `/` autocomplete to discover capabilities. Skills invoke tools with correct parameters and trigger ref-injector to provide protocol docs when needed.
2. **Hookify enforces mechanically.** If you try something wrong (raw `git commit`, compound bash, force push, cd to main), a hookify rule blocks you with guidance on what to do instead.
3. **Ref-injector provides context on demand.** When you invoke a skill, the hook injects the relevant reference doc into your context — full protocol detail exactly when you need it.
4. **Handoff tool for session context.** Use `/handoff` or `./claude/tools/handoff write` — never write handoff files manually.
5. **ISCP for communication.** Dispatches and flags via `/dispatch` and `/flag` skills. Start `/monitor-dispatches` at session start for real-time notification.

## Key Skills

| Skill | Purpose |
|-------|---------|
| `/git-safe-commit` | QG-aware commit wrapper (never raw `git commit`) |
| `/quality-gate` | Parallel multi-agent review at commit boundaries |
| `/iteration-complete` | Commit at iteration end (auto-approve) |
| `/phase-complete` | Commit at phase end (principal approval required) |
| `/release` | Quality-check, commit, push, create PR, and cut a release in one flow |
| `/handoff` | Session context — archive, write, verify |
| `/session-resume` | Full startup — sync, handoff, dispatches (runs session-preflight at end) |
| `/session-compact` | Mid-session context refresh — commit, write handoff, then compact |
| `/session-end` | Clean teardown — handoff, dirty-state warning |
| `/dispatch` | ISCP dispatch lifecycle |
| `/discuss` | 1B1 protocol for multi-item discussions |
| `/define` | Drive toward complete PVR |
| `/design` | Drive toward complete A&D |
| `/worktree-sync` | Sync worktree with master |
| `/monitor-dispatches` | Event-driven dispatch watching (Monitor tool) |

## Safe Tools

All commands in the table below are blocked by hookify (decision:block + exit 2 — enforced since Day 40). Use the safe alternatives.

| Blocked command | Safe alternative | Why |
|----------------|-----------------|-----|
| `git *` (all subcommands) | `git-safe` (read + merge ops), `git-captain` (captain-only: push, fetch, tag, merge-to-master, switch-branch), `/git-safe-commit` (commits) | Role-scoped git access |
| `git push` | `./claude/tools/git-push` (via `/sync`, `/release`) | All pushes go through PRs |
| `cp` | `./claude/tools/cp-safe` | Blocks cross-worktree copies |
| `gh pr create` | `./claude/tools/pr-create` (via `/release`) | Requires QGR + version bump |

## Valueflow Stream Model

Work moves through three streams. Each stream has its own gates.

| Stream | What flows | Gates |
|--------|-----------|-------|
| **Work stream** | Agent commits | `/iteration-complete`, `/phase-complete` |
| **Delivery stream** | PRs and releases | `/release`, `pr-create` |
| **Value stream** | Builds and deployments | `/deploy` |

Transitions: commits → QG/RG gate → PRs → PR gate → builds.

## Reference Docs

Injected automatically when relevant skills run. Read directly when you need them outside a skill context.

| Topic | Document |
|-------|----------|
| Repo structure & directory tree | `claude/REFERENCE-REPO-STRUCTURE.md` |
| Agent & principal addressing | `claude/REFERENCE-AGENT-ADDRESSING.md` |
| Quality gate protocol | `claude/REFERENCE-QUALITY-GATE.md` |
| Development methodology (Valueflow, MAR, three-bucket) | `claude/REFERENCE-DEVELOPMENT-METHODOLOGY.md` |
| Worktrees, master, and agent roles | `claude/REFERENCE-WORKTREE-DISCIPLINE.md` |
| Session handoff spec | `claude/REFERENCE-HANDOFF-SPEC.md` |
| ISCP protocol (dispatches & flags) | `claude/REFERENCE-ISCP-PROTOCOL.md` |
| Code review & PR lifecycle | `claude/REFERENCE-CODE-REVIEW-LIFECYCLE.md` |
| Git discipline (merge, never rebase) | `claude/REFERENCE-GIT-MERGE-NOT-REBASE.md` |
| Feedback & bug report format | `claude/REFERENCE-FEEDBACK-FORMAT.md` |
| Provenance headers & script discipline | `claude/REFERENCE-PROVENANCE-HEADERS.md` |
| Testing & quality discipline | `claude/REFERENCE-QUALITY-DISCIPLINE.md` |
| Enforcement model (Triangle, Ladder, all rules) | `claude/README-ENFORCEMENT.md` |
| Contribution model (three rings of trust) | `claude/REFERENCE-CONTRIBUTION-MODEL.md` |
| Concepts & onboarding | `claude/REFERENCE-CONCEPTS.md` |
| Safe tools family (git-safe, git-captain, cp-safe, pr-create) | `claude/REFERENCE-SAFE-TOOLS.md` |
| Receipt infrastructure (five-hash chain, receipt-sign, receipt-verify) | `claude/REFERENCE-RECEIPT-INFRASTRUCTURE.md` |

## Core Principles

- **Fix what you find.** No workarounds, no "fix later," no severity-based skip.
- **Merge, never rebase.** All branch sync uses merge. Hookify blocks rebase.
- **Never push without permission.** `/sync` and `/release` are the only push commands.
- **Plan before you build.** Use plan mode for non-trivial tasks.
- **Commit via skills.** `/iteration-complete`, `/phase-complete`, `/git-safe-commit` — never raw `git commit`.

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
