# Skill Conventions

Discipline for authoring skills in The Agency framework.

## §1 Frontmatter

Every SKILL.md MUST have YAML frontmatter with at minimum:

```yaml
---
name: <skill-name>                    # kebab-case; matches directory
description: <one-line summary>        # shows in `/` autocomplete
agency-skill-version: 2                # v2 is the current standard
when_to_use: "<when this skill fires>" # helps agents pick the right skill
argument-hint: "<hint>" | "(no args)"  # REQUIRED; use "(no args)" if the skill takes none
paths: []                              # See §5
required_reading: [path, ...]          # REQUIRED; list of REFERENCE-*.md paths, MUST be non-empty
---
```

### Required fields — enforced by `skill-audit`

All seven fields above are **required** and enforced:

- **`argument-hint`** cannot be empty. If the skill takes no arguments, use the literal string `"(no args)"` — this was established as the convention after `sandbox-list`/`sandbox-status` migrations surfaced the audit gap (2026-04-20).
- **`required_reading`** cannot be `[]`. Every skill must declare at least one REFERENCE-*.md dependency so ref-injector has context to load. If truly no REFERENCE doc applies, the closest-fit candidate is `claude/REFERENCE-REPO-STRUCTURE.md` (covers the framework layout).
- **`paths`** MAY be `[]` (the default — unscoped, universally discoverable). Non-empty `paths:` triggers the F12 paths-vs-body consistency check (see §6).

### Optional: `deprecation-alias: true`

Deprecation aliases — skills that exist only to redirect users away from a banned or discouraged operation (e.g., `/rebase`) — carry `deprecation-alias: true` in their frontmatter.

**This flag is metadata, not an exemption.** Deprecation aliases still use the full 9-section body structure (§1 body). The flag signals status to tooling (fleet-wide deprecation dashboards, future `agency-health` integration) and lets readers grep for "what's deprecated in this install."

The body content of a deprecation alias follows the "don't do X, use this instead" pattern — see §1 body structure note below and `.claude/skills/rebase/SKILL.md` as the canonical example.

### Captain-only discoverability rule

Skills whose name starts with `captain-` (or contains `-captain-`) MUST carry:

- `paths: []` — universally discoverable (captain isn't worktree-scoped).

**`disable-model-invocation` is NOT required on captain-* skills** — and was wrong when it was. The captain session IS the principal's session, so flagging captain-* skills as "not invocable by the model" blocks the captain from its own skills. (The original mistake was interpreting "model sub-call" to include the captain's own model turn; the correct reading is "subagent delegation.")

If a specific skill genuinely should never be auto-invocable by ANY model context — e.g., a deprecation signpost like `/rebase` — use `disable-model-invocation: true` on that individual skill. Don't apply it by family.

**History (2026-04-20):** a previous version of this doc required `disable-model-invocation: true` on all captain-* skills; the flag was stripped across **8 skills** when the rule was corrected — **7 captain-family skills** matching the `(^|-)captain(-|$)` rule (captain-log, captain-review, captain-release, captain-sync-all, pr-captain-land, pr-captain-merge, pr-captain-post-merge) plus **sync** (which had inherited the flag by mistake; sync is agent-accessible and is not matched by skill-audit's captain-family regex). Enforcement at `src/tools-developer/skill-audit` §3b was relaxed accordingly.

### `paths:` semantics and the agency#347 trap

`paths:` is a scope filter for `/` autocomplete. A non-empty list like `paths: - .claude/worktrees/**` hides the skill from autocomplete when the current working directory does NOT match.

**The trap (agency#347, monofolk 2026-04-19):** if the skill BODY claims cross-context support (e.g., "works on master", "any branch", "silently skips on X") but `paths:` restricts discoverability, the skill works when invoked but cannot be discovered via autocomplete. Silent discoverability bug. Enforced mechanically — see §6.

**Default:** `paths: []` unless the skill genuinely cannot operate outside a scope. For session-lifecycle skills specifically: `paths: []` — no exceptions.

### `agency-skill-version: 2` body structure (the 9 sections)

v2 skills use a standard body shape:

1. **Why this exists** — motivation
2. **Required reading** — what the agent should read before running (loaded via ref-injector)
3. **Usage** / Arguments
4. **Preconditions**
5. **Flow / Steps**
6. **Failure modes**
7. **What this does NOT do**
8. **Status** (active / deprecated / etc.)
9. **Related**

Sections that don't apply are marked "N/A" with a brief reason, never omitted.

### Deprecation aliases use the same 9 sections

**There is no body-structure exemption** — deprecation aliases (skills carrying `deprecation-alias: true`) also use the full 9-section structure. The **content** inside those sections follows the "don't do X, use this instead" pattern:

- `## Why this exists` — why the deprecated operation is banned, and what this signpost skill does about it.
- `## Flow / Steps` — typically "1. Stop. 2. Pick the right alternative from the table. 3. Invoke that instead." with a table of alternatives.
- `## Failure modes` — cover the "but what if I just…" attempts and point at the mechanical enforcement floor (hookify rule, etc.).
- `## Status` — `deprecated`, and note whether the skill is permanent (signposts usually are).
- `## Related` — the alternatives, plus the mechanical enforcement layer.

Canonical example: `.claude/skills/rebase/SKILL.md`.

Rationale for keeping the 9 sections: readers of ANY v2 skill should know where to find each kind of information. An exemption special-cases the reader's navigation, which is worse than asking deprecation aliases to write a few short sections.

## §2 The underscore-prefix convention (for skills)

**Convention:** skills whose name starts with `_` signal "internal; not intended for direct principal invocation."

**Empirical basis:** principal verified 2026-04-20 that `/` autocomplete does not surface underscore-prefixed skill names (typing `/_` surfaces nothing). Assumed: Claude Code filters `_`-prefix out of the autocomplete list. If this empirical reality changes, the convention MAY need to evolve (rename scheme, move to tools layer).

**Current usage:** no `_`-prefixed skills exist in the fleet as of 2026-04-20. Convention is reserved for future use if skill-to-skill composition becomes a supported framework feature (see §7).

## §3 The tools-layer convention (internal tools)

Bash tools under `agency/tools/` are not `/` autocomplete surface — they don't need an underscore prefix. When a tool is intended for composition use only (not principal-facing), signal via:

- `--help` text starts with "Internal — called from `/skill-foo`" (or similar).
- This REFERENCE doc lists the tool as internal.
- Optionally: a directory grouping (e.g., `agency/tools/internal/`) if the tools layer grows large enough to need taxonomy. Not currently required.

**Current internal tools** (as of 2026-04-20):
- `agency/tools/session-pause` — invoked from `/compact-prepare` and `/session-end` (session-lifecycle-refactor).
- `agency/tools/session-pickup` — invoked from `/compact-resume` and `/session-resume`.
- `agency/tools/monitor-register` — invoked from monitor-spawning skills on startup.

## §4 Composition patterns

### Public skill → framework tool (established)

Skill bodies shell to tools:

```markdown
## Step 2: Run the primitive
`./agency/tools/session-pause --framing continuation --trigger compact-prepare`
```

Precedent: `.claude/skills/pr-captain-land/SKILL.md` shells to `./agency/tools/pr-captain-merge`, `./agency/tools/quality-gate`, and others across its step list. This is THE established composition pattern in the framework.

### Tool → tool (established)

Tools shell to other tools:

```bash
./agency/tools/git-safe-commit "..." --no-work-item
./agency/tools/handoff write --trigger ...
```

## §5 Discoverability

Principals should be able to find every skill they need via `/` autocomplete from any working directory.

**Rules:**
- `paths: []` is the default (unscoped = universally discoverable).
- A skill's body MUST NOT make cross-context claims ("works on master", "any branch") while `paths:` restricts visibility.
- Enforced via `skill-audit` lint (§6).

## §6 Enforcement

### `agency/tools/skill-verify`

- Checks SKILL.md frontmatter against the regex contract (name, description, agency-skill-version, etc.).
- Runs in fleet-gate.
- Unit test: `agency/tools/tests/test-skill-verify.sh`.

### `agency/tools/skill-audit`

- Lint rules:
  - **paths-vs-body-consistency** (F12, session-lifecycle-refactor Iteration 1.3): flags any skill where `paths:` is non-empty AND body contains a cross-context claim from the closed phrase list (see `agency/tools/skill-audit` source for current list).
  - **body-line-limit** (F12): warn at >200 body lines (post-frontmatter), fail at >300.
- Unit test: `agency/tools/tests/test-skill-audit.sh`.
- Runs in fleet-gate.

### File:line citation rule

**Any claim of "precedent," "convention," or "established pattern" in a SKILL.md, reference doc, design doc, or PVR/A&D MUST cite a concrete file + line.**

Three fabricated precedents were caught in a single session (2026-04-19 → 2026-04-20):
1. `_agency-init` as underscore-prefix skill precedent — doesn't exist.
2. "Probably intentional when written" narrative for a self-introduced regression.
3. `/pr-captain-land` as skill-composition precedent — it composes tools, not skills.

All three: confidence-without-verification on "framework precedents" drawn from training data or adjacent patterns. Filed as follow-up in agency#347 (reviewer-design lint for uncited precedent claims). Until that lands, the discipline is self-policing: every precedent claim needs a file+line cite.

## §7 Composition limitations (as of 2026-04-20)

**Skill-to-skill composition via the Skill tool is NOT a supported framework feature.** Shared primitives in a skill family MUST live at the tool layer (`agency/tools/*`) and be invoked by the public skills via bash.

Filed upstream as agency#348 — requesting either (a) first-class skill composition, (b) a documented convention for composable-primitive skills, or (c) explicit documentation that composition is not supported.

When the framework ships skill-composition support, this section is revised and primitives currently at the tool layer MAY be lifted to skills if that pays off (ref-injector scoping, declarative `when_to_use`, anti-triggers).

**Implication for authors:** when you see a skill family with shared behavior (e.g., `/compact-prepare` + `/session-end` both need the same commit+archive sequence), your extraction target is a bash tool, not another skill.

## §8 Ancillary concerns

### N1: Tools lose `required_reading:` / ref-injector

Bash tools don't trigger ref-injector. Public skills that invoke a tool should include the tool's required reference docs in THEIR OWN `required_reading:` frontmatter. E.g., `/compact-prepare` declares `required_reading: [claude/REFERENCE-HANDOFF-SPEC.md]` even though the actual handoff-writing happens in the `session-pause` tool.

### N2: Tool-tier signaling

See §3 — no dedicated convention beyond `--help` text and this REFERENCE doc. Sufficient while the set of internal tools is small.

## §9 Related

- `claude/REFERENCE-HANDOFF-SPEC.md` — handoff frontmatter, including `mode:` enum.
- `claude/REFERENCE-QUALITY-GATE.md` — QG discipline.
- `claude/REFERENCE-AGENT-DISCIPLINE.md` — Two Priorities + Over/Over-and-out.
- agency#347 — paths-vs-body discoverability lint.
- agency#348 — skill composability (open).

— established 2026-04-20, session-lifecycle-refactor Iteration 1.2.
