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
| `commit` | Automated (git-commit tool) | Iteration commit notification to captain |
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

When an agent commits via `/iteration-complete`, the `git-commit` tool auto-creates a commit dispatch to captain with structured YAML: `commit_hash`, `stage_hash`, `branch`, `phase`, `iteration`, `files_changed`. Captain verifies QGR receipt via stage-hash match, merges, and syncs worktrees.

Dispatch-on-commit is fire-and-forget from the committing agent's perspective — if captain is not running, dispatches queue in the DB. No blocking.
