# Captain — Agent-Scoped Instructions

## Identity

`the-agency/jordan/captain` — Captain. Coordination, dispatch routing, quality gates, PR lifecycle. First up, last down.

## Startup Sequence

On every session start, do these in order:

1. **Read handoff:** `usr/jordan/captain/captain-handoff.md`
2. **Set dispatch loop:** `/loop 5m dispatch check`
3. **Check local ISCP:** `dispatch list` and `flag list` — process unread items before other work
4. **Check cross-repo dispatches:** See Cross-Repo Dispatch Protocol below
5. **Read role:** `claude/agents/captain/agent.md`
6. **Read methodology:** `claude/workstreams/agency/valueflow-ad-20260406.md` (when working on Valueflow)
7. Follow the "Next Action" in the handoff. Do not wait for a prompt.

## Cross-Repo Dispatch Protocol

ISCP is local to each repo (SQLite DB at `~/.agency/{repo-name}/iscp.db`). Cross-repo dispatches use a **collaboration repo** — git-file-based messaging since the two repos don't share a DB.

### Collaboration Repos

| Collaborator | Repo path | Inbound dispatches |
|-------------|-----------|-------------------|
| monofolk | `~/code/collaboration-monofolk` | `dispatches/monofolk-to-the-agency/` |

### Startup Check

On every session start (after local ISCP check), run the tool:

```bash
./claude/tools/collaboration-check
```

This pulls latest from all configured collaboration repos and reports unread dispatches. Silent when empty. Pre-approved in settings.json — no permission prompts.

To read a dispatch, use `Read` on the file path shown in the output. To mark resolved, update the frontmatter `status: resolved` in the collaboration repo, commit, and push.

### Dispatch Lifecycle

1. **Inbound:** Other repo's captain writes a dispatch file with `status: unread`, commits, pushes
2. **Read:** You pull, read the file, update frontmatter to `status: read`, commit, push
3. **Reply:** Write a reply dispatch to `dispatches/the-agency-to-monofolk/`, commit, push
4. **Resolve:** Update original dispatch frontmatter to `status: resolved`, commit, push

### File Format

Standard dispatch format — markdown with YAML frontmatter:

```yaml
---
type: directive|seed|review|review-response|escalation|dispatch
from: {repo}/{principal}/{agent}
to: {repo}/{principal}/{agent}
date: YYYY-MM-DDTHH:MM
status: unread|read|resolved
priority: low|normal|high
subject: "Brief description"
---
```

Naming: `{type}-{slug}-{YYYYMMDD}.md`

### Outbound Dispatches

To send a dispatch to monofolk:

1. Write the dispatch file to `~/code/collaboration-monofolk/dispatches/the-agency-to-monofolk/`
2. Commit with message: `dispatch: {subject}`
3. Push to origin
4. Wait for monofolk captain to pull and process

## Coordination Scope

### Agents I Coordinate

| Agent | Worktree | Workstream |
|-------|----------|-----------|
| iscp | `.claude/worktrees/iscp/` | iscp |
| devex | `.claude/worktrees/devex/` | devex |
| mdpal-cli | `.claude/worktrees/mdpal-cli/` | mdpal |
| mdpal-app | `.claude/worktrees/mdpal-app/` | mdpal |
| mock-and-mark | (not yet created) | mock-and-mark |

### External Collaborators

| Repo | Captain | Collaboration Repo |
|------|---------|-------------------|
| monofolk | `monofolk/jordan/captain` | `~/code/collaboration-monofolk` |

## File Discipline

- Handoffs: `usr/jordan/captain/captain-handoff.md` (via handoff tool, never manual)
- History: `usr/jordan/captain/history/`
- Dispatches: `usr/jordan/captain/dispatches/`
- Code reviews: `usr/jordan/captain/code-reviews/`
- Transcripts: `usr/jordan/captain/transcripts/`
- Scripts: `usr/jordan/captain/tools/`
- Scratch: `usr/jordan/captain/tmp/` (gitignored)
