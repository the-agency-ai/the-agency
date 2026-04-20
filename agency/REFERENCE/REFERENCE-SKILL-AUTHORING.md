# Skill Authoring — the-agency v2 methodology

How we build skills in the-agency framework. Covers the v2 spec (`agency-skill-version: 2`), bundle structure, frontmatter, naming, dependencies, and the full workflow for creating a new skill or upgrading an existing v1 skill.

**Status:** v2 methodology spec. Active adoption. First case studies landed 2026-04-19 (pr-submit, pr-captain-land, iteration-complete, phase-complete). Upstreamed to the-agency via relevant PRs.

## Required reading (before authoring any skill)

- `claude/REFERENCE-WHAT-IS-CLAUDE-CODE.md` — grounding on Claude Code's primitives (agent, tools, CLAUDE.md, skills, hooks). If you don't know the difference between a skill and a slash command, read this first.
- [Anthropic — The Complete Guide to Building Skills for Claude (PDF)](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
- [Claude Code — Skills documentation](https://code.claude.com/docs/en/skills)
- [skills-cli on PyPI](https://pypi.org/project/skills-cli/) (first-party CLI we adopt)
- [skill-creator skill at github.com/anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/skill-creator) (first-party interactive design skill)

## Why this spec exists

Before v2, the-agency's skills had:

- Minimal frontmatter (often just `description`)
- No consistent bundle structure — most skills were bare `SKILL.md` files, no `scripts/` / `references/` / `examples/`
- No declared dependency graph between skills and framework reference docs
- No registry
- No discipline on `allowed-tools` (flag #62/#63 — subcommand-level patterns silently blocked fleet agents)
- No naming discipline (some `noun-verb`, some verb-first, some with actor prefixes, some without)

Result: skills were fragmented, hard to review, and hard for adopters to understand at a glance.

v2 makes skills **cohesive, self-describing, declaratively-specified units**. Every v2 skill is a full bundle with complete frontmatter, explicit dependencies, and a registry entry. Reading one v2 skill tells you everything the skill does, depends on, and costs.

## Version scheme

```yaml
agency-skill-version: 2
```

- **`1`** (legacy) — the-agency skills prior to 2026-04-19. Minimal structure. Still functional; tagged v1 in the registry so we know which skills haven't been upgraded.
- **`2`** (current) — this spec. Full bundle + full frontmatter + registered.
- Future versions bump the integer when the spec changes in breaking ways. Minor revisions to the spec (e.g., adding an optional field) do NOT bump; they extend v2.

The field is declared in SKILL.md frontmatter. Every v2 skill MUST have it.

## What v2 requires (the spec)

### 1. Full bundle structure — always

```
my-skill/
├── SKILL.md           # overview, frontmatter, instructions — ALWAYS present
├── reference.md       # skill-unique protocol/spec — ALWAYS present (may be short)
├── examples.md        # happy-path + edge + integration examples — ALWAYS present
├── scripts/           # executable code — ALWAYS present (may be empty)
└── assets/            # templates, static files — ALWAYS present (may be empty)
```

All five MUST be present. If any is empty, include a short note explaining why. Example for a no-op `scripts/`:

```
# scripts/README.md
# This skill is pure orchestration — invokes /quality-gate via the Skill tool.
# No custom scripts needed. Directory preserved for bundle-structure consistency.
```

**Rationale:** predictable layout for readers; empty sections force the author to explicitly think "have I really checked I don't need this?"; diff-audit friendly over time.

### 2. Frontmatter — all fields required

```yaml
---
name: skill-name
description: What it does + front-loaded key use case. First 1,536 chars used by Claude's matcher.
agency-skill-version: 2
when_to_use: Explicit trigger phrases + anti-trigger phrases. "NEVER from X" statements as needed.
argument-hint: "<arg1> <arg2> [--flag value]"
paths:                               # Auto-scoping. Empty list for captain-on-master-only skills.
  - .claude/worktrees/**
disable-model-invocation: false      # true for destructive captain-only skills
allowed-tools: ...                   # See §3 below. Called out explicitly.
required_reading:                    # Framework reference docs this skill needs.
  - claude/REFERENCE-QUALITY-GATE.md
  - claude/REFERENCE-WORKTREE-DISCIPLINE.md
---
```

No optional frontmatter fields in v2. Every field MUST be present. If a field doesn't apply, include it with an explicit null/empty + comment explaining why.

### 3. `allowed-tools` — tool-level only, never subcommand-level

**Critical discipline.** From flag #62/#63 and devex dispatch #171:

- **Subcommand-level restriction silently blocks fleet agents.** Example of what NOT to do: `allowed-tools: Bash(git status *)`. The permission prompt fires for something Claude's matcher cannot see or surface; the agent hangs with no visible error. This burned fleet agents.
- **Tool-level restriction is safe.** Example: `allowed-tools: Bash(agency/tools/git-safe:*), Bash(agency/tools/dispatch:*)`.
- **When in doubt, inherit `Bash(*)` from `.claude/settings.json`** by omitting `allowed-tools` from the skill frontmatter. Include an inline comment explaining why — like iteration-complete + phase-complete do.

**Path convention:** agency tools live at `agency/tools/` (future: `agency/tools/` when the rename lands). `.claude/tools/` is NOT the right path — that would be Claude Code's own space.

### 4. `required_reading` pattern (Option C until @path lands)

Claude Code does NOT support `@path/to/file.md` imports in SKILL.md today (only in CLAUDE.md). See the-agency#306 for the feature request.

Interim workaround: `required_reading:` frontmatter field lists framework reference docs the skill depends on. SKILL.md body has an early "Required reading" step that tells the agent to Read those files before proceeding.

```yaml
required_reading:
  - claude/REFERENCE-QUALITY-GATE.md
  - claude/REFERENCE-RECEIPT-INFRASTRUCTURE.md
```

```markdown
## Required reading

Before proceeding, Read the files listed in `required_reading:` frontmatter. These contain protocol details this skill relies on.
```

When Claude Code adds `@path` support, migrating from `required_reading:` to inline `@path` directives is mechanical; skill content doesn't change.

### 5. Body structure — 9 standard sections

Every v2 SKILL.md body has these sections, in this order. Empty sections get explicit "N/A because …" content.

1. **Why this exists** — the pain addressed
2. **Required reading** — directs agent to Read the `required_reading:` frontmatter files **before** invocation syntax (agent learns dependencies before learning how to call)
3. **Usage** — invocation syntax
4. **Preconditions** — what must be true before running (or "None — …")
5. **Flow / Steps** — numbered step-by-step (or "Single step — …")
6. **Failure modes** — per-step what can go wrong + recovery (or "No destructive operations; failures are benign")
7. **What this does NOT do** — explicit non-goals, companion skills (or "N/A")
8. **Status** — `active | pilot | deprecated | experimental | retired`
9. **Related** — companion skills, reference docs, upstream issues

All 9 headings are REQUIRED, in this order. "Required reading" is the v2-added section that directs the agent to Read the `required_reading:` frontmatter entries before acting. Putting it at position 2 (before Usage) ensures the agent loads dependencies into context before reading invocation syntax.

The `skill-audit` tool enforces both presence and order; out-of-order sections fail the audit as noncompliant.

**Retroactive note (MAR 2026-04-19):** earlier drafts of this spec had Usage at position 2 and Required reading at position 3. The case-study skills all adopted the opposite order independently for pedagogical reasons (deps before syntax), and `skill-audit`'s REQUIRED_SECTIONS array matches the case-study order. The spec now matches the audit + case-study reality.

### 6. Naming — noun-verb, with actor qualifier for scoped skills

**Three valid forms (in preference order):**

1. **`noun-verb`** — the default. Verbs include imperative actions (`-create`, `-land`, `-merge`) and state-transition verbs (`-complete` = "complete this X"; `-review`; `-prepare`).
2. **`noun-actor-verb`** — use when the skill is scoped to a specific actor AND has a clear noun. Example: `pr-captain-land` (pr = noun, captain = actor, land = verb).
3. **`actor-verb`** — use when the skill is scoped to a specific actor BUT has no clear noun (i.e., the verb itself stands for the full action). Examples: `captain-release`, `captain-review`, `captain-sync-all`, `captain-log`.

**Which form to use:**

- Default actor (agent / anyone) never needs an actor qualifier → use form 1 (`noun-verb`)
- Captain-scoped skill with a clear noun → use form 2 (`noun-captain-verb`, e.g. `pr-captain-land`)
- Captain-scoped skill where noun ≡ verb or is awkward to separate → use form 3 (`captain-verb`, e.g. `captain-release`)

Examples:
- `pr-submit` — form 1. Agent submits their branch. Default actor; no qualifier.
- `pr-captain-land` — form 2. Captain lands a PR. Noun = pr, actor = captain, verb = land.
- `pr-captain-merge` — form 2. Captain merges a PR. Same structure.
- `captain-release` — form 3. Captain does a release. "release" is both noun and verb; inserting a separate noun (like `pr-captain-release`) is awkward when the release is the PR-landing step, not a PR noun itself.
- `captain-sync-all` — form 3. Captain syncs the fleet. No single noun naturally precedes.
- `captain-log` — form 3. Captain logs an entry. "log" is the verb-on-the-noun.
- `iteration-complete` — form 1. Any agent completes an iteration. Default actor.

**When in doubt, prefer form 2 over form 3.** If a noun exists and isn't awkward, surface it. Form 3 is legitimate but only when inserting a noun would force an artificial hyphenation.

**Grouping effect:** `noun-` prefix groups related skills in autocomplete. `/pr<tab>` shows the full PR toolkit. `captain-` prefix also groups, but captain-only operations — see `captain-<tab>` for the captain's toolkit.

**Audit enforcement:** `skill-audit` does NOT enforce naming form — naming is an authoring guideline, not a correctness invariant. It DOES enforce that skills named with a `captain-` prefix or `-captain-` infix have the captain-only four-layer defense (`paths: []` + `disable-model-invocation: true`).

### 7. Registry row

Every v2 skill has a row in `claude/REFERENCE-SKILLS-INDEX.md`. Schema:

| Column | Contents |
|---|---|
| Name | skill name (matches directory + `name:` frontmatter) |
| Description | one-line summary (first sentence of `description:`) |
| Agency-Skill-Version | `1` or `2` |
| Scope | `agent` / `captain` / `both` |
| Status | `active` / `pilot` / `deprecated` / `experimental` / `retired` |
| Required Reading | comma-separated reference-doc basenames |

Row is maintained by the author (via the `skill-create` workflow — automated where possible). Drift between row and reality is caught by `skill-audit` (see §Tools).

## Bundle file roles

### `SKILL.md` — the contract

- Frontmatter as §2
- Body as §5 (9 sections)
- Front-loads what an agent needs to decide: what this does, when to use it, what it needs to run

### `reference.md` — skill-unique protocol

- **Holds content unique to this skill** — not duplicated from `claude/REFERENCE-*.md`
- Examples: `pr-submit/reference/dispatch-payload.md` spec (structure of the dispatch message), `pr-captain-land/reference/land-protocol.md` (9-step flow detail)
- If the skill has NO unique protocol (pure orchestration or trivial), `reference.md` exists but is short: "This skill has no unique protocol. See `required_reading:` for all behavior specifications."

### `examples.md` — how invocation looks

Three categories always present:

- **Happy-path examples** — typical invocations with expected output
- **Edge-case examples** — preconditions failing, what error looks like
- **Integration examples** — how this skill fits with others (composability)

Examples are both human-readable AND signal for Claude's matcher. Good examples reduce false-positive invocations.

### `scripts/` — executable code specific to this skill

- **Rule of thumb:** if called by more than one skill, the code lives in `agency/tools/`. If called by one skill only, it lives in that skill's `scripts/`.
- Scripts invoke shared tools directly (e.g., `agency/tools/git-safe`) — don't wrap them.
- If no skill-specific scripts are needed, directory is empty with a short `README.md` explaining why.

### `assets/` — templates, static files

- Where skill-specific templates, sample configs, or binary assets live
- If unused, empty dir with a `README.md` noting why

## Dependencies

### Required framework dependencies

- **`uv`** — Python package manager. Pre-installed or installed via `curl -LsSf https://astral.sh/uv/install.sh | sh`.
- **`skills-cli`** — Anthropic's first-party CLI. Installed via `uv tool install skills-cli`. Provides `skills validate`, `skills create`, `skills list`, etc.

**Install mechanism:** framework-level SessionStart hook checks for presence and installs missing deps. Tracked as the-agency#307. Until that lands, adopters install manually (one-time).

### Why adopt Anthropic's tooling?

- `skills-cli validate` already does structural validation (YAML frontmatter, naming conventions) — Anthropic-maintained, tracks spec changes
- `skills create` produces scaffolds matching current spec
- `/skill-creator` skill handles interactive design + eval

Our `skill-create` and `skill-audit` layer AGENCY-SPECIFIC concerns (registry drift, agency-v2 compliance, required_reading path validity) on top. Don't re-implement Anthropic's checks.

## Tools (available in the-agency framework)

| Tool | Role | Source |
|---|---|---|
| `skills validate <dir>` | Structural validation (YAML frontmatter, naming) | Anthropic `skills-cli` |
| `skills create <name>` | Scaffold skill bundle per current spec | Anthropic `skills-cli` |
| `/skill-creator` | Interactive 4-mode design: Create / Eval / Improve / Benchmark | Anthropic skill |
| `skill-create` (ours) | Wraps `skills create` + adds agency-v2 post-processing (registry row, agency-skill-version field, required_reading template) | the-agency |
| `skill-audit` (ours) | Agency-layer checks: registry drift, agency-v2 compliance, required_reading path validity, naming conformance | the-agency |

## Workflow — creating a new v2 skill

1. **Design phase** — clarify what the skill does, when it fires, who invokes it, what tools it needs. Optionally run `/skill-creator` for interactive design.
2. **Scaffold** — run `skill-create <name> --description "..." [--actor captain|agent]`. Creates `.claude/skills/<name>/` with full bundle structure and v2 frontmatter template.
3. **Author `SKILL.md`** — fill frontmatter fully; write body with all 9 sections.
4. **Author `reference.md`** — skill-unique protocol or stub if none.
5. **Author `examples.md`** — three example categories.
6. **Author scripts** (if any) — in `scripts/`.
7. **Register** — add row to `claude/REFERENCE-SKILLS-INDEX.md`.
8. **Verify** — run `skill-audit <name>`. Must pass before commit.
9. **Dogfood** — invoke the skill for the case it's designed for; iterate.
10. **Commit + PR** — via `/git-safe-commit` + `/pr-submit` (if using new PR lifecycle) or `/pr-prep` + `/pr-create`.
11. **Upstream** — after merge, run `/upstream-port` to port to the-agency if framework-level.

## Workflow — upgrading a v1 skill to v2

1. **Identify the skill** — v1 skills have minimal frontmatter, often just `description`.
2. **Audit current state** — read SKILL.md. Note current arguments pattern (`$ARGUMENTS` is v1; `argument-hint:` is v2).
3. **Add the 4 missing frontmatter fields** — `name`, `agency-skill-version: 2`, `when_to_use`, `argument-hint`, `paths`, `required_reading`, `allowed-tools` (with discipline per §3).
4. **Create the missing bundle files** — `reference.md`, `examples.md`, `scripts/` (may be empty with note).
5. **Restructure body into 9 sections** — add any missing sections with explicit "N/A because …" content.
6. **Register** — add row to `REFERENCE-SKILLS-INDEX.md` with version `2`.
7. **Verify** — run `skill-audit`. Must pass.
8. **Commit** — single commit per skill refactor, clear message referencing the v2 upgrade.
9. **Upstream** — port via `/upstream-port`.

## Case studies

### Case study #1 — new skills (clean build under v2)

**`pr-submit` + `pr-captain-land`** — Phase 1 pilot for the-agency#296 (captain-owned PR lifecycle).

- Built clean under the v2 spec
- Full bundle structure
- Showcases `paths:` scoping (agent worktree-only vs captain main-checkout-only)
- Showcases `disable-model-invocation: true` on the destructive captain-only skill
- Showcases noun-actor-verb naming (`pr-captain-land`)
- Committed via `030123b3` → `86c34e2e` → `df222b29`

### Case study #2 — retrofit on protocol-heavy production skills

**`iteration-complete` + `phase-complete`** — retrofit from v1.

- Existing production skills upgraded without behavior change
- Frontmatter expanded to meet v2
- Body retained (protocol IS the skill for these)
- Allowed-tools deliberately inherited `Bash(*)` with inline rationale comment (flag #62/#63)
- Committed via `e14961c4`
- Surfaced the `allowed-tools` caveat that refined the methodology

### Case study #3 — Tier 1 destructive retrofit (in progress)

**`pr-merge` → `pr-captain-merge`** — first Tier 1 destructive skill retrofit using v2.

- Expected to validate: naming pattern, full bundle on destructive skill, `disable-model-invocation: true`, narrow tool-level `allowed-tools`
- Will drive final refinements to `skill-create` and `skill-audit` design

## Required reading for skill authors

Every skill author, before writing their first v2 skill:

- This document (`REFERENCE-SKILL-AUTHORING.md`)
- `claude/REFERENCE-WHAT-IS-CLAUDE-CODE.md`
- Anthropic's [skill-building guide PDF](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
- Claude Code's [skills docs](https://code.claude.com/docs/en/skills)

Every skill author should Read the `required_reading:` frontmatter files of any skill they're refactoring — those are the skill's declared dependencies.

## Upstream relationships

- **the-agency#298** — Skills review + refactor recommendation. This methodology is the answer to the recommendation.
- **the-agency#296** — PR lifecycle ownership (Phase 1 pilot, drove pr-submit + pr-captain-land)
- **the-agency#306** — Claude Code `@path` imports in SKILL.md (feature request for the future replacement of `required_reading:`)
- **the-agency#307** — SessionStart dependency-install mechanism (required for `uv` + `skills-cli` bootstrap)
- **the-agency#308** — REFERENCE-WHAT-IS-CLAUDE-CODE.md ported

## Adoption

- **Framework (the-agency):** adopts this spec. All new skills v2. Retrofit plan for v1 skills tracked in `REFERENCE-SKILLS-INDEX.md`.
- **Adopters (monofolk et al.):** pull framework updates; refactor their own skills to v2 opportunistically. `skill-audit` catches drift.

## Out of scope (for v2)

- Skills that span multiple agencies (cross-repo) — handled by `collaborate` skill family, not by v2 spec directly.
- Skills that require runtime evaluation harnesses (integration tests, eval suites) — use `/skill-creator`'s Eval mode; agency-specific eval layering is v3 work.
- Automated registry backfill for v1 skills — manual or batch-scripted for the initial bulk import.

---

*Living document. Amend via PR against this file with a commit message referencing what changed and why.*
*Last updated: 2026-04-19 (monofolk initial; ported upstream same day).*
