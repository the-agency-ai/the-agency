# The Agency 2.0 — Product Vision & Requirements

**Workstream:** housekeeping (captain)
**Date:** 2026-04-05
**Status:** Draft — driving toward completeness via /define
**Agent:** the-agency/jordan/captain
**Source:** Release scoping 1B1 (29 items) + Monofolk port 1B1 (15 items), 2026-04-04/05

---

## 1. Problem Statement

### What problem does this solve?

The Agency framework works for its creators but fails for anyone else. Three categories of failure:

1. **Broken front door.** `agency-init` has 5 known bugs (flat principals format, branchless repos, missing permissions, missing tools, brace expansion prompts). No one can adopt the framework if init doesn't work. `agency-update` doesn't exist — adopters fork and drift.

2. **Agent coordination at scale.** Single-agent sessions work. Multi-agent coordination (captain + worktree agents) breaks: no notification layer, git-coupled messaging fails in worktrees, no reliable dispatch lifecycle. ISCP workstream is addressing this separately.

3. **Missing Enforcement Triangle coverage.** Key operations lack the full tool + skill + hookify rule pattern: git push, test execution, provenance headers, secret management, prototype lifecycle. Without mechanical enforcement, compliance is just prose.

### For whom?

- **Framework adopters** — developers running `agency-init` on their own repos
- **Agency principals** — humans directing multi-agent workflows
- **Agency agents** — AI instances that need reliable tooling, permissions, and coordination

### Why now?

Agency 2.0 is the public release. mdpal and mock-and-mark are the launch apps. The framework must work on repos that aren't the-agency itself. Every broken tool or missing permission is a first-impression failure.

---

## 2. Vision

The Agency ships as a self-bootstrapping framework: `agency-init` creates a working agent environment, `agency-update` keeps it current, and the Enforcement Triangle ensures every capability has mechanical backing. Agents work in isolated worktrees, coordinate through typed dispatches (ISCP), and produce auditable quality gates at every boundary. The framework supports pluggable providers (secrets, prototypes, deploy/preview) so projects bring their own infrastructure.

---

## 3. Users & Stakeholders

| User | Needs | Priority |
|------|-------|----------|
| New adopter | Working `agency-init`, clear onboarding, zero broken tools | P0 |
| Existing adopter (monofolk) | `agency-update` that doesn't destroy project config | P0 |
| Principal (Jordan) | Multi-agent coordination, dispatch lifecycle, reliable handoffs | P0 |
| Worktree agent | Pre-approved permissions, dispatch notifications, merge signals | P1 |
| Captain agent | PR lifecycle skill, dispatch routing, worktree sync | P1 |
| Community contributor | Vouch model, AI-POLICY.md, contribution docs | P2 |
| Content consumer | Articles, workshops, book (separate repo) | P3 |

---

## 4. Requirements

### P0 — Must Ship (Bootstrap & Permissions)

| ID | Requirement | Source |
|----|-------------|--------|
| R1 | `agency-init` fixes: flat principals, branchless repos, missing usr/** permissions, missing flag+handoff tools, brace expansion | Item 1 |
| R2 | `agency-update`: tier assignment (framework/project), never overwrite project config, add/update/remove lifecycle | Item 2 |
| R3 | `agent-create` fixes: bootstrap handoff, tech-lead template, placeholder text, settings registration, clean file output | Item 3 |
| R4 | Pre-approved permissions: mine transcripts/logs for prompt triggers, pre-approve non-destructive ops in settings-template.json | Item 4 |
| R5 | `/pr` skill (captain-only): build PR branch → QG → create PR → push → auto-merge. Full Enforcement Triangle. Block raw push and raw `gh pr create` from non-captain agents | Item 6 |
| R6 | Docker container test execution: tool + skill + hookify rule. Structured output. Same behavior locally and in CI | Item 7 |

### P1 — Should Ship (Tooling & DevEx)

| ID | Requirement | Source |
|----|-------------|--------|
| R7 | SessionStart hook: mechanical startup, validate principal, usr/, tools, agency.yaml | Item 5 |
| R8 | Handoff multi-agent: `{agent}-handoff.md` per agent, workstream-create scaffolds | Item 8 |
| R9 | Transcript mining tool: formalize to `agency/tools/`, feed permissions discovery and friction detection | Item 9 |
| R10 | Dispatch auto-read: abstraction layer now (file-rename), ISCP replaces implementation later | Item 10 |
| R11 | Hookify rules terse: one-liner + doc ref + kittens as standard pattern, audit remaining | Item 11 |
| R12 | Handoff typed frontmatter: session-restore, agency-bootstrap, agent-bootstrap types | Item 12 |
| R13 | Transcript dual-write: worktree + master simultaneously, tooling handles it | Item 13 |
| R14 | Kill agency-service: delete all code and references | Item 14 |
| R15 | Kill /agency dispatcher: document patterns/anti-patterns, then delete | Item 15 |
| R16 | Provenance header enforcement: hookify rule on Write, check for What Problem + How & Why, block if missing | Item 20 |
| R17 | MAR formalization: define in CLAUDE-THEAGENCY.md, concept + review loop + composition per QG + red-green discipline | Item 21 |

### P2 — Pluggable Providers & Patterns

| ID | Requirement | Source |
|----|-------------|--------|
| R18 | PROVIDER-SPEC.md: formalize provider contract (functions, signatures, exit codes, output format, env, error handling, registration) | Item 22 |
| R19 | DevEx workstream + agent in the-agency, bootstrap from monofolk DevEx context | Item 22 |
| R20 | Prototype pattern: generalized lifecycle (create/up/down/health/preview/promote/merge/archive), worktree isolation, PROVIDER-SPEC consumer | Port items 1-13 |
| R21 | Secret management: `/secret` skill, age vault as default provider, PROVIDER-SPEC consumer. Vault at ~/.agency/vault/ | Port item 14 |
| R22 | PM agent update: diff against monofolk version, merge improvements | Port item 15 |

### P3 — Community & Content

| ID | Requirement | Source |
|----|-------------|--------|
| R23 | the-agency-starter sunset: mine content, notify stargazers/fork/follower, redirect README, pin issue, archive | Item 16 |
| R24 | Vouch model: CONTRIBUTING.md + AI-POLICY.md (4Ds), Ghostty template | Item 17 |
| R25 | the-agency-content repo: private, agency model, content workstreams | Item 18 |
| R26 | X/Twitter custom MCP: post, read, search. Pay-per-use tier. Jordan TODO: developer account | Item 19 |
| R27 | Ghostty + VS Code + Zed + CLI as supported surfaces. Community adds others | Item 29 |

### ISCP Owns (separate PVR)

| ID | Requirement | Source |
|----|-------------|--------|
| I1 | Dropbox (outside repo) | Item 23 |
| I2 | Flag agent-addressable + SQLite (outside repo) | Item 24 |
| I3 | Dispatch lifecycle with 9 typed dispatch types | Item 25 + session 19 |
| I4 | Cross-repo delivery (priority: intra → inter → cross same → cross different) | Item 26 |

---

## 5. Non-Requirements (Explicit Exclusions)

| Exclusion | Reason |
|-----------|--------|
| Cursor support | Uses Claude model but not Claude Code — no integration surface |
| iTerm/other terminals | Ghostty-only, community contributes others |
| Prototype-specific infra (Docker, Prisma, NestJS) | Delegated to providers — framework is infra-agnostic |
| Human review in PR flow | QG already ran at every boundary — PR is delivery mechanism, not review gate |
| ISCP implementation details | Separate workstream with its own PVR |

---

## 6. Success Criteria

| Criterion | Measurement |
|-----------|-------------|
| `agency-init` works on bare repo | Smoke test: fresh git repo, run init, launch agent, complete a task |
| `agency-init` works on existing repo | Smoke test: Ghostty fork, run init, no conflicts |
| `agency-update` preserves project config | Existing monofolk config survives update |
| Zero permission prompts for standard agent operations | Mine session transcripts, count prompts, target: 0 |
| Enforcement Triangle complete for push, test, provenance | All three layers exist and are wired |
| PROVIDER-SPEC has ≥2 consumers with default providers | Prototype (Docker) + Secret (age) |

---

## 7. Key Decisions (from 1B1s)

| Decision | Rationale |
|----------|-----------|
| `/pr` not `/push` | Push is an implementation step inside the PR skill, not a standalone action |
| Docker for test isolation | Same behavior locally and CI. Enforcement Triangle for test execution |
| age over GPG for local secrets | Simple (one command encrypt/decrypt), no key servers, no config |
| Seeds at workstream level | `agency/workstreams/{name}/seeds/` — belong to workstream, not agent |
| `git init → agency init → claude` | Already settled, not reopened |
| Content in separate private repo | the-agency-ai/the-agency-content, agency model |
| Dispatch types: 9 typed + flag as separate primitive | directive, seed, review, review-response, commit, master-updated, escalation, dispatch (generic). Flag stays separate — zero-ceremony capture |

---

## 8. Open Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | What's the minimum viable PROVIDER-SPEC? Do we need the full contract before shipping prototype/secret, or can we iterate? | R18, R20, R21 |
| 2 | How does the `/pr` skill interact with branch protection rules on repos that have them? | R5 |
| 3 | What's the Docker container strategy for repos that don't use Docker? Is Docker a hard requirement for test isolation? | R6 |
| 4 | Provenance header enforcement — how strict on first launch? Block (hard fail) or warn (soft fail with ramp-up)? | R16 |
| 5 | X API pricing: $200/mo Basic tier vs $100/mo Pro tier. Which capabilities do we actually need? | R26 |
| 6 | Priority ordering within P0 — is R1→R2→R3 the right sequence, or should permissions (R4) come first to unblock everything? | All P0 |
| 7 | Prototype lifecycle — does the framework ship with a default provider (Docker compose), or is it provider-required from day one? | R20 |
| 8 | How do we validate agency-update against the-agency-starter migrants if we don't have any active users yet? | R2, R23 |

---

## 9. Dependencies

```
R1 (agency-init) ──→ R2 (agency-update) ──→ R23 (starter sunset)
R1 ──→ R3 (agent-create) ──→ R8 (handoff multi-agent)
R4 (permissions) ──→ R7 (SessionStart hook)
R18 (PROVIDER-SPEC) ──→ R20 (prototype) + R21 (secret)
R14 (kill agency-service) ──→ I3 (ISCP dispatch lifecycle)
R15 (kill /agency dispatcher) ──→ R14
```

---

*Source: Release scoping 1B1 (29 items, 2026-04-04) + Monofolk port 1B1 (15 items, 2026-04-05). All 44 items resolved by principal.*
