---
type: proposal
date: 2026-04-02
subject: Agent Addressing Standard
status: revision 3 — MAR round 2 findings addressed (12 more)
mar_findings: 52 total (40 round 1 + 12 round 2)
---

# Agent Addressing Standard — Proposal (Rev 3)

## 1. Proposed CLAUDE-THEAGENCY.md Section

Insert after "TheAgency Repo Structure" section, before "Quality Gate (QG) Protocol":

---

## Agent & Principal Addressing

### Principals and Agents

A **principal** is a human who directs agent work. An **agent** is an AI instance running under a principal's direction. Every agent belongs to exactly one principal.

Identify principals and agents by **name** — a lowercase ASCII slug (`[a-z0-9][a-z0-9_-]*`, max 32 characters). Names are machine identifiers for paths, addresses, and code. They are NOT human names.

For human-readable display, set `display_name` in `agency.yaml` — a single freeform Unicode string. Do not parse it, split it into fields, or restrict its characters. People's names contain apostrophes (O'Brien), hyphens (Dea-Mattson), diacritics (José), CJK characters (田中太郎), spaces, and more. The display name accepts whatever the human says their name is. (See: [Falsehoods Programmers Believe About Names](https://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/).)

```yaml
principals:
  tanaka:                       # system username on this machine
    name: tanaka                # principal slug (machine identifier)
    display_name: "田中太郎"       # human display (freeform Unicode)
    address:
      informal: "太郎"           # how to address in conversation (default: display_name)
      formal: "田中さん"          # formal address (default: display_name)
    platforms:
      github:
        - username: tanaka-taro
          repos:
            - org: the-agency-ai
              repo: the-agency
```

Defaults: if `address.informal` is omitted, use `display_name`. If `address.formal` is omitted, use `display_name`. Most principals only need `display_name` — the address fields are for when the principal has a preference:

```yaml
  jdm:
    name: jordan
    display_name: "Jordan Dea-Mattson"
    address:
      informal: "Jordan"        # "Hey Jordan" not "Hey Jordan Dea-Mattson"
    platforms:
      github:
        - username: jordandm
          repos:
            - org: the-agency-ai
              repo: the-agency
        - username: jordan-of
          repos:
            - org: OrdinaryFolk
              repo: monofolk
            - org: the-agency-ai
              repo: the-agency
```

**Reserved names** (cannot be used as principal names): `_` (shared agents), `system`, `shared`, `all` (broadcast addressing), `default` (fallback principal in `_path-resolve`). These are reserved for future use.

**Display name safety:** `display_name` and `address.*` fields are freeform Unicode but must be double-quoted when written to YAML output. They are NEVER used in filesystem paths, address strings, or machine-parseable identifiers. Tools that emit them into markdown must ensure they cannot produce a bare `---` line (which breaks frontmatter boundaries).

**Agents use `address.informal`** when addressing the principal in conversation. Use `address.formal` in dispatch headers and formal communications. These are the consumers — they guide how the AI talks to the human.

### Address Hierarchy

Four levels, broadest to narrowest:

```
{org}/{repo}/{principal}/{agent}
```

| Level | What | Constraint | Example |
|-------|------|-----------|---------|
| Org | Hosting namespace (GitHub org, GitLab group) | Case-preserved, `[A-Za-z0-9-]+` | `the-agency-ai`, `OrdinaryFolk` |
| Repo | Repository short name | `[a-z0-9][a-z0-9_-]*`, no slashes | `the-agency`, `monofolk` |
| Principal | Human directing the agent | `[a-z0-9][a-z0-9_-]*` | `jordan`, `peter`, `tanaka` |
| Agent | Agent instance name | `[a-z0-9][a-z0-9_-]*` | `captain`, `devex` |

Repo short names are the leaf name only — no org prefix, no nested group paths. For GitLab nested groups (`org/subgroup/repo`), the short name is `repo`. The `remotes` registry handles full path resolution.

### What Tools Write vs. What Tools Accept

**Always write fully qualified** — `{repo}/{principal}/{agent}`. Every tool, every dispatch, every handoff, every written record. No exceptions. The written record must be unambiguous regardless of future context changes.

**Accept short forms as input** and resolve them using local context:

| Input form | Pattern | Resolution |
|------------|---------|------------|
| Bare | `captain` | Resolve repo from git, principal from agency.yaml |
| Principal-scoped | `jordan/captain` | Resolve repo from git |
| Fully qualified | `monofolk/jordan/captain` | No resolution needed |
| Org-qualified | `OrdinaryFolk/monofolk/jordan/captain` | No resolution needed (rare — repo name collision across orgs) |

Tools parse input by segment count: 1 = bare, 2 = principal/agent, 3 = repo/principal/agent, 4 = org/repo/principal/agent. Three segments is ALWAYS `repo/principal/agent` — never `org/repo/principal`. If you need org qualification, use all 4 segments. If the first segment of a 3-segment address matches a known org name, tools should warn that the user may have intended 4 segments.

**Principal resolution:** To resolve the current principal, find the `principals` entry in `agency.yaml` whose key matches `$USER`, then use its `name` field as the principal slug. Example: `$USER=jdm` → key `jdm` → `name: jordan` → principal is `jordan`.

### Principal Identity Across Repos

A principal may have different platform identities in different orgs:

| Repo | Local name | GitHub identity | Org |
|------|-----------|----------------|-----|
| the-agency | `jordan` | `jordandm` | `the-agency-ai` |
| monofolk | `jordan` | `jordan-of` | `OrdinaryFolk` |

The framework treats each `{repo}/{principal}` as a distinct context — different role, different permissions, different sandbox. The physical person may be the same, but the addressing system does not assume this.

### Address Resolution

Addresses resolve via local context, not global lookup.

**Local repo identity:** Auto-detected from `git remote -v` (parse origin URL for org and repo name). Override in `agency.yaml` only when auto-detection fails:

```yaml
repo:
  name: monofolk          # override auto-detected name
  org: OrdinaryFolk       # override auto-detected org
```

**Cross-repo resolution:** The `remotes` section maps repo short names to hosting locations for repos that are NOT the current repo's git remotes:

```yaml
remotes:
  monofolk:
    url: https://github.com/OrdinaryFolk/monofolk
```

The transport layer (git push/pull, future IACP) is separate from addressing. Addresses identify; transport delivers.

**Resolution errors:** Unknown repo = hard fail with actionable message. Unknown principal = hard fail. Unknown agent = warn (agent may not be registered yet in a fresh worktree).

### Commit Messages

Commit message agent prefixes (`housekeeping/captain: ...`) stay bare-form. They are repo-local context and do not need qualification.

### Future: Shared Agents

A shared agent serves a repo or value stream rather than a specific principal — e.g., a captain that coordinates across all principals. Addressed as `{repo}/_/{agent}` using the reserved `_` principal name. Not implemented yet.

### Future: Groups and Broadcast

Role-based addressing (`*/jordan/*`, `monofolk/*/captain`) and broadcast targeting are anticipated but out of scope. The current address format does not preclude them — the wildcard `*` is not a valid name character, so it can be introduced later without collision.

### Future: Delegation and Ephemeral Agents

When a captain delegates to a worktree agent, the worktree agent is ephemeral — it has no stable address. For dispatch purposes, ephemeral agents reply through their captain's address. A derived address form (e.g., `the-agency/jordan/captain:wt-devex`) is anticipated but not implemented.

---

## 2. Tooling Impact

### New: `agency/tools/lib/_address-parse`

**Create a canonical address parsing library.** All tools source this instead of reimplementing parsing.

Functions:
- `address_parse <addr>` — split into components, return `ADDR_ORG`, `ADDR_REPO`, `ADDR_PRINCIPAL`, `ADDR_AGENT`
- `address_resolve <addr>` — resolve short forms using local context (git remote, agency.yaml)
- `address_format <repo> <principal> <agent>` — produce fully qualified form
- `address_validate_component <name> [--level org|repo|principal|agent]` — reject path traversal (`..`, `/`, null bytes). For org level: `[A-Za-z0-9-]+` (case-preserved). For all other levels: `[a-z0-9][a-z0-9_-]*` (lowercase only). Reject reserved names (`_`, `system`, `shared`, `all`, `default`). Max 32 chars per component.

### Update: `agency/tools/lib/_path-resolve`

**Add `_validate_name()`.** Reject any name component containing `/`, `..`, null bytes, or characters outside `[a-z0-9_-]`. Apply in every function that constructs filesystem paths from names. This fixes the existing path traversal vulnerability.

**Add precondition to `_pr_yaml_get`:** Assert that the `key` parameter matches `^[a-z0-9][a-z0-9_-]*$` before using it in a regex. Defense in depth — do not rely on callers to pre-validate.

**Rewrite `_pr_yaml_get` for nested YAML.** The current parser only handles flat `key: value` pairs under a section. The new `principals` structure is nested (key → object with `name`, `display_name`, `platforms`). Either rewrite `_pr_yaml_get` to handle nested structures, or have `_address-parse` handle all principal resolution and deprecate direct `_pr_yaml_get` calls for principal lookups.

### Update: `agency/tools/dispatch-create`

**Current:** `From: ${PRINCIPAL}/captain` — missing repo, bare form, hardcodes `captain`.
**Change:** Compute `from:` automatically — repo from git, principal from agency.yaml, agent from context (default: `captain`, detect from session if possible).

No `--from` flag. The sender's identity is computed from trusted sources, not self-asserted. Accept `--to` for the recipient address.

**New frontmatter format:**
```yaml
---
status: created
created: 2026-04-02T10:10
from: the-agency/jordan/captain
to: monofolk/jordan/captain
priority: normal
subject: "..."
in_reply_to: "dispatch-code-review-findings-20260401-1430.md"
---
```

The `in_reply_to` field is the originating dispatch filename (without path).

### Update: `agency/tools/handoff`

**Add `agent` field** to frontmatter. Computed from local context (not self-asserted).

```yaml
---
type: session
date: 2026-04-02 09:05
agent: the-agency/jordan/captain
branch: main
trigger: monofolk-plan-complete
---
```

Existing handoffs without the `agent` field remain valid — backward compatible.

### Update: `agency/config/agency.yaml`

**Restructure `principals` section** to include platform identity (merge `identity` into `principals` — one place for all principal metadata):

```yaml
principals:
  jdm:                          # system username on THIS machine
    name: jordan                # principal name (the stable slug)
    display_name: "Jordan Dea-Mattson"
    platforms:
      github:
        - username: jordandm
          repos:
            - org: the-agency-ai
              repo: the-agency
        - username: jordan-of
          repos:
            - org: OrdinaryFolk
              repo: monofolk
            - org: the-agency-ai
              repo: the-agency
```

The principal name (`jordan`) is the stable identity across machines and repos. System usernames and platform handles are per-machine, per-org plumbing. A different machine with a different system user maps to the same principal:

```yaml
# On a different machine (e.g., monofolk laptop)
principals:
  jdm-of:
    name: jordan
    display_name: "Jordan Dea-Mattson"
    address:
      informal: "Jordan"
    platforms:
      github:
        - username: jordan-of
          repos:
            - org: OrdinaryFolk
              repo: monofolk
            - org: the-agency-ai
              repo: the-agency
```

**Add `remotes` section** for cross-repo address resolution (only for repos not in git remotes):

```yaml
remotes:
  monofolk:
    url: https://github.com/OrdinaryFolk/monofolk
```

**Add optional `repo` section** for overriding auto-detected repo identity:

```yaml
repo:
  name: the-agency
  org: the-agency-ai
```

### Agent registration (`.claude/agents/{name}.md`)

**No `address` field.** The fully qualified address is always computable at runtime from repo + principal + agent name. Storing it creates stale-data risk.

### Commit messages

**No change.** Bare-form agent prefixes (`housekeeping/captain: ...`) are correct for repo-local context.

## 3. Tests Required

### New: `tests/tools/dispatch-create.bats`

Baseline tests BEFORE making changes:
- Creates file at correct path
- Correct filename format (slug + timestamp)
- Frontmatter fields present

Then add:
- `from:` field is fully qualified (`{repo}/{principal}/{agent}`)
- `from:` is auto-computed, not user-supplied
- `to:` field is validated
- `in_reply_to` field format is filename-only

### New: `tests/tools/address-parse.bats`

- Parse all 4 input forms (1, 2, 3, 4 segments)
- Resolve bare → fully qualified
- Resolve principal-scoped → fully qualified
- Reject: empty, slashes in components, `..`, reserved names (`_`, `system`, `shared`, `all`)
- Reject: non-ASCII, too-long names (>32 chars), uppercase in non-org position
- Org names preserve case

### Update: `tests/tools/handoff-types.bats`

- `agent` field present in new handoffs
- `agent` field is fully qualified
- Missing `agent` field still parses (backward compat)

### Update: `tests/tools/principal.bats`

- Reject `_`, `system`, `shared`, `all` as principal names
- Reject path traversal in principal names

### Update: `tests/skills/skill-validation.bats`

- Monofolk references in example text within `.claude/skills/` are OK if in comments/examples — update grep to exclude example blocks, OR keep example repo names out of skills entirely

## 4. Migration

1. Create `agency/tools/lib/_address-parse` with validation, parsing, resolution
2. Add `_validate_name()` to `agency/tools/lib/_path-resolve`
3. Update `dispatch-create` — computed `from:`, YAML frontmatter, `--to` flag
4. Update `handoff` tool — add `agent` field
5. Restructure `principals` in agency.yaml template (merge identity)
6. Add `remotes` section to agency.yaml template
7. Update `agency-init` to scaffold new agency.yaml structure and prompt for org/repo (or auto-detect from `git remote -v`)
8. Create all test files listed in section 3
9. Update prior dispatch resolution to note that addressing standard evolved past `{repo}/{agent}` form
10. Existing dispatches and handoffs are NOT retroactively updated — historical records

## 5. Relationship to ISCP / IACP

This addressing standard is a prerequisite for both protocols:

- **ISCP (Inter-Session Communication Protocol):** Same agent, across sessions. Handoffs now carry the agent's fully qualified address for auditability. Local delivery — transport is the filesystem.
- **IACP (Inter-Agency Communication Protocol):** Different agents, potentially cross-repo. Fully qualified addresses are the envelope. Resolution via `remotes` + git remotes. Transport is git push/pull today, pluggable later.

Addressing defines identity. ISCP defines local delivery. IACP defines cross-repo delivery. Transport is pluggable — separate from all three.

## 6. Trust Model

**Current trust boundary:** Anyone who can commit to the repo can create dispatches. The `from:` field is computed by tooling but not cryptographically verified. This is acceptable for single-principal and trusted-team repos.

**For multi-principal and cross-repo:** Before implementing IACP, define:
- Dispatch signing via commit signatures (`git verify-commit`)
- Receiving repo validates `from:` against configured `remotes`
- Transport mechanism documented as part of IACP, not deferred

**Modifying `remotes` in agency.yaml is a privilege-sensitive operation** — changes should be reviewed in PRs, not auto-merged.

**Platform identity is intentionally public** for open-source repos. For private repos, platform identity can be split into a local override file at `agency/config/agency.local.yaml` (gitignored). Merge precedence: local overrides committed. Tools check local first, fall back to committed. Implementation deferred — define the file path and merge rule now so the schema supports it.

### Future: Enforcement Triangle

The addressing standard does not yet have a hookify rule to enforce address construction via `_address-parse`. When tools stabilize, consider adding `hookify.block-raw-address-construction` to prevent agents from hardcoding addresses instead of using the library. Noted as a future enforcement item.
