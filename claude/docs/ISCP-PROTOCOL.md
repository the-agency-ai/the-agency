## ISCP Protocol — Dispatch, Flag, and Notification

ISCP (Inter-Session Communication Protocol) is the notification and messaging backbone. Every agent has automatic mail. Full reference: `claude/workstreams/iscp/iscp-reference-20260405.md`.

### Architecture

Shared SQLite database at `~/.agency/{repo-name}/iscp.db` — outside git, WAL mode, all worktrees share it. Two primitives:

| Primitive | Storage | What |
|-----------|---------|------|
| **Flag** | DB only | Quick-capture observations, agent-addressable |
| **Dispatch** | DB notification + git payload | Structured messages with immutable payload files |

### Tools

```bash
# Flags — instant capture, no git
flag <message>                   # flag to self
flag --to <agent> <message>      # flag to specific agent
flag list                        # show flags, mark as read
flag discuss                     # output as /discuss agenda, mark processed
flag clear                       # mark all as processed

# Dispatches — structured messages with git payloads
dispatch create --to <addr> --subject <text> --body <content> [--type <type>]
dispatch list                    # list dispatches for current agent
dispatch read <id>               # read payload, mark as read
dispatch check                   # silent when empty, JSON when items waiting
dispatch resolve <id>            # mark resolved
dispatch status                  # summary statistics
```

### Dispatch Types

| Type | Who can create | Purpose |
|------|---------------|---------|
| `directive` | Captain only | "Do this" |
| `review` | Captain only | "Review and fix these findings" |
| `seed` | Any agent | Input material for a workstream |
| `review-response` | Reviewer (in reply to review) | "Here's what I found" |
| `commit` | Automated (git-safe-commit tool) | Iteration commit notification to captain |
| `master-updated` | Captain only | Master was updated, sync your worktree |
| `escalation` | Any agent | Urgent — captain triages before all other work |
| `dispatch` | Any agent | General communication |

### Addressing

Fully qualified: `{repo}/{principal}/{agent}`. Tools write fully qualified, accept short forms as input.

| Input | Resolution |
|-------|-----------|
| `captain` | Resolve repo + principal from local context |
| `jordan/captain` | Resolve repo from git |
| `the-agency/jordan/captain` | No resolution needed |

### Dispatch Payloads

Payloads are immutable markdown files in git at `usr/{principal}/{project}/dispatches/`. Named `{type}-{slug}-{YYYYMMDD-HHMM}.md`. The DB stores the notification (status, timestamps); git stores the content.

### Notification Hook

`iscp-check` fires on SessionStart, UserPromptSubmit, and Stop. Queries the DB for unread items. Silent when empty (zero tokens). One-line JSON summary when items are waiting.

### When You Have Mail

- **SessionStart:** Process unread items FIRST before other work
- **Mid-session:** Act on mail at a natural break, not immediately
- **Escalations:** Captain triages before all other work

### Flag Lifecycle

Three states: **unread** → **read** (on `flag list`, Slack-style seen) → **processed** (on `flag discuss` or `flag clear`).

### Dispatch Lifecycle

Four states: **unread** → **read** (on `dispatch read`) → **resolved** (on `dispatch resolve`). Also: **undeliverable** (agent not found).

### Dispatch-on-Commit (V2)

When an agent commits via `/iteration-complete`, the `git-safe-commit` tool auto-creates a commit dispatch to captain with structured YAML: `commit_hash`, `stage_hash`, `branch`, `phase`, `iteration`, `files_changed`. Captain verifies QGR receipt via stage-hash match, merges, and syncs worktrees.

Dispatch-on-commit is fire-and-forget from the committing agent's perspective — if captain is not running, dispatches queue in the DB. No blocking.

### Dispatch Monitoring

**Preferred: Monitor tool (96% token savings, 10-second latency):**

Use the `/monitor-dispatches` skill at session start. It runs `./claude/tools/dispatch-monitor --include-collab` in the background persistently via the Monitor tool. Completely silent when no dispatches; outputs when items arrive. The `--include-collab` flag also checks cross-repo collaboration dispatches.

**Fallback: `/loop` polling (if Monitor is unavailable, Claude Code < v2.1.98):**

```
/loop 5m Run: ./claude/tools/dispatch list --status unread
(silent when clean, act on unread)
```

```
/loop 30m NAG CHECK: Run ./claude/tools/dispatch list --status unread
(visible alert if items sitting 30+ minutes)
```

### Cross-Repo Communication

ISCP is local to each repo (the SQLite DB lives at `~/.agency/{repo-name}/iscp.db`). Cross-repo dispatches use **collaboration repos** — git-file-based messaging since the two repos don't share a DB.

**The collaboration tool** (`claude/tools/collaboration`) is captain-only. It manages cross-repo dispatch lifecycle:

```bash
collaboration check                    # Pull all repos, scan for unread
collaboration list                     # List configured repos
collaboration read <repo> <file>       # Read and mark as read
collaboration reply <repo> --to <file> --subject <text> --body <text>
collaboration resolve <repo> <file>    # Mark resolved
collaboration push <repo>             # Commit and push status updates + replies
```

**Configuration** in `claude/config/agency.yaml`:
```yaml
collaboration:
  repos:
    monofolk:
      path: "~/code/collaboration-monofolk"
      inbound: "dispatches/monofolk-to-the-agency"
      outbound: "dispatches/the-agency-to-monofolk"
```

Use the `/collaborate` skill — never invoke the raw tool directly.

### Schema Versioning (V2 Phase 2.0)

The ISCP DB uses SQLite's `PRAGMA user_version` for schema versioning. The framework ships migration code via `_iscp_run_migrations` and per-version functions named `_iscp_migration_v<N>`. The runner walks from `current_version+1` to `ISCP_SCHEMA_VERSION`, wrapping each migration in `BEGIN EXCLUSIVE`/`COMMIT` for concurrency safety (multiple agents share one DB).

**How to add a new migration:**

1. Bump `ISCP_SCHEMA_VERSION` constant in `claude/tools/lib/_iscp-db`
2. Define `_iscp_migration_v<N>()` returning the SQL (heredoc)
3. The runner picks it up automatically on next `iscp_db_init` call

**Coordination requirement:** Schema bumps are multi-worktree events. All worktrees on the machine share the DB. If one worktree bumps to v2 but another worktree's tools still expect v1, the v1 tools will refuse to run (`FATAL: DB schema version 2 is newer than expected 1`). Schema changes must be planned as coordinated deploys: all worktrees pull the new tools first, THEN the version bump lands. Tools support runtime column detection (`PRAGMA table_info`) where possible, allowing the schema to be ahead of any individual worktree's expected version without breaking.

**Currently shipped:** v1 schema (initial). Migration framework lands in R3. The first column-add migration (flag categories) is queued for a future release once the multi-worktree coordination is in place.
