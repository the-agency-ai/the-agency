<!-- What Problem: The monolithic CLAUDE-THEAGENCY.md bootloader loads ~12K tokens
     on every session start, but agents only need addressing rules when working with
     dispatches, identity resolution, or cross-repo communication. Extracting this
     into a standalone ref doc lets the ref-injector hook inject it on demand.

     How & Why: Verbatim extraction from CLAUDE-THEAGENCY.md "Agent & Principal
     Addressing" section (lines 98-266). Kept as-is because this is reference
     material — accuracy matters more than brevity. The ref-injector hook will
     inject this when dispatch, flag, agent-identity, or collaboration skills run.

     Written: 2026-04-12 during devex session (CLAUDE.md bootloader refactoring) -->

## Agent & Principal Addressing

Every agent and principal has a structured address used in dispatches, handoffs, and tool output. This section defines those addresses and how they resolve.

### Principals and Agents

A **principal** is a human who directs agent work. An **agent** is an AI instance running under a principal's direction. Every agent belongs to exactly one principal.

Identify principals and agents by **name** — a lowercase ASCII slug (`[a-z0-9][a-z0-9_-]*`, max 32 characters). Names are machine identifiers for paths, addresses, and code. They are NOT human names.

For human-readable display, set `display_name` in `agency.yaml` — a single freeform Unicode string. Do not parse it, split it into fields, or restrict its characters. People's names contain apostrophes (O'Brien), hyphens (Dea-Mattson), diacritics (Jose), CJK characters (田中太郎), spaces, and more. The display name accepts whatever the human says their name is. (See: [Falsehoods Programmers Believe About Names](https://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/).)

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

**Reserved names** (cannot be used as principal or agent names): `_` (shared agents), `system`, `shared`, `all` (broadcast addressing), `default` (used by `_path-resolve` when no principal can be resolved from `$USER`).

**Display name safety:** `display_name` and `address.*` fields are freeform Unicode. Double-quote them in YAML output. Never use them in filesystem paths, address strings, or machine-parseable identifiers. Tools that emit them into markdown must ensure they cannot produce a bare `---` line (which breaks frontmatter boundaries).

**Use `address.informal`** when addressing the principal in conversation. Use `address.formal` in dispatch headers and formal communications.

### Address Hierarchy

Two addressing targets: **agents** (principal-scoped) and **workstreams** (repo-scoped).

**Agent addressing** — four levels, broadest to narrowest:

```
{org}/{repo}/{principal}/{agent}
```

| Level | What | Constraint | Example |
|-------|------|-----------|---------|
| Org | Hosting namespace (GitHub org, GitLab group) | Case-preserved, `[A-Za-z0-9-]+` | `the-agency-ai`, `OrdinaryFolk` |
| Repo | Repository short name | `[a-z0-9][a-z0-9_-]*`, no slashes | `the-agency`, `monofolk` |
| Principal | Human directing the agent | `[a-z0-9][a-z0-9_-]*` | `jordan`, `peter`, `tanaka` |
| Agent | Agent instance name | `[a-z0-9][a-z0-9_-]*` | `captain`, `devex` |

**Workstream addressing** — two levels, repo-scoped (no principal):

```
{repo}/{workstream}
```

| Level | What | Constraint | Example |
|-------|------|-----------|---------|
| Repo | Repository short name | Same as agent addressing | `the-agency`, `monofolk` |
| Workstream | Workstream name | `[a-z0-9][a-z0-9_-]*` | `iscp`, `mdpal`, `mock-and-mark` |

Workstreams are repo-level concepts — they match `claude/workstreams/{name}/`. No principal scoping.

**Disambiguation:** A bare name (e.g., `iscp`) could be an agent or a workstream. Resolution order: (1) check `claude/workstreams/{name}/` — if exists, it's a workstream; (2) check agent registrations — if exists, it's an agent; (3) fail with actionable error.

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

Parse input by segment count: 1 = bare, 2 = principal/agent, 3 = repo/principal/agent, 4 = org/repo/principal/agent. Three segments is ALWAYS `repo/principal/agent` — never `org/repo/principal`. Use all 4 segments for org qualification. Warn if the first segment of a 3-segment address matches a known org name.

**Principal resolution:** Find the `principals` entry in `agency.yaml` whose key matches `$USER`, then use its `name` field as the principal slug. Example: `$USER=jdm` → key `jdm` → `name: jordan` → principal is `jordan`.

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

The transport layer (git push/pull, ISCP) is separate from addressing. Addresses identify; transport delivers. ISCP v1 uses the local filesystem (SQLite DB + git payloads) — cross-machine transport is a future extension.

**Resolution errors:** Unknown repo = hard fail with actionable message. Unknown principal = hard fail. Unknown agent = warn (agent may not be registered yet in a fresh worktree).

### Dispatch & Flag Payload Locations

Addresses resolve to physical locations for dispatch payloads:

| Target type | Address pattern | Dispatch payload location |
|-------------|----------------|--------------------------|
| Agent | `{repo}/{principal}/{agent}` | `claude/data/dispatches/` |
| Workstream | `{repo}/{workstream}` | `claude/workstreams/{workstream}/dispatches/` |

A **dispatch** is a structured message between agents or from principal to agent. It consists of a notification pointing to a payload file in git at the resolved location above. Dispatch payloads are immutable once written. Named `{type}-{slug}-{YYYYMMDD-HHMM}.md`.

Dispatches are managed by the `dispatch` tool — never created manually. The tool creates both the DB record and the git payload atomically. Dispatch types are validated against an 8-type enum: `directive`, `seed`, `review`, `review-response`, `commit`, `master-updated`, `escalation`, `dispatch`. Integer IDs (from the DB) are used to reference dispatches, not file paths.

A **flag** is a quick-capture observation for later discussion. Flags are DB-only — no git payload, instant capture from any worktree. Agent-addressable: `flag <message>` (self), `flag --to <agent> <message>` (specific agent). Three-state lifecycle: unread → read (on `flag list`) → processed (on `flag discuss` or `flag clear`).

Both dispatch notifications and flags are persisted in a SQLite database at `~/.agency/{repo-name}/iscp.db` (outside git). The DB stores notification metadata and mutable state (read/unread, timestamps). Dispatch payloads remain as immutable markdown files in git. Flags are DB-only (no git payload). See the ISCP reference: `claude/workstreams/iscp/iscp-reference-20260405.md`.

### Commit Messages

Commit message agent prefixes (`housekeeping/captain: ...`) stay bare-form. They are repo-local context and do not need qualification. See `claude/REFERENCE-GIT-MERGE-NOT-REBASE.md` § "Git & Remote Discipline" for the full commit message format.

### Future Extensions

- **Shared agents:** A shared agent serves a repo or value stream rather than a specific principal. Addressed as `{repo}/_/{agent}` using the reserved `_` principal name. Not implemented yet.
- **Groups and broadcast:** Role-based addressing (`*/jordan/*`, `monofolk/*/captain`) and broadcast targeting are anticipated but out of scope. The wildcard `*` is not a valid name character, so it can be introduced later without collision.
- **Delegation and ephemeral agents:** When a captain delegates to a worktree agent, the worktree agent is ephemeral — no stable address. Ephemeral agents reply through their captain's address. A derived address form (e.g., `the-agency/jordan/captain:wt-devex`) is anticipated but not implemented.
